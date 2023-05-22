import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:dartz/dartz.dart' show Either;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide Chip;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openup/analytics/analytics.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/chat_api.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/menu_page.dart';
import 'package:openup/util/location_service.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/discover_list.dart';
import 'package:openup/widgets/discover_map.dart';
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
  bool _fetchingProfiles = false;
  bool _errorLoadingProfiles = false;
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

  int? _profileIndex;
  final _invitedUsers = <String>{};

  final _profileBuilderKey = GlobalKey<ProfileBuilderState>();

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
          _profileIndex = null;
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
    final prevLocation = _queryLocation;
    if (prevLocation != null) {
      final panned =
          greatCircleDistance(prevLocation.latLong, location.latLong) >
              prevLocation.radius * 1 / 3;
      final ratio = location.radius / prevLocation.radius;
      final zoomed = ratio > 2 || ratio < 1 / 2;
      if (panned || zoomed) {
        setState(() => _queryLocation = location);
        _queryProfilesAt(location);
      }
    }
  }

  void _onProfileChanged(int? index) {
    setState(() {
      _profileIndex = index;
      _ignoreNextLocationChange = true;
      _discoverOperation?.cancel();
      _fetchingProfiles = false;
    });
    _profileBuilderKey.currentState?.play();
  }

  @override
  Widget build(BuildContext context) {
    return ActivePage(
      onActivate: () {
        setState(() => _pageActive = true);
        final queryLocation = _queryLocation;
        if (queryLocation != null) {
          _queryProfilesAt(queryLocation);
        }
        ;
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

          final profileIndex = _profileIndex;
          final profile = (_profiles.isEmpty || profileIndex == null)
              ? null
              : _profiles[profileIndex].profile;
          return LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  // Must live above PageView.builder (otherwise duplicate global key)
                  ProfileBuilder(
                    key: _profileBuilderKey,
                    profile: profile,
                    play: _pageActive,
                    builder: (context, play, playbackInfoStream) {
                      return Stack(
                        children: [
                          _buildMapView(
                            play: play,
                            initialLocation: initialLocation,
                            onLocationChanged: _maybeRefetchProfiles,
                            bottomBuilder: (context) {
                              if (profileIndex == null) {
                                return const SizedBox.shrink();
                              }
                              return _buildListView(
                                profileIndex: profileIndex,
                                play: play,
                                onProfilePressed: () {
                                  if (profile == null) {
                                    return;
                                  }
                                  _showFullProfile(
                                    context: context,
                                    profile: profile,
                                    play: play,
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
                  Positioned(
                    left: 16,
                    top: MediaQuery.of(context).padding.top + 24 + 20,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ProfileButton(
                          onPressed: () async {
                            final prevGender = _gender;
                            final gender = await _showPreferencesSheet();
                            if (mounted && gender != prevGender) {
                              setState(() {
                                _gender = gender;
                                _profileIndex = null;
                                _profiles.clear();
                              });
                              final queryLocation = _queryLocation;
                              if (queryLocation != null) {
                                _queryProfilesAt(queryLocation);
                              }
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
                      ],
                    ),
                  ),
                  if (_queryLocation != null)
                    Positioned(
                      left: 16 + 100,
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
                                  _gender = gender;
                                  _profileIndex = 0;
                                  _profiles.clear();
                                });
                                final queryLocation = _queryLocation;
                                if (queryLocation != null) {
                                  _queryProfilesAt(queryLocation);
                                }
                              }
                            },
                            icon: Switch(
                              value: _showDebugUsers,
                              onChanged: (show) {
                                setState(() => _showDebugUsers = show);
                                _queryProfilesAt(_queryLocation!);
                              },
                            ),
                            label: const Text('Show fake users'),
                          ),
                        ],
                      ),
                    ),
                  if (_fetchingProfiles)
                    Positioned(
                      left: 0,
                      top: MediaQuery.of(context).padding.top + 24 + 72,
                      right: 0,
                      height: 4,
                      child: const LinearProgressIndicator(),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildListView({
    required int profileIndex,
    required bool play,
    required VoidCallback onProfilePressed,
  }) {
    final profile = _profiles[profileIndex].profile;
    return DiscoverList(
      profiles: _profiles,
      profileIndex: profileIndex,
      onProfileChanged: (index) {
        // final scrollingForward = index > _profileIndex;
        // if (scrollingForward) {
        //   _precacheImageAndDepth(_profiles, from: index + 1, count: 2);
        // }
        _onProfileChanged(index);
      },
      play: play,
      onPlayPause: () {
        if (!play) {
          _profileBuilderKey.currentState?.play();
        } else {
          _profileBuilderKey.currentState?.pause();
        }
      },
      onRecord: () {
        _showRecordPanelOrSignIn(context, profile.uid);
      },
      onProfilePressed: onProfilePressed,
    );
  }

  Widget _buildMapView({
    required bool play,
    required Location initialLocation,
    required ValueChanged<Location> onLocationChanged,
    required WidgetBuilder bottomBuilder,
  }) {
    return DiscoverMap(
      profiles: _profiles,
      profileIndex: _profileIndex,
      onProfileChanged: _onProfileChanged,
      bottomBuilder: bottomBuilder,
      initialLocation: initialLocation,
      onLocationChanged: onLocationChanged,
      showRecordPanel: () {
        // final profile =
        //     _profiles.isEmpty ? null : _profiles[_profileIndex].profile;
        // if (profile != null) {
        //   _showRecordPanelOrSignIn(context, profile.uid);
        // }
      },
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

  void _showFullProfile({
    required BuildContext context,
    required Profile profile,
    required bool play,
  }) {
    showBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          margin: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16 + MediaQuery.of(context).padding.top,
          ),
          clipBehavior: Clip.hardEdge,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(64)),
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
              _showRecordPanelOrSignIn(context, profile.uid);
            },
            onBlock: () {
              setState(() =>
                  _profiles.removeWhere(((p) => p.profile.uid == profile.uid)));
              Navigator.of(context).pop();
            },
          ),
        );
      },
    );
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
                  selected: _gender == null,
                  onTap: () => Navigator.of(context).pop('any'),
                  radioAtEnd: true,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 19,
                      fontWeight: FontWeight.w400,
                      color: Colors.white),
                ),
                RadioTile(
                  label: 'Men',
                  selected: _gender == Gender.male,
                  onTap: () => Navigator.of(context).pop('male'),
                  radioAtEnd: true,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 19,
                      fontWeight: FontWeight.w400,
                      color: Colors.white),
                ),
                RadioTile(
                  label: 'Women',
                  selected: _gender == Gender.female,
                  onTap: () => Navigator.of(context).pop('female'),
                  radioAtEnd: true,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 19,
                      fontWeight: FontWeight.w400,
                      color: Colors.white),
                ),
                RadioTile(
                  label: 'Non-Binary',
                  selected: _gender == Gender.nonBinary,
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
