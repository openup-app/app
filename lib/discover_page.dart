import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:async/async.dart';
import 'package:dartz/dartz.dart' show Either;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide Chip;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as maps;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/chat_api.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/menu_page.dart';
import 'package:openup/util/location_service.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/profile_display.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class DiscoverPage extends ConsumerStatefulWidget {
  final ScrollToDiscoverTopNotifier scrollToTopNotifier;
  final bool showWelcome;

  const DiscoverPage({
    Key? key,
    required this.scrollToTopNotifier,
    required this.showWelcome,
  }) : super(key: key);

  @override
  ConsumerState<DiscoverPage> createState() => DiscoverPageState();
}

class DiscoverPageState extends ConsumerState<DiscoverPage> {
  bool _loading = false;
  bool _hasLocation = false;
  bool _errorLoadingProfiles = false;
  Gender? _genderPreference;
  bool _pageActive = false;

  bool _showingList = true;
  maps.GoogleMapController? _googleMapController;
  final _mapMarkerImages = <String, Uint8List>{};

  CancelableOperation<Either<ApiError, DiscoverResultsPage>>?
      _discoverOperation;
  final _profiles = <DiscoverProfile>[];
  double _nextMinRadius = 0.0;
  int _nextPage = 0;

  int _currentProfileIndex = 0;
  Profile? _currentProfile;
  final _invitedUsers = <String>{};

  final _pageListener = ValueNotifier<double>(0);
  final _pageController = PageController();
  final _profileBuilderKey = GlobalKey<ProfileBuilderState>();

  @override
  void initState() {
    super.initState();
    _fetchPageOfProfiles().then((_) {
      _maybeRequestNotification();
    });

    ref.listenManual<LocationValue?>(
      locationProvider,
      fireImmediately: true,
      (previous, next) {
        if (next != null) {
          recenterMap(LocationStatus.value(next.latLong));
        }
      },
    );

    _pageController.addListener(() {
      final page = _pageController.page ?? 0;
      _pageListener.value = page;
      final oldIndex = _currentProfileIndex;
      final index = _pageController.page?.round() ?? _currentProfileIndex;

      if (oldIndex != index) {
        _profileBuilderKey.currentState?.play();
      }

      // Prefetching profiles
      final scrollingForward = index > oldIndex;
      if (_currentProfileIndex != index) {
        _precacheImageAndDepth(_profiles, from: index + 1, count: 2);
        setState(() {
          _currentProfileIndex = index;
          _currentProfile = _profiles[index].profile;
        });
        if (index > _profiles.length - 4 && !_loading && scrollingForward) {
          _fetchPageOfProfiles();
        }
      }
    });
  }

  void recenterMap(LocationStatus? status) {
    final latLong = status?.map(
      value: (value) => value.latLong,
      denied: (_) => null,
      failure: (_) => null,
    );
    const googleplexLatLong = LatLng(
      37.42796133580664,
      -122.085749655962,
    );
    final CameraPosition pos = CameraPosition(
      target: latLong != null
          ? LatLng(latLong.latitude, latLong.longitude)
          : googleplexLatLong,
      zoom: 14.4746,
    );
    _googleMapController?.animateCamera(CameraUpdate.newCameraPosition(pos));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _precacheImageAndDepth(_profiles, from: 1, count: 2);
  }

  void _precacheImageAndDepth(
    List<DiscoverProfile> profiles, {
    required int from,
    required int count,
  }) {
    profiles.skip(from).take(count).forEach((discoverProfile) {
      discoverProfile.profile.collection.photos.forEach((photo3d) {
        precacheImage(NetworkImage(photo3d.url), context);
        precacheImage(NetworkImage(photo3d.depthUrl), context);
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    _pageController.dispose();
    _googleMapController?.dispose();
  }

  Future<void> _maybeRequestNotification() async {
    final status = await Permission.notification.status;
    if (!(status.isGranted || status.isLimited)) {
      await Permission.notification.request();
    }
  }

  Future<bool> _maybeRequestLocationPermission() async {
    final status = await Permission.location.status;
    if (status.isGranted || status.isLimited) {
      return Future.value(true);
    }

    final result = await Permission.location.request();
    if ((result.isGranted || status.isLimited)) {
      return Future.value(true);
    } else {
      if (!mounted) {
        return false;
      }
      showCupertinoDialog(
        context: context,
        builder: (context) {
          return CupertinoAlertDialog(
            title: const Text(
              'Location Services',
              textAlign: TextAlign.center,
            ),
            content: const Text(
                'Location needs to be on in order to discover people near you.'),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              CupertinoDialogAction(
                onPressed: () {
                  openAppSettings();
                  Navigator.of(context).pop();
                },
                child: const Text('Enable in Settings'),
              ),
            ],
          );
        },
      );
      return Future.value(false);
    }
  }

  Future<LatLong?> _getLocation() async {
    final locationService = LocationService();
    final location = await locationService.getLatLong();
    return location.map(
      value: (value) {
        return Future.value(value.latLong);
      },
      denied: (_) => Future.value(),
      failure: (_) => Future.value(),
    );
  }

  Future<void> _updateLocation() async {
    setState(() => _loading = true);

    final latLong = await _getLocation();
    if (latLong != null && mounted) {
      ref.read(locationProvider.notifier).update(LocationValue(latLong));
      await updateLocation(
        ref: ref,
        latLong: latLong,
      );
    }
  }

  Future<void> _fetchPageOfProfiles() async {
    final granted = await _maybeRequestLocationPermission();
    if (!mounted || !granted) {
      return;
    }

    setState(() => _loading = true);
    final location = await _getLocation();
    if (!mounted) {
      return;
    }

    if (location == null) {
      return;
    }
    setState(() => _hasLocation = true);

    final api = ref.read(apiProvider);
    _discoverOperation?.cancel();
    final discoverFuture = api.getDiscover(
      location.latitude,
      location.longitude,
      seed: Api.seed,
      gender: _genderPreference,
      minRadius: _nextMinRadius,
      page: _nextPage,
    );
    _discoverOperation = CancelableOperation.fromFuture(discoverFuture);
    final profiles = await _discoverOperation?.value;

    if (!mounted || profiles == null) {
      return;
    }
    setState(() => _loading = false);

    profiles.fold(
      (l) {
        if (_profiles.isEmpty) {
          setState(() => _errorLoadingProfiles = true);
        }
        var message = errorToMessage(l);
        message = l.when(
          network: (_) => message,
          client: (client) => client.when(
            badRequest: () => 'Unable to request users',
            unauthorized: () => message,
            notFound: () => 'Unable to find users',
            forbidden: () => message,
            conflict: () => message,
          ),
          server: (_) => message,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
          ),
        );
      },
      (r) async {
        setState(() {
          _profiles.addAll(r.profiles);
          _currentProfile = _profiles[_currentProfileIndex].profile;
          _nextMinRadius = r.nextMinRadius;
          _nextPage = r.nextPage;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ActivePage(
      onActivate: () => setState(() => _pageActive = true),
      onDeactivate: () {
        _profileBuilderKey.currentState?.pause();
        setState(() => _pageActive = false);
      },
      child: Builder(
        builder: (context) {
          if (_loading && _profiles.isEmpty) {
            return const Center(
              child: LoadingIndicator(
                color: Colors.black,
              ),
            );
          }

          if (_profiles.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: !_hasLocation
                        ? Text(
                            'Unable to get location',
                            style: Theme.of(context).textTheme.bodyMedium,
                          )
                        : Text(
                            'Couldn\'t find any profiles',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      // Location needed at least once for nearby users
                      // (may not have granted location during onboarding)
                      setState(() => _loading = true);
                      final locationService = LocationService();
                      if (!await locationService.hasPermission()) {
                        final status =
                            await locationService.requestPermission();
                        if (status) {
                          await _updateLocation();
                        }
                      }

                      if (!mounted) {
                        return;
                      }
                      setState(() {
                        _nextMinRadius = 0;
                        _nextPage = 0;
                      });
                      _fetchPageOfProfiles();
                    },
                    child: const Text('Refresh'),
                  ),
                ],
              ),
            );
          }

          final currentProfile = _currentProfile;
          return ValueListenableBuilder<double>(
            valueListenable: _pageListener,
            builder: (context, page, child) {
              final index = page.round();
              final profile = _profiles[index].profile;
              return Stack(
                fit: StackFit.expand,
                children: [
                  // Must live above PageView.builder (otherwise duplicate global key)
                  ProfileBuilder(
                    key: _profileBuilderKey,
                    profile: profile,
                    play: index == _currentProfileIndex && _pageActive,
                    builder: (context, play, playbackInfoStream) {
                      if (_showingList) {
                        return PageView.builder(
                          controller: _pageController,
                          itemCount: _profiles.length,
                          itemBuilder: (context, index) {
                            final profile = _profiles[index].profile;
                            return ClipRRect(
                              clipBehavior: Clip.hardEdge,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(32),
                                topRight: Radius.circular(32),
                              ),
                              child: Container(
                                margin: EdgeInsets.only(
                                  left: 16,
                                  right: 16,
                                  top: 24 + MediaQuery.of(context).padding.top,
                                  bottom: 16 +
                                      MediaQuery.of(context).padding.bottom,
                                ),
                                clipBehavior: Clip.hardEdge,
                                decoration: const BoxDecoration(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(48)),
                                ),
                                child: ProfileDisplay(
                                  profile: profile,
                                  play: play,
                                  onPlayPause: () {
                                    if (!play) {
                                      _profileBuilderKey.currentState?.play();
                                    } else {
                                      _profileBuilderKey.currentState?.pause();
                                    }
                                  },
                                  onRecord: () {
                                    if (FirebaseAuth.instance.currentUser ==
                                        null) {
                                      _showSignInDialog();
                                    } else {
                                      _showRecordPanel(context, profile.uid);
                                    }
                                  },
                                  onBlock: () => setState(() =>
                                      _profiles.removeWhere(((p) =>
                                          p.profile.uid == profile.uid))),
                                ),
                              ),
                            );
                          },
                        );
                      } else {
                        final locationStatus = ref.read(locationProvider);
                        final latLong = locationStatus?.map(
                          value: (value) => value.latLong,
                          denied: (_) => null,
                          failure: (_) => null,
                        );
                        const googleplexLatLong = LatLng(
                          37.42796133580664,
                          -122.085749655962,
                        );
                        final CameraPosition pos = CameraPosition(
                          target: latLong != null
                              ? LatLng(latLong.latitude, latLong.longitude)
                              : googleplexLatLong,
                          zoom: 14.4746,
                        );
                        return Stack(
                          children: [
                            GoogleMap(
                              mapType: MapType.normal,
                              initialCameraPosition: pos,
                              onMapCreated: (controller) async {
                                controller.setMapStyle(_nightMapStyle());
                                setState(
                                    () => _googleMapController = controller);
                                _updateImages();
                              },
                              myLocationEnabled: true,
                              myLocationButtonEnabled: false,
                              markers: {
                                for (final profile in _profiles)
                                  Marker(
                                    markerId: MarkerId(profile.profile.uid),
                                    position: LatLng(
                                      profile.location.latLong.latitude,
                                      profile.location.latLong.longitude,
                                    ),
                                    onTap: () {
                                      setState(() =>
                                          _currentProfile = profile.profile);
                                    },
                                    icon:
                                        _mapMarkerImages[profile.profile.uid] ==
                                                null
                                            ? BitmapDescriptor.defaultMarker
                                            : BitmapDescriptor.fromBytes(
                                                _mapMarkerImages[
                                                    profile.profile.uid]!),
                                  ),
                              },
                            ),
                            if (currentProfile != null)
                              Align(
                                alignment: Alignment.bottomCenter,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Button(
                                            onPressed: () {
                                              _showRecordPanel(
                                                  context, currentProfile.uid);
                                            },
                                            child: Container(
                                              width: 54,
                                              height: 54,
                                              decoration: const BoxDecoration(
                                                color: Colors.white,
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    offset: Offset(0, 2),
                                                    blurRadius: 10,
                                                    color: Color.fromRGBO(
                                                        0x00, 0x00, 0x00, 0.25),
                                                  )
                                                ],
                                              ),
                                              alignment: Alignment.center,
                                              child: const Icon(
                                                Icons.mic,
                                                size: 26,
                                                color: Color.fromRGBO(
                                                    0xFF, 0x00, 0x00, 1.0),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Button(
                                            onPressed: () => recenterMap(
                                                ref.read(locationProvider)),
                                            child: Container(
                                              width: 54,
                                              height: 54,
                                              decoration: const BoxDecoration(
                                                color: Colors.white,
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    offset: Offset(0, 2),
                                                    blurRadius: 10,
                                                    color: Color.fromRGBO(
                                                        0x00, 0x00, 0x00, 0.25),
                                                  )
                                                ],
                                              ),
                                              alignment: Alignment.center,
                                              child: const Icon(
                                                CupertinoIcons.location_fill,
                                                size: 26,
                                                color: Color.fromRGBO(
                                                    0x22, 0x53, 0xFF, 1.0),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Container(
                                        height: 84,
                                        decoration: const BoxDecoration(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(66)),
                                          color: Colors.white,
                                          boxShadow: [
                                            BoxShadow(
                                              offset: Offset(0, 2),
                                              blurRadius: 10,
                                              color: Color.fromRGBO(
                                                  0x00, 0x00, 0x00, 0.25),
                                            )
                                          ],
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            const SizedBox(width: 12),
                                            Container(
                                              clipBehavior: Clip.hardEdge,
                                              decoration: const BoxDecoration(
                                                shape: BoxShape.circle,
                                              ),
                                              child: Image.network(
                                                currentProfile.photo,
                                                width: 63,
                                                height: 63,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    currentProfile.name,
                                                    style: const TextStyle(
                                                      fontSize: 20,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Row(
                                                    children: const [
                                                      InfoIcon(),
                                                      SizedBox(width: 4),
                                                      Expanded(
                                                        child: Text(
                                                          '1 mutual friends',
                                                          style: TextStyle(
                                                            fontSize: 15,
                                                            fontWeight:
                                                                FontWeight.w400,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              width: 48,
                                              height: 48,
                                              clipBehavior: Clip.hardEdge,
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  width: 2,
                                                  color: const Color.fromRGBO(
                                                      0xFF, 0xA8, 0x00, 1.0),
                                                ),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Text(
                                                '14:39',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w400,
                                                  color: Color.fromRGBO(
                                                      0x43, 0x43, 0x43, 1.0),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Icon(
                                              Icons.pause,
                                              size: 42,
                                              color: Color.fromRGBO(
                                                  0x43, 0x43, 0x43, 1.0),
                                            ),
                                            const SizedBox(width: 24),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Container(
                                        height: 46,
                                        decoration: const BoxDecoration(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(54)),
                                          color: Colors.white,
                                          boxShadow: [
                                            BoxShadow(
                                              offset: Offset(0, 2),
                                              blurRadius: 10,
                                              color: Color.fromRGBO(
                                                  0x00, 0x00, 0x00, 0.25),
                                            )
                                          ],
                                        ),
                                        child: Row(
                                          children: [
                                            const SizedBox(width: 16),
                                            const Icon(
                                              Icons.location_pin,
                                              color: Colors.black,
                                            ),
                                            const SizedBox(width: 8),
                                            const Text(
                                              'Location Services',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w400,
                                                color: Colors.black,
                                              ),
                                            ),
                                            const Spacer(),
                                            CupertinoSwitch(
                                              value: true,
                                              onChanged: (_) {},
                                            ),
                                            const SizedBox(width: 16),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      SizedBox(
                                          height: MediaQuery.of(context)
                                              .padding
                                              .bottom),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        );
                      }
                    },
                  ),
                  Positioned(
                    left: 16 + 20,
                    top: MediaQuery.of(context).padding.top + 24 + 20,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ProfileButton(
                          onPressed: () async {
                            final gender = await _showPreferencesSheet();
                            if (mounted && gender != null) {
                              setState(() {
                                _genderPreference = gender;
                                _nextMinRadius = 0;
                                _nextPage = 0;
                                _pageController.jumpTo(0);
                                _profiles.clear();
                              });
                              _fetchPageOfProfiles();
                            }
                          },
                          icon: Image.asset(
                            'assets/images/preferences_icon.png',
                            color: Colors.black,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.medium,
                          ),
                          label: const Text('Filters'),
                        ),
                        const SizedBox(width: 4),
                        ProfileButton(
                          onPressed: () =>
                              setState(() => _showingList = !_showingList),
                          icon: _showingList
                              ? const Icon(
                                  Icons.map,
                                  color: Colors.black,
                                )
                              : const Icon(
                                  Icons.list,
                                  color: Colors.black,
                                ),
                          label: _showingList
                              ? const Text('Map')
                              : const Text('List'),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _updateImages() async {
    setState(() => _mapMarkerImages.clear());
    final images =
        await _createMapMarkerImages(_profiles.map((p) => p.profile).toList());
    if (mounted) {
      setState(() {
        _mapMarkerImages.clear();
        _mapMarkerImages.addAll(images);
      });
    }
  }

  Future<Map<String, Uint8List>> _createMapMarkerImages(
    List<Profile> profiles,
  ) async {
    final images = <Uint8List>[];
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    for (final profile in profiles) {
      final image = await _createMapMarkerImage(profile, pixelRatio);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      images.add(bytes!.buffer.asUint8List());
      image.dispose();
    }
    final mapping = <String, Uint8List>{};
    for (var i = 0; i < profiles.length; i++) {
      mapping[profiles[i].uid] = images[i];
    }
    return mapping;
  }

  Future<ui.Image> _fetchImage(ImageProvider provider) {
    final completer = Completer<ui.Image>();
    final listener = ImageStreamListener((imageInfo, _) {
      completer.complete(imageInfo.image);
    }, onError: (error, stackTrace) {
      completer.completeError(error, stackTrace);
    });
    provider.resolve(ImageConfiguration.empty).addListener(listener);
    return completer.future;
  }

  Future<ui.Image> _createMapMarkerImage(
      Profile profile, double pixelRatio) async {
    final builder = ui.ParagraphBuilder(ui.ParagraphStyle(maxLines: 1));
    builder.pushStyle(ui.TextStyle(color: Colors.black));
    builder.addText(profile.name);
    final image = await _fetchImage(NetworkImage(profile.photo));

    final textPainter = TextPainter(
      text: TextSpan(
        text: profile.name,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: 200);
    final metrics = textPainter.computeLineMetrics();

    final pictureRecorder = ui.PictureRecorder();
    final canvas = ui.Canvas(pictureRecorder);
    const textLeftPadding = 2.0;
    const textRightPadding = 12.0;
    const textTopPadding = 10.0;
    final metric = metrics[0];

    canvas.scale(pixelRatio);

    final width =
        2 + 34 + 2 + textLeftPadding + metric.width + textRightPadding;
    const height = 36.0;

    canvas.clipRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, width, height),
        const Radius.circular(38),
      ),
    );
    canvas.drawPaint(Paint()..color = Colors.white);

    textPainter.paint(
      canvas,
      const Offset(2 + 34 + 2 + textLeftPadding, textTopPadding),
    );

    canvas.clipPath(Path()..addOval(const Rect.fromLTWH(2, 2, 32, 32)));
    canvas.drawImageRect(
      image,
      Offset.zero & Size(image.width.toDouble(), image.height.toDouble()),
      const Rect.fromLTWH(2, 2, 34, 34),
      Paint()..color = Colors.white,
    );
    final picture = pictureRecorder.endRecording();
    return picture.toImage(
      (pixelRatio * width).toInt(),
      (pixelRatio * height).toInt(),
    );
  }

  void _showRecordPanel(BuildContext context, String uid) async {
    final audio = await showModalBottomSheet<Uint8List>(
      backgroundColor: Colors.transparent,
      context: context,
      builder: (context) {
        return Surface(
          child: RecordPanelContents(
            onSubmit: (audio, duration) => Navigator.of(context).pop(audio),
          ),
        );
      },
    );

    if (audio == null || !mounted) {
      return;
    }

    ref.read(mixpanelProvider).track(
      "send_invite",
      properties: {"type": "discover"},
    );

    final tempDir = await getTemporaryDirectory();
    final file = File(path.join(tempDir.path, 'invite.m4a'));
    await file.writeAsBytes(audio);
    if (!mounted) {
      return;
    }

    final future =
        ref.read(apiProvider).sendMessage(uid, ChatType.audio, file.path);
    await withBlockingModal(
      context: context,
      label: 'Sending invite...',
      future: future,
    );

    if (mounted) {
      setState(() => _invitedUsers.add(uid));
    }
  }

  void _showSignInDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text('Log in to send an invite'),
          actions: [
            CupertinoDialogAction(
              onPressed: Navigator.of(context).pop,
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(context).pop();
                context.pushNamed('signup');
              },
              child: const Text('Log in'),
            ),
          ],
        );
      },
    );
  }

  Future<Gender?> _showPreferencesSheet() async {
    final genderString = await showModalBottomSheet<String>(
      backgroundColor: Colors.transparent,
      context: context,
      builder: (context) {
        return Surface(
          child: Padding(
            padding: const EdgeInsets.only(left: 30.0, right: 45),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    'I\'m interested in seeing...',
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16),
                RadioTile(
                  label: 'Everyone',
                  selected: _genderPreference == null,
                  onTap: () => Navigator.of(context).pop('any'),
                  radioAtEnd: true,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 19,
                      fontWeight: FontWeight.w400,
                      color: Colors.white),
                ),
                RadioTile(
                  label: 'Men',
                  selected: _genderPreference == Gender.male,
                  onTap: () => Navigator.of(context).pop('male'),
                  radioAtEnd: true,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 19,
                      fontWeight: FontWeight.w400,
                      color: Colors.white),
                ),
                RadioTile(
                  label: 'Women',
                  selected: _genderPreference == Gender.female,
                  onTap: () => Navigator.of(context).pop('female'),
                  radioAtEnd: true,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 19,
                      fontWeight: FontWeight.w400,
                      color: Colors.white),
                ),
                RadioTile(
                  label: 'Non-Binary',
                  selected: _genderPreference == Gender.nonBinary,
                  onTap: () => Navigator.of(context).pop('nonBinary'),
                  radioAtEnd: true,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 19,
                      fontWeight: FontWeight.w400,
                      color: Colors.white),
                ),
                SizedBox(
                  height: MediaQuery.of(context).padding.bottom + 24,
                ),
              ],
            ),
          ),
        );
      },
    );

    Gender? gender;
    if (genderString != null) {
      try {
        gender =
            Gender.values.firstWhere((element) => element.name == genderString);
      } on StateError {
        // Ignore
      }
    }
    return gender;
  }
}

class ScrollToDiscoverTopNotifier extends ValueNotifier<void> {
  ScrollToDiscoverTopNotifier() : super(null);

  void scrollToTop() => notifyListeners();
}

class _Welcome extends StatelessWidget {
  const _Welcome({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('welcome_background'),
          fit: BoxFit.fill,
        ),
      ),
      child: Column(
        children: [
          const Spacer(),
          Text('Welcome',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium!
                  .copyWith(fontSize: 40, fontWeight: FontWeight.w400)),
          const SizedBox(height: 8),
          Text('swipe up to begin',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium!
                  .copyWith(fontSize: 16, fontWeight: FontWeight.w300)),
          const SizedBox(height: 97),
          Image.asset(
            'assets/images/app_logo.png',
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

String _nightMapStyle() {
  return jsonEncode(
    [
      {
        'elementType': 'geometry',
        'stylers': [
          {'color': '#242f3e'}
        ]
      },
      {
        'elementType': 'labels.text.stroke',
        'stylers': [
          {'color': '#242f3e'}
        ]
      },
      {
        'elementType': 'labels.text.fill',
        'stylers': [
          {'color': '#746855'}
        ]
      },
      {
        'featureType': 'administrative.locality',
        'elementType': 'labels.text.fill',
        'stylers': [
          {'color': '#d59563'}
        ],
      },
      {
        'featureType': 'poi',
        'elementType': 'labels.text.fill',
        'stylers': [
          {'color': '#d59563'}
        ],
      },
      {
        'featureType': 'poi.park',
        'elementType': 'geometry',
        'stylers': [
          {'color': '#263c3f'}
        ],
      },
      {
        'featureType': 'poi.park',
        'elementType': 'labels.text.fill',
        'stylers': [
          {'color': '#6b9a76'}
        ],
      },
      {
        'featureType': 'road',
        'elementType': 'geometry',
        'stylers': [
          {'color': '#38414e'}
        ],
      },
      {
        'featureType': 'road',
        'elementType': 'geometry.stroke',
        'stylers': [
          {'color': '#212a37'}
        ],
      },
      {
        'featureType': 'road',
        'elementType': 'labels.text.fill',
        'stylers': [
          {'color': '#9ca5b3'}
        ],
      },
      {
        'featureType': 'road.highway',
        'elementType': 'geometry',
        'stylers': [
          {'color': '#746855'}
        ],
      },
      {
        'featureType': 'road.highway',
        'elementType': 'geometry.stroke',
        'stylers': [
          {'color': '#1f2835'}
        ],
      },
      {
        'featureType': 'road.highway',
        'elementType': 'labels.text.fill',
        'stylers': [
          {'color': '#f3d19c'}
        ],
      },
      {
        'featureType': 'transit',
        'elementType': 'geometry',
        'stylers': [
          {'color': '#2f3948'}
        ],
      },
      {
        'featureType': 'transit.station',
        'elementType': 'labels.text.fill',
        'stylers': [
          {'color': '#d59563'}
        ],
      },
      {
        'featureType': 'water',
        'elementType': 'geometry',
        'stylers': [
          {'color': '#17263c'}
        ],
      },
      {
        'featureType': 'water',
        'elementType': 'labels.text.fill',
        'stylers': [
          {'color': '#515c6d'}
        ],
      },
      {
        'featureType': 'water',
        'elementType': 'labels.text.stroke',
        'stylers': [
          {'color': '#17263c'}
        ],
      },
    ],
  );
}
