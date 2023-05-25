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

  final _mapKey = GlobalKey<DiscoverMapState>();

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

          return LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  Stack(
                    children: [
                      _buildMapView(
                        initialLocation: initialLocation,
                        onLocationChanged: _maybeRefetchProfiles,
                      ),
                    ],
                  ),
                  if (_queryLocation != null)
                    Positioned(
                      left: 16,
                      top: MediaQuery.of(context).padding.top + 16,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ProfileButton(
                            onPressed: () {},
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
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 16,
                    right: 16,
                    width: 48,
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
                                  clipBehavior: Clip.hardEdge,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      width: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                  child: Image.network(
                                    myProfile.photo,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              _MapButton(
                                onPressed: () => _mapKey.currentState
                                    ?.recenterMap(ref.read(locationProvider)),
                                child: const Icon(
                                  Icons.location_on,
                                  color: Color.fromRGBO(0x24, 0xFF, 0x00, 1.0),
                                ),
                              ),
                            ],
                            _MapButton(
                              onPressed: () => _mapKey.currentState
                                  ?.recenterMap(ref.read(locationProvider)),
                              child: const Icon(
                                CupertinoIcons.location_fill,
                                color: Color.fromRGBO(0x22, 0x53, 0xFF, 1.0),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _BottomSheet(
                      gender: _gender,
                      onGenderChanged: (gender) {
                        setState(() {
                          _gender = gender;
                          _profileIndex = null;
                          _profiles.clear();
                        });
                        final queryLocation = _queryLocation;
                        if (queryLocation != null) {
                          _queryProfilesAt(queryLocation);
                        }
                      },
                      profiles: _profiles,
                      profileIndex: _profileIndex,
                      onProfileIndexChanged: (profileIndex) {
                        setState(() => _profileIndex = profileIndex);
                      },
                      profileBuilderKey: _profileBuilderKey,
                      onRecordInvite: (profile) {
                        _showRecordPanelOrSignIn(context, profile.uid);
                      },
                      onBlockUser: (profile) {
                        setState(() => _profiles.removeWhere(
                            ((p) => p.profile.uid == profile.uid)));
                      },
                      onShowConversations: widget.onShowConversations,
                      pageActive: _pageActive,
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

  Widget _buildMapView({
    required Location initialLocation,
    required ValueChanged<Location> onLocationChanged,
  }) {
    return DiscoverMap(
      key: _mapKey,
      profiles: _profiles,
      profileIndex: _profileIndex,
      onProfileChanged: _onProfileChanged,
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

class _BottomSheet extends StatefulWidget {
  final Gender? gender;
  final ValueChanged<Gender?> onGenderChanged;
  final List<DiscoverProfile> profiles;
  final int? profileIndex;
  final ValueChanged<int> onProfileIndexChanged;
  final GlobalKey<ProfileBuilderState> profileBuilderKey;
  final void Function(Profile profile) onRecordInvite;
  final void Function(Profile profile) onBlockUser;
  final VoidCallback onShowConversations;
  final bool pageActive;

  const _BottomSheet({
    super.key,
    required this.gender,
    required this.onGenderChanged,
    required this.profiles,
    required this.profileIndex,
    required this.onProfileIndexChanged,
    required this.profileBuilderKey,
    required this.onRecordInvite,
    required this.onBlockUser,
    required this.onShowConversations,
    required this.pageActive,
  });

  @override
  State<_BottomSheet> createState() => _BottomSheetState();
}

class _BottomSheetState extends State<_BottomSheet>
    with SingleTickerProviderStateMixin {
  late final _animationController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileIndex = widget.profileIndex;
    final Profile? profile;
    if (profileIndex == null) {
      profile = null;
    } else {
      profile = widget.profiles[profileIndex].profile;
    }
    return BottomSheet(
      animationController: _animationController,
      backgroundColor: Colors.transparent,
      onClosing: () {},
      builder: (context) {
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _MapButton(
                  onPressed: () {},
                  child: const Icon(
                    Icons.circle,
                    size: 16,
                    color: Color.fromRGBO(0xFF, 0x00, 0x00, 1.0),
                  ),
                ),
                const SizedBox(width: 8),
                _MapButton(
                  onPressed: widget.onShowConversations,
                  child: const Icon(
                    Icons.email,
                    color: Color.fromRGBO(0x0A, 0x7B, 0xFF, 1.0),
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
            Container(
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                color: Color.fromRGBO(0x10, 0x12, 0x12, 0.9),
              ),
              child: Builder(
                builder: (context) {
                  return Column(
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: Container(
                          width: 46,
                          height: 5,
                          margin: const EdgeInsets.only(top: 8, bottom: 11),
                          decoration: const BoxDecoration(
                            color: Color.fromRGBO(0x6F, 0x72, 0x73, 1.0),
                            borderRadius: BorderRadius.all(
                              Radius.circular(2.5),
                            ),
                          ),
                        ),
                      ),
                      ProfileButton(
                        onPressed: () async {
                          final prevGender = widget.gender;
                          final gender = await _showPreferencesSheet();
                          if (mounted && gender != prevGender) {
                            widget.onGenderChanged(gender);
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

                      // Must live above PageView.builder (otherwise duplicate global key)
                      ProfileBuilder(
                        key: widget.profileBuilderKey,
                        profile: profile,
                        play: widget.pageActive,
                        builder: (context, play, playbackInfoStream) {
                          if (profileIndex == null || profile == null) {
                            return const SizedBox.shrink();
                          }
                          return _buildListView(
                            profile: profile,
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

  Widget _buildListView({
    required Profile profile,
    required int profileIndex,
    required bool play,
    required VoidCallback onProfilePressed,
  }) {
    return DiscoverList(
      profiles: widget.profiles,
      profileIndex: profileIndex,
      onProfileChanged: (index) {
        // final scrollingForward = index > _profileIndex;
        // if (scrollingForward) {
        //   _precacheImageAndDepth(_profiles, from: index + 1, count: 2);
        // }
        widget.onProfileIndexChanged(index);
      },
      play: play,
      onPlayPause: () {
        if (!play) {
          widget.profileBuilderKey.currentState?.play();
        } else {
          widget.profileBuilderKey.currentState?.pause();
        }
      },
      onRecord: () => widget.onRecordInvite(profile),
      onProfilePressed: onProfilePressed,
    );
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
                widget.profileBuilderKey.currentState?.play();
              } else {
                widget.profileBuilderKey.currentState?.pause();
              }
            },
            onRecord: () {
              widget.onRecordInvite(profile);
            },
            onBlock: () {
              widget.onBlockUser(profile);
              Navigator.of(context).pop();
            },
          ),
        );
      },
    );
  }
}

class _MapButton extends StatelessWidget {
  final Widget child;
  final Color color;
  final VoidCallback onPressed;

  const _MapButton({
    super.key,
    required this.onPressed,
    this.color = const Color.fromRGBO(0x1A, 0x1D, 0x1E, 0.9),
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Button(
      onPressed: onPressed,
      child: Container(
        width: 48,
        height: 48,
        clipBehavior: Clip.hardEdge,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.all(Radius.circular(13)),
          boxShadow: const [
            BoxShadow(
              offset: Offset(0, 2),
              blurRadius: 13,
              color: Color.fromRGBO(0x00, 0x00, 0x00, 0.25),
            )
          ],
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}
