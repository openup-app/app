import 'dart:io';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:dartz/dartz.dart' show Either;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide Chip;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/chat_api.dart';
import 'package:openup/menu_page.dart';
import 'package:openup/util/location_service.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/icon_with_shadow.dart';
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
  GoogleMapController? _googleMapController;
  _LatLong? _location;

  CancelableOperation<Either<ApiError, DiscoverResultsPage>>?
      _discoverOperation;
  final _profiles = <Profile>[];
  double _nextMinRadius = 0.0;
  int _nextPage = 0;

  int _currentProfileIndex = 0;
  final _invitedUsers = <String>{};

  final _pageListener = ValueNotifier<double>(0);
  final _pageController = PageController();
  final _userProfileInfoDisplayKey = GlobalKey<UserProfileInfoDisplayState>();

  @override
  void initState() {
    super.initState();
    _fetchPageOfProfiles().then((_) {
      _maybeRequestNotification();
    });

    _pageController.addListener(() {
      final page = _pageController.page ?? 0;
      _pageListener.value = page;
      final oldIndex = _currentProfileIndex;
      final index = _pageController.page?.round() ?? _currentProfileIndex;

      if (oldIndex != index) {
        _userProfileInfoDisplayKey.currentState?.play();
      }

      // Prefetching profiles
      final scrollingForward = index > oldIndex;
      if (_currentProfileIndex != index) {
        _precacheImageAndDepth(_profiles, from: index + 1, count: 2);
        setState(() => _currentProfileIndex = index);
        if (index > _profiles.length - 4 && !_loading && scrollingForward) {
          _fetchPageOfProfiles();
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _precacheImageAndDepth(_profiles, from: 1, count: 2);
  }

  void _precacheImageAndDepth(
    List<Profile> profiles, {
    required int from,
    required int count,
  }) {
    profiles.skip(from).take(count).forEach((profile) {
      profile.collection.photos.forEach((photo3d) {
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

  Future<_LatLong?> _getLocation() async {
    final locationService = LocationService();
    final location = await locationService.getLatLong();
    return location.when(
      value: (lat, long) {
        return Future.value(_LatLong(lat, long));
      },
      denied: () => Future.value(),
      failure: () => Future.value(),
    );
  }

  Future<void> _updateLocation() async {
    setState(() => _loading = true);

    final location = await _getLocation();
    if (location != null && mounted) {
      setState(() => _location = location);
      await updateLocation(
        latitude: location.latitude,
        longitude: location.longitude,
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

    final api = GetIt.instance.get<Api>();
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
          _profiles.addAll(r.profiles.map((e) => e.profile));
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
        _userProfileInfoDisplayKey.currentState?.pause();
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

          return ValueListenableBuilder<double>(
            valueListenable: _pageListener,
            builder: (context, page, child) {
              final index = page.round();
              final profile = _profiles[index];
              return Stack(
                fit: StackFit.expand,
                children: [
                  // Must live above PageView.builder (otherwise duplicate global key)
                  UserProfileInfoDisplay(
                    key: _userProfileInfoDisplayKey,
                    profile: profile,
                    // invited: _invitedUsers.contains(profile.uid),
                    play: index == _currentProfileIndex && _pageActive,
                    builder: (context, play, playbackInfoStream) {
                      if (_showingList) {
                        return PageView.builder(
                          controller: _pageController,
                          itemCount: _profiles.length,
                          itemBuilder: (context, index) {
                            final profile = _profiles[index];
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
                                child: _ProfileDisplay(
                                  profile: profile,
                                  play: play,
                                  onPlayPause: () {
                                    if (!play) {
                                      _userProfileInfoDisplayKey.currentState
                                          ?.play();
                                    } else {
                                      _userProfileInfoDisplayKey.currentState
                                          ?.pause();
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
                                      _profiles.removeWhere(
                                          ((p) => p.uid == profile.uid))),
                                ),
                              ),
                            );
                          },
                        );
                      } else {
                        final latLong = _location == null
                            ? const LatLng(37.42796133580664, -122.085749655962)
                            : LatLng(_location!.latitude, _location!.longitude);
                        final CameraPosition pos = CameraPosition(
                          target: latLong,
                          zoom: 14.4746,
                        );
                        return GoogleMap(
                          mapType: MapType.hybrid,
                          initialCameraPosition: pos,
                          onMapCreated: (GoogleMapController controller) {
                            setState(() => _googleMapController = controller);
                          },
                        );
                      }
                    },
                  ),
                  Positioned(
                    left: 16 + 20,
                    top: MediaQuery.of(context).padding.top + 24 + 20,
                    child: _PageControls(
                      profile: profile,
                      preference: _genderPreference,
                      showingList: _showingList,
                      onPreference: (gender) {
                        if (gender == _genderPreference) {
                          return;
                        }
                        setState(() {
                          _genderPreference = gender;
                          _nextMinRadius = 0;
                          _nextPage = 0;
                          _pageController.jumpTo(0);
                          _profiles.clear();
                        });
                        _fetchPageOfProfiles();
                      },
                      onMap: () {
                        setState(() => _showingList = !_showingList);
                      },
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

    GetIt.instance.get<Mixpanel>().track(
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
        GetIt.instance.get<Api>().sendMessage(uid, ChatType.audio, file.path);
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
}

class _ProfileDisplay extends StatelessWidget {
  final Profile profile;
  final bool play;
  final VoidCallback onPlayPause;
  final VoidCallback onRecord;
  final VoidCallback onBlock;

  const _ProfileDisplay({
    super.key,
    required this.profile,
    required this.play,
    required this.onPlayPause,
    required this.onRecord,
    required this.onBlock,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          clipBehavior: Clip.hardEdge,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(48)),
          ),
          child: Button(
            onPressed: onPlayPause,
            child: UserProfileDisplay(
              key: ValueKey(profile.uid),
              profile: profile,
              playSlideshow: play,
              invited: false,
            ),
          ),
        ),
        if (!play)
          const Center(
            child: IgnorePointer(
              child: IconWithShadow(
                Icons.play_arrow,
                size: 80,
              ),
            ),
          ),
        Positioned(
          right: 22,
          top: 24,
          child: ReportBlockPopupMenu2(
            uid: profile.uid,
            name: profile.name,
            onBlock: onBlock,
            builder: (context) {
              return Container(
                width: 29,
                height: 29,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(8.0),
                decoration: const BoxDecoration(
                  color: Color.fromRGBO(0x5A, 0x5A, 0x5A, 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.ellipsis,
                  color: Colors.white,
                  size: 14,
                ),
              );
            },
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 120,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.5),
                ],
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: 51,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            margin: const EdgeInsets.only(bottom: 38),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AutoSizeText(
                        profile.name,
                        minFontSize: 15,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white),
                      ),
                      Row(
                        children: [
                          // Info icon with solid white background
                          Stack(
                            alignment: Alignment.center,
                            children: const [
                              SizedBox(
                                width: 10,
                                height: 10,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.info,
                                color: Color.fromRGBO(0xFF, 0x38, 0x38, 1.0),
                                size: 16,
                              ),
                            ],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text('1 mutual friends',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium!
                                    .copyWith(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.white)),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 146,
                  child: _RecordButton(
                    onPressed: onRecord,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RecordButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const _RecordButton({
    super.key,
    this.label = 'send message',
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Button(
      onPressed: onPressed,
      child: Container(
        width: 146,
        height: 51,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromRGBO(0xF3, 0x49, 0x50, 1.0),
              Color.fromRGBO(0xDF, 0x39, 0x3F, 1.0),
            ],
          ),
          borderRadius: BorderRadius.all(Radius.circular(25)),
          boxShadow: [
            BoxShadow(
              offset: Offset(0, 4),
              blurRadius: 4,
              color: Color.fromRGBO(0x00, 0x00, 0x00, 0.25),
            ),
          ],
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              fontSize: 14, fontWeight: FontWeight.w400, color: Colors.white),
        ),
      ),
    );
  }
}

class _PageControls extends StatelessWidget {
  final Profile? profile;
  final Gender? preference;
  final bool showingList;
  final void Function(Gender? preference) onPreference;
  final VoidCallback onMap;

  const _PageControls({
    super.key,
    required this.profile,
    required this.preference,
    required this.showingList,
    required this.onPreference,
    required this.onMap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Button(
          onPressed: () => _showPreferencesSheet(context),
          child: Container(
            width: 96,
            height: 35,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(32)),
              boxShadow: [
                BoxShadow(
                  offset: Offset(0, 2),
                  blurRadius: 4,
                  color: Color.fromRGBO(0x00, 0x00, 0x00, 0.25),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/preferences_icon.png',
                  color: Colors.black,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.medium,
                ),
                const SizedBox(width: 8),
                Text(
                  'Filters',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium!
                      .copyWith(fontSize: 14, fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Button(
          onPressed: onMap,
          child: Container(
            width: 96,
            height: 35,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(32)),
              boxShadow: [
                BoxShadow(
                  offset: Offset(0, 2),
                  blurRadius: 4,
                  color: Color.fromRGBO(0x00, 0x00, 0x00, 0.25),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                showingList
                    ? const Icon(
                        Icons.map,
                        color: Colors.black,
                      )
                    : const Icon(
                        Icons.list,
                        color: Colors.black,
                      ),
                const SizedBox(width: 8),
                Text(
                  showingList ? 'Map' : 'List',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium!
                      .copyWith(fontSize: 14, fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showPreferencesSheet(BuildContext context) async {
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
                  selected: preference == null,
                  onTap: () => Navigator.of(context).pop('any'),
                  radioAtEnd: true,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 19,
                      fontWeight: FontWeight.w400,
                      color: Colors.white),
                ),
                RadioTile(
                  label: 'Men',
                  selected: preference == Gender.male,
                  onTap: () => Navigator.of(context).pop('male'),
                  radioAtEnd: true,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 19,
                      fontWeight: FontWeight.w400,
                      color: Colors.white),
                ),
                RadioTile(
                  label: 'Women',
                  selected: preference == Gender.female,
                  onTap: () => Navigator.of(context).pop('female'),
                  radioAtEnd: true,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 19,
                      fontWeight: FontWeight.w400,
                      color: Colors.white),
                ),
                RadioTile(
                  label: 'Non-Binary',
                  selected: preference == Gender.nonBinary,
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
    if (genderString != null) {
      Gender? gender;
      try {
        gender =
            Gender.values.firstWhere((element) => element.name == genderString);
      } on StateError {
        // Ignore
      }
      onPreference(gender);
    }
  }
}

class _LatLong {
  final double latitude;
  final double longitude;
  const _LatLong(
    this.latitude,
    this.longitude,
  );
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
