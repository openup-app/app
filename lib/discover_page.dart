import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:async/async.dart';
import 'package:dartz/dartz.dart' show Either;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide Chip;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:openup/analytics/analytics.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/chat_api.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/shell_page.dart';
import 'package:openup/util/location_service.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/discover_list.dart';
import 'package:openup/widgets/discover_map.dart';
import 'package:openup/widgets/profile_display.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class DiscoverPage extends ConsumerStatefulWidget {
  final VoidCallback onShowConversations;
  final VoidCallback onShowSettings;

  const DiscoverPage({
    Key? key,
    required this.onShowConversations,
    required this.onShowSettings,
  }) : super(key: key);

  @override
  ConsumerState<DiscoverPage> createState() => DiscoverPageState();
}

class DiscoverPageState extends ConsumerState<DiscoverPage>
    with SingleTickerProviderStateMixin {
  bool _fetchingProfiles = false;
  Gender? _gender;
  bool _pageActive = false;

  bool _showDebugUsers = false;

  CancelableOperation<Either<ApiError, DiscoverResultsPage>>?
      _discoverOperation;
  final _profiles = <DiscoverProfile>[];
  Location? _initialLocation;
  Location? _queryLocation;
  static const _kMinRadius = 4000.0;

  bool _ignoreNextLocationChange = false;

  DiscoverProfile? _selectedProfile;
  final _invitedUsers = <String>{};

  final _profileBuilderKey = GlobalKey<ProfileBuilderState>();

  final _mapKey = GlobalKey<DiscoverMapState>();
  MarkerRenderStatus _markerRenderStatus = MarkerRenderStatus.ready;

  late final _bottomSheetController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );

  @override
  void initState() {
    super.initState();
    _maybeRequestLocationPermission().then((_) {
      _updateLocation().then((latLong) {
        if (mounted && latLong != null) {
          final location = Location(latLong: latLong, radius: _kMinRadius);
          setState(() {
            _queryLocation = location;
            _initialLocation = location;
          });
          _queryProfilesAt(location).then((_) {
            _maybeRequestNotification();
          });
        }
      });
    });
    _bottomSheetController.addListener(_bottomSheetUpdated);
  }

  @override
  void dispose() {
    _bottomSheetController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _precacheImageAndDepth(_profiles, from: 1, count: 2);
  }

  void _bottomSheetUpdated() {}

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

  Future<LatLong?> _updateLocation() async {
    final latLong = await _getLocation();
    if (latLong != null && mounted) {
      ref.read(locationProvider.notifier).update(LocationValue(latLong));
      await updateLocation(
        ref: ref,
        latLong: latLong,
      );
    }
    return latLong;
  }

  Future<void> _queryProfilesAt(Location location) async {
    setState(() => _fetchingProfiles = true);
    final api = ref.read(apiProvider);
    _discoverOperation?.cancel();
    final discoverFuture = api.getDiscover(
      location: location,
      gender: _gender,
      debug: _showDebugUsers,
    );
    _discoverOperation = CancelableOperation.fromFuture(discoverFuture);
    final profiles = await _discoverOperation?.value;

    if (!mounted || profiles == null) {
      return;
    }
    setState(() => _fetchingProfiles = false);

    profiles.fold(
      (l) {
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
          _profiles
            ..clear()
            ..addAll(r.profiles);
        });
      },
    );
  }

  void _maybeRefetchProfiles(Location location) {
    if (_ignoreNextLocationChange) {
      setState(() => _ignoreNextLocationChange = false);
      return;
    }

    // Reduced radius for improved experience when searching
    final targetLocation = location.copyWith(radius: location.radius * 0.5);
    final prevLocation = _queryLocation;
    if (prevLocation != null) {
      final panRatio =
          greatCircleDistance(prevLocation.latLong, targetLocation.latLong) /
              prevLocation.radius;
      final zoomRatio = targetLocation.radius / prevLocation.radius;
      final panned = panRatio > 1 / 3;
      final zoomed = zoomRatio > 5 / 3 || zoomRatio < 2 / 3;
      if (panned || zoomed) {
        setState(() => _queryLocation = targetLocation);
        _queryProfilesAt(targetLocation);
      }
    }
  }

  void _onProfileChanged(DiscoverProfile? selectedProfile) {
    setState(() {
      _selectedProfile = selectedProfile;
      _ignoreNextLocationChange = true;
      _discoverOperation?.cancel();
      _fetchingProfiles = false;
    });
    _profileBuilderKey.currentState?.play();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoScaffold(
      body: ActivePage(
        onActivate: () {
          setState(() => _pageActive = true);
          final queryLocation = _queryLocation;
          if (queryLocation != null) {
            _queryProfilesAt(queryLocation);
          }
        },
        onDeactivate: () {
          _profileBuilderKey.currentState?.pause();
          setState(() => _pageActive = false);
        },
        child: Builder(
          builder: (context) {
            final initialLocation = _initialLocation;
            if (initialLocation == null) {
              return const Center(
                child: LoadingIndicator(),
              );
            }

            final profiles = List.of(_profiles);
            final selectedProfile = _selectedProfile;
            return Stack(
              fit: StackFit.expand,
              children: [
                DiscoverMap(
                  key: _mapKey,
                  profiles: _profiles,
                  selectedProfile: _selectedProfile,
                  onProfileChanged: _onProfileChanged,
                  initialLocation: initialLocation,
                  onLocationChanged: _maybeRefetchProfiles,
                  showRecordPanel: () {
                    final selectedProfile = _selectedProfile;
                    if (selectedProfile != null) {
                      _showRecordPanelOrSignIn(
                          context, selectedProfile.profile.uid);
                    }
                  },
                  onMarkerRenderStatus: (status) {
                    setState(() => _markerRenderStatus = status);
                  },
                ),
                if (_queryLocation != null)
                  Positioned(
                    left: 16,
                    top: MediaQuery.of(context).padding.top + 16,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Opacity(
                          opacity: 0.8,
                          child: Button(
                            onPressed: () {
                              setState(
                                  () => _showDebugUsers = !_showDebugUsers);
                              _queryProfilesAt(_queryLocation!);
                            },
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.all(
                                  Radius.circular(24),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Switch(
                                    value: _showDebugUsers,
                                    onChanged: (show) {
                                      setState(() => _showDebugUsers = show);
                                      _queryProfilesAt(_queryLocation!);
                                    },
                                  ),
                                  const Text(
                                    'Fake users',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  const SizedBox(width: 12),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Positioned(
                  top: MediaQuery.of(context).padding.top + 16,
                  right: 16,
                  child: Consumer(
                    builder: (context, ref, child) {
                      final myProfile = ref.watch(userProvider2.select(
                        (p) => p.map(
                            guest: (_) => null,
                            signedIn: (signedIn) => signedIn.profile),
                      ));
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (myProfile != null) ...[
                            Button(
                              onPressed: widget.onShowSettings,
                              child: Container(
                                width: 45,
                                height: 45,
                                clipBehavior: Clip.hardEdge,
                                foregroundDecoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(width: 2, color: Colors.white),
                                ),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      offset: Offset(0, 4),
                                      blurRadius: 8,
                                      color: Color.fromRGBO(
                                          0x00, 0x00, 0x00, 0.25),
                                    ),
                                  ],
                                ),
                                child: Image.network(
                                  myProfile.photo,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(height: 19),
                            _MapButton(
                              onPressed: () {},
                              child: const Icon(
                                Icons.location_on,
                                color: Color.fromRGBO(0x24, 0xFF, 0x00, 1.0),
                              ),
                            ),
                            const SizedBox(height: 11),
                          ],
                          Consumer(
                            builder: (context, ref, child) {
                              final latLong =
                                  ref.watch(locationProvider)?.latLong;
                              return _MapButton(
                                onPressed: latLong == null
                                    ? null
                                    : () => _mapKey.currentState
                                        ?.recenterMap(latLong),
                                child: const Icon(
                                  CupertinoIcons.location_fill,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ),
                Positioned(
                  left: 0,
                  bottom: 0,
                  right: 0,
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Align(
                            alignment: Alignment.centerRight,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                _MapButton(
                                  onPressed: () {},
                                  child: const Icon(
                                    Icons.circle,
                                    size: 16,
                                    color:
                                        Color.fromRGBO(0xFF, 0x00, 0x00, 1.0),
                                  ),
                                ),
                                const SizedBox(width: 13),
                                _MapButton(
                                  onPressed: widget.onShowConversations,
                                  child: const Icon(
                                    Icons.email,
                                    color:
                                        Color.fromRGBO(0x0A, 0x7B, 0xFF, 1.0),
                                  ),
                                ),
                                const SizedBox(width: 16),
                              ],
                            ),
                          ),
                          Center(
                            child: IgnorePointer(
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOutQuart,
                                opacity: (_fetchingProfiles ||
                                        _markerRenderStatus ==
                                            MarkerRenderStatus.rendering)
                                    ? 1
                                    : 0,
                                child: Lottie.asset(
                                  'assets/images/map_searching.json',
                                  width: 100,
                                  height: 48,
                                  animate: _fetchingProfiles ||
                                      _markerRenderStatus ==
                                          MarkerRenderStatus.rendering,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 11),
                      _ProfilePanel(
                        gender: _gender,
                        onGenderChanged: (gender) {
                          setState(() {
                            _gender = gender;
                            _selectedProfile = null;
                            _profiles.clear();
                          });
                          _mapKey.currentState?.resetMarkers();
                          final queryLocation = _queryLocation;
                          if (queryLocation != null) {
                            _queryProfilesAt(queryLocation);
                          }
                        },
                        profiles: profiles,
                        selectedProfile: selectedProfile,
                        onProfileChanged: (profile) {
                          setState(() {
                            _ignoreNextLocationChange = true;
                            _selectedProfile = profile;
                          });
                        },
                        profileBuilderKey: _profileBuilderKey,
                        onRecordInvite: (profile) {
                          _showRecordPanelOrSignIn(context, profile.uid);
                        },
                        onToggleFavorite: () {
                          if (selectedProfile != null) {
                            _toggleFavorite(selectedProfile);
                          }
                        },
                        onBlockUser: (profile) {
                          setState(() => _profiles.removeWhere(
                              ((p) => p.profile.uid == profile.uid)));
                        },
                        pageActive: _pageActive,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showRecordPanelOrSignIn(BuildContext context, String uid) {
    final userState = ref.read(userProvider2);
    userState.map(
      guest: (_) {
        _showSignInDialog();
      },
      signedIn: (_) {
        _showRecordPanel(context, uid);
      },
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

  void _toggleFavorite(DiscoverProfile profile) async {
    final api = ref.read(apiProvider);
    Either<ApiError, DiscoverProfile> result;
    var index =
        _profiles.indexWhere((p) => p.profile.uid == profile.profile.uid);
    if (index != -1) {
      setState(() {
        _profiles.replaceRange(
          index,
          index + 1,
          [profile.copyWith(favorite: !profile.favorite)],
        );
      });
    }
    setState(() {
      _selectedProfile =
          _selectedProfile?.copyWith(favorite: !_selectedProfile!.favorite);
    });
    if (profile.favorite) {
      result = await api.removeFavorite(profile.profile.uid);
    } else {
      result = await api.addFavorite(profile.profile.uid);
    }

    if (!mounted) {
      return;
    }

    index = _profiles.indexWhere((p) => p.profile.uid == profile.profile.uid);
    result.fold(
      (l) {
        if (index != -1) {
          setState(() => _profiles.replaceRange(index, index + 1, [profile]));
        }
        displayError(context, l);
      },
      (r) {
        if (index != -1) {
          setState(() => _profiles.replaceRange(index, index + 1, [r]));
        }
      },
    );
  }
}

class _ProfilePanel extends StatefulWidget {
  final Gender? gender;
  final ValueChanged<Gender?> onGenderChanged;
  final List<DiscoverProfile> profiles;
  final DiscoverProfile? selectedProfile;
  final ValueChanged<DiscoverProfile?> onProfileChanged;
  final GlobalKey<ProfileBuilderState> profileBuilderKey;
  final void Function(Profile profile) onRecordInvite;
  final VoidCallback onToggleFavorite;
  final void Function(Profile profile) onBlockUser;
  final bool pageActive;

  const _ProfilePanel({
    super.key,
    required this.gender,
    required this.onGenderChanged,
    required this.profiles,
    required this.selectedProfile,
    required this.onProfileChanged,
    required this.profileBuilderKey,
    required this.onRecordInvite,
    required this.onToggleFavorite,
    required this.onBlockUser,
    required this.pageActive,
  });

  @override
  State<_ProfilePanel> createState() => _ProfilePanelState();
}

class _ProfilePanelState extends State<_ProfilePanel> {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(24),
        topRight: Radius.circular(24),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          color: const Color.fromRGBO(0x10, 0x12, 0x12, 0.5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 24),
              Button(
                onPressed: () async {
                  final prevGender = widget.gender;
                  final gender = await _showPreferencesSheet();
                  if (mounted && gender != prevGender) {
                    widget.onGenderChanged(gender);
                  }
                },
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: const BoxDecoration(
                    color: Color.fromRGBO(0x29, 0x2C, 0x2E, 1.0),
                    borderRadius: BorderRadius.all(
                      Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        offset: Offset(0, 2),
                        blurRadius: 12,
                        color: Color.fromRGBO(0x00, 0x00, 0x00, 0.35),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.search,
                        size: 20,
                        color: Color.fromRGBO(0xF4, 0xF4, 0xF4, 1.0),
                      ),
                      Expanded(
                        child: Text(
                          'Who are you searching for?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Color.fromRGBO(0xF4, 0xF4, 0xF4, 1.0),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 19),

              // Must live above PageView.builder (otherwise duplicate global key)
              ProfileBuilder(
                key: widget.profileBuilderKey,
                profile: widget.selectedProfile?.profile,
                play: widget.pageActive,
                builder: (context, play, playbackInfoStream) {
                  final selectedProfile = widget.selectedProfile;
                  return AnimatedSize(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutQuart,
                    child: Builder(
                      builder: (context) {
                        if (selectedProfile == null) {
                          return const SizedBox(
                            height: 0,
                            width: double.infinity,
                          );
                        }
                        return DiscoverList(
                          profiles: widget.profiles,
                          selectedProfile: selectedProfile,
                          onProfileChanged: (profile) {
                            // final scrollingForward = index > _profileIndex;
                            // if (scrollingForward) {
                            //   _precacheImageAndDepth(_profiles, from: index + 1, count: 2);
                            // }
                            widget.onProfileChanged(profile);
                          },
                          play: play,
                          onPlayPause: () => _onPlayPause(play),
                          onToggleFavorite: widget.onToggleFavorite,
                          onRecord: () =>
                              widget.onRecordInvite(selectedProfile.profile),
                          onProfilePressed: () {
                            CupertinoScaffold.showCupertinoModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.transparent,
                              builder: (context) {
                                return Container(
                                  clipBehavior: Clip.hardEdge,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(56),
                                      topRight: Radius.circular(56),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        offset: Offset(0, 2),
                                        blurRadius: 12,
                                        color: Color.fromRGBO(
                                            0x00, 0x00, 0x00, 0.25),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const SizedBox(height: 9),
                                      Container(
                                        width: 37,
                                        height: 5,
                                        decoration: const BoxDecoration(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(2.5)),
                                          color: Color.fromRGBO(
                                              0xE0, 0xE0, 0xE0, 1.0),
                                        ),
                                      ),
                                      const SizedBox(height: 9),
                                      Expanded(
                                        child: DiscoverListFull(
                                          profiles: widget.profiles,
                                          selectedProfile: selectedProfile,
                                          onProfileChanged: (profile) {
                                            widget.onProfileChanged(profile);
                                          },
                                          play: play,
                                          onPlayPause: () => _onPlayPause(play),
                                          onRecord: () => widget.onRecordInvite(
                                              selectedProfile.profile),
                                          onBlock: () {
                                            widget.onBlockUser(
                                                selectedProfile.profile);
                                            widget.onProfileChanged(null);
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: MediaQuery.of(context).padding.bottom,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onPlayPause(bool playing) {
    if (!playing) {
      widget.profileBuilderKey.currentState?.play();
    } else {
      widget.profileBuilderKey.currentState?.pause();
    }
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
                  selected: widget.gender == null,
                  onTap: () => Navigator.of(context).pop('any'),
                  radioAtEnd: true,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 19,
                      fontWeight: FontWeight.w400,
                      color: Colors.white),
                ),
                RadioTile(
                  label: 'Men',
                  selected: widget.gender == Gender.male,
                  onTap: () => Navigator.of(context).pop('male'),
                  radioAtEnd: true,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 19,
                      fontWeight: FontWeight.w400,
                      color: Colors.white),
                ),
                RadioTile(
                  label: 'Women',
                  selected: widget.gender == Gender.female,
                  onTap: () => Navigator.of(context).pop('female'),
                  radioAtEnd: true,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 19,
                      fontWeight: FontWeight.w400,
                      color: Colors.white),
                ),
                RadioTile(
                  label: 'Non-Binary',
                  selected: widget.gender == Gender.nonBinary,
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

class _MapButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;

  const _MapButton({
    super.key,
    required this.onPressed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 45,
      height: 45,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(13)),
        boxShadow: [
          BoxShadow(
            offset: Offset(0, 4),
            blurRadius: 8,
            color: Color.fromRGBO(0x00, 0x00, 0x00, 0.25),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(13)),
        child: Button(
          onPressed: onPressed,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 13, sigmaY: 13),
            child: ColoredBox(
              color: const Color.fromRGBO(0x1A, 0x1D, 0x1E, 0.9),
              child: OverflowBox(
                minWidth: 56,
                minHeight: 56,
                maxWidth: 56,
                maxHeight: 56,
                alignment: Alignment.center,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
