import 'dart:async';
import 'dart:ui';

import 'package:async/async.dart';
import 'package:collection/collection.dart';
import 'package:dartz/dartz.dart' show Either;
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Chip;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openup/analytics/analytics.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/chat_state.dart';
import 'package:openup/api/user_profile_cache.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/discover/discover_provider.dart';
import 'package:openup/discover_map_provider.dart';
import 'package:openup/dynamic_config/dynamic_config.dart';
import 'package:openup/location/location_provider.dart';
import 'package:openup/location/location_service.dart';
import 'package:openup/shell_page.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/discover_list.dart';
import 'package:openup/widgets/discover_map.dart';
import 'package:openup/widgets/drag_handle.dart';
import 'package:openup/widgets/profile_display.dart';
import 'package:openup/widgets/record.dart';
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
  Location? _mapLocation;
  Location? _prevQueryLocation;
  DiscoverProfile? _selectedProfile;
  String? _selectUidWhenAvailable;
  final _invitedUsers = <String>{};

  final _profileBuilderKey = GlobalKey<ProfileBuilderState>();

  final _mapKey = GlobalKey<DiscoverMapState>();
  MarkerRenderStatus _markerRenderStatus = MarkerRenderStatus.ready;

  bool _hasShownStartupModals = false;

  Timer? _audioBioUpdatedAnimationTimer;

  @override
  void initState() {
    super.initState();
    _maybeRequestNotification();
    ref.listenManual<LocationMessage?>(locationMessageProvider,
        (previous, next) {
      if (next == null) {
        return;
      }
      switch (next) {
        case LocationMessage.permissionRationale:
          _showLocationPermissionRationale();
          break;
      }
    });

    ref.listenManual<DiscoverAction?>(
      discoverProvider,
      (previous, next) {
        if (next == null) {
          return;
        }

        next.map(
          viewProfile: (viewProfile) {
            final profile = viewProfile.profile;
            _mapKey.currentState?.recenterMap(profile.location.latLong);
            setState(() => _selectUidWhenAvailable = profile.profile.uid);
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _audioBioUpdatedAnimationTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _precacheImageAndDepth(_profiles, from: 1, count: 2);

    Future.delayed(Duration.zero).then((_) {
      if (!mounted) {
        return;
      }
      if (!_hasShownStartupModals) {
        _hasShownStartupModals = true;
        _showStartupModals();
      }
    });
  }

  void _precacheImageAndDepth(
    List<DiscoverProfile> profiles, {
    required int from,
    required int count,
  }) {
    profiles.skip(from).take(count).forEach((discoverProfile) {
      discoverProfile.profile.gallery.forEach((photoUrl) {
        precacheImage(NetworkImage(photoUrl), context);
      });
    });
  }

  Future<void> _maybeRequestNotification() async {
    final status = await Permission.notification.status;
    if (!(status.isGranted || status.isLimited)) {
      await Permission.notification.request();
    }
  }

  void _showStartupModals() async {
    final showSafetyNoticeSubscription = ref.listenManual<bool>(
      showSafetyNoticeProvider,
      (prev, next) => prev == null && next,
      fireImmediately: true,
    );

    final shouldShowSafetyNotice = showSafetyNoticeSubscription.read();
    if (shouldShowSafetyNotice) {
      await showSafetyAndPrivacyModal(context);
    }

    if (!mounted) {
      return;
    }

    final isSignedOutProvider = userProvider2.select((p) {
      return p.map(
        guest: (guest) => !guest.byDefault,
        signedIn: (_) => false,
      );
    });
    ref.listenManual<bool>(
      isSignedOutProvider,
      fireImmediately: true,
      (previous, next) {
        if (next) {
          _tempPauseAudio();
          showSignupGuestModal(
            context,
            onShowSignup: () => context.pushNamed('signup'),
          );
        }
      },
    );
  }

  Future<void> _performQuery() {
    final location = _mapLocation;
    if (location != null) {
      setState(() {
        _prevQueryLocation = location;
        _selectedProfile = null;
      });
      return _queryProfilesAt(location.copyWith(radius: location.radius * 0.5));
    }
    return Future.value();
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
        DiscoverProfile? profileToSelect;
        final targetUid = _selectUidWhenAvailable;
        if (targetUid != null) {
          profileToSelect =
              r.profiles.firstWhereOrNull((p) => p.profile.uid == targetUid);
        }
        setState(() {
          _selectUidWhenAvailable = null;
          _selectedProfile = profileToSelect;
          _profiles
            ..clear()
            ..addAll(r.profiles);
        });
      },
    );
  }

  void _tempPauseAudio() {
    _profileBuilderKey.currentState?.pause();
  }

  bool _areLocationsDistant(Location a, Location b) {
    // Reduced radius for improved experience when searching
    final panRatio = greatCircleDistance(a.latLong, b.latLong) / a.radius;
    final zoomRatio = b.radius / a.radius;
    final panned = panRatio > 0.5;
    final zoomed = zoomRatio > 2.0 || zoomRatio < 0.5;
    if (panned || zoomed) {
      return true;
    }
    return false;
  }

  void _onProfileChanged(DiscoverProfile? selectedProfile) {
    setState(() {
      _selectedProfile = selectedProfile;
      _discoverOperation?.cancel();
      _fetchingProfiles = false;
    });
    _profileBuilderKey.currentState?.play();
  }

  @override
  Widget build(BuildContext context) {
    final profiles = List.of(_profiles);
    final selectedProfile = _selectedProfile;
    return ActivePage(
      activeOnSheetOpen: false,
      onActivate: () {
        setState(() => _pageActive = true);
        _performQuery();
      },
      onDeactivate: () {
        _profileBuilderKey.currentState?.pause();
        setState(() => _pageActive = false);
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final height = constraints.biggest.height;
              return ColoredBox(
                color: Colors.black,
                child: DiscoverMap(
                  key: _mapKey,
                  profiles: _profiles,
                  selectedProfile: _selectedProfile,
                  onProfileChanged: _onProfileChanged,
                  initialLocation: Location(
                    latLong: ref.read(locationProvider).initialLatLong,
                    radius: 1800,
                  ),
                  onLocationChanged: (location) {
                    setState(() => _mapLocation =
                        location.copyWith(radius: location.radius));
                    final prevQueryLocation = _prevQueryLocation;
                    if (prevQueryLocation == null ||
                        _areLocationsDistant(location, prevQueryLocation)) {
                      _performQuery();
                    }
                  },
                  obscuredRatio: 326 / height,
                  enable3d: true,
                  onShowRecordPanel: () {
                    final selectedProfile = _selectedProfile;
                    if (selectedProfile != null) {
                      _showRecordInvitePanelOrSignIn(
                          context, selectedProfile.profile.uid);
                    }
                  },
                  onLocationSafetyTapped: () =>
                      showSafetyAndPrivacyModal(context),
                  onMarkerRenderStatus: (status) {
                    setState(() => _markerRenderStatus = status);
                  },
                ),
              );
            },
          ),
          if (_mapLocation != null && !kReleaseMode)
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
                        setState(() => _showDebugUsers = !_showDebugUsers);
                        _performQuery();
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
                                _performQuery();
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
          Align(
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            _MapButton(
                              onPressed: _showConversationsOrSignIn,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  const Icon(
                                    Icons.email,
                                    color:
                                        Color.fromRGBO(0x0A, 0x7B, 0xFF, 1.0),
                                  ),
                                  Builder(
                                    builder: (context) {
                                      final count =
                                          ref.watch(unreadCountProvider);
                                      if (count == 0) {
                                        return const SizedBox.shrink();
                                      }
                                      return Align(
                                        alignment: Alignment.topRight,
                                        child: Container(
                                          width: 14.5,
                                          height: 14.5,
                                          margin: const EdgeInsets.only(
                                              top: 1, right: 1),
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Color.fromRGBO(
                                                0xFF, 0x00, 0x00, 1.0),
                                            boxShadow: [
                                              BoxShadow(
                                                offset: Offset(0, 1),
                                                blurRadius: 1.8,
                                                color: Color.fromRGBO(
                                                    0x00, 0x00, 0x00, 0.25),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),
                            Builder(
                              builder: (context) {
                                final myAccount =
                                    ref.watch(userProvider2.select(
                                  (p) {
                                    return p.map(
                                      guest: (_) => null,
                                      signedIn: (signedIn) => signedIn.account,
                                    );
                                  },
                                ));
                                return _MapButton(
                                  onPressed: () async {
                                    final visibility =
                                        myAccount?.location.visibility;
                                    _showLiveLocationModalOrSignIn(
                                      targetVisibility: visibility ==
                                              LocationVisibility.private
                                          ? LocationVisibility.public
                                          : LocationVisibility.private,
                                    );
                                  },
                                  child: myAccount?.location.visibility ==
                                          LocationVisibility.public
                                      ? const Icon(
                                          Icons.location_on,
                                          color: Color.fromRGBO(
                                              0x25, 0xB7, 0x00, 1.0),
                                        )
                                      : const Icon(
                                          Icons.location_off,
                                          color: Color.fromRGBO(
                                              0xFF, 0x00, 0x00, 1.0),
                                        ),
                                );
                              },
                            ),
                            const SizedBox(height: 18),
                            Consumer(
                              builder: (context, ref, child) {
                                final latLong =
                                    ref.watch(locationProvider).current;
                                return _MapButton(
                                  onPressed: () => _mapKey.currentState
                                      ?.recenterMap(latLong),
                                  child: const Icon(
                                    CupertinoIcons.location_fill,
                                    size: 20,
                                    color:
                                        Color.fromRGBO(0x8D, 0x8D, 0x8D, 1.0),
                                  ),
                                );
                              },
                            ),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutQuart,
                              width: 0,
                              height: _selectedProfile == null ? 0 : 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Builder(
                      builder: (context) {
                        final searching = (_fetchingProfiles ||
                            _markerRenderStatus ==
                                MarkerRenderStatus.rendering);
                        return Button(
                          onPressed: searching ? null : _performQuery,
                          useFadeWheNoPressedCallback: false,
                          child: Container(
                            width: 86,
                            height: 26,
                            padding: const EdgeInsets.only(top: 1),
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(5)),
                              color: Color.fromRGBO(0xFF, 0xFF, 0xFF, 0.95),
                              boxShadow: [
                                BoxShadow(
                                  blurRadius: 24,
                                  color: Color.fromRGBO(0x00, 0x00, 0x00, 0.15),
                                ),
                              ],
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: searching
                                  ? const IgnorePointer(
                                      child: Center(
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'Loading',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w400,
                                                color: Colors.black,
                                              ),
                                            ),
                                            SizedBox(width: 5),
                                            LoadingIndicator(
                                              color: Colors.black,
                                              size: 6.5,
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  : Center(
                                      child: Text(
                                        '${_profiles.length} result${_profiles.length == 1 ? '' : 's'}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                _Panel(
                  gender: _gender,
                  onGenderChanged: (gender) {
                    setState(() {
                      _gender = gender;
                      _selectedProfile = null;
                      _profiles.clear();
                    });
                    _mapKey.currentState?.resetMarkers();
                    _performQuery();
                  },
                  profiles: profiles,
                  selectedProfile: selectedProfile,
                  onProfileChanged: (profile) {
                    ref.read(analyticsProvider).trackViewMiniProfile();
                    setState(() => _selectedProfile = profile);
                  },
                  profileBuilderKey: _profileBuilderKey,
                  onShowSettings: _showSettingsOrSignIn,
                  onToggleFavorite: () {
                    if (selectedProfile != null) {
                      _toggleFavoriteOrShowSignIn(context, selectedProfile);
                    }
                  },
                  onBlockUser: (profile) {
                    setState(() => _profiles
                        .removeWhere(((p) => p.profile.uid == profile.uid)));
                  },
                  pageActive: _pageActive,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showRecordInvitePanelOrSignIn(BuildContext context, String uid) {
    _tempPauseAudio();
    final userState = ref.read(userProvider2);
    userState.map(
      guest: (_) => showSignInModal(context),
      signedIn: (_) async {
        final result = await showRecordPanel(
          context: context,
          title: const Text('Recording Message'),
          submitLabel: const Text('Finish & Send'),
        );

        if (result == null || !mounted) {
          return;
        }

        final notifier = ref.read(userProvider2.notifier);
        await withBlockingModal(
          context: context,
          label: 'Sending invite...',
          future: notifier.sendMessage(uid: uid, audio: result.audio),
        );

        if (mounted) {
          setState(() => _invitedUsers.add(uid));
        }
      },
    );
  }

  void _toggleFavoriteOrShowSignIn(
    BuildContext context,
    DiscoverProfile profile,
  ) async {
    _tempPauseAudio();
    final userState = ref.read(userProvider2);
    userState.map(
      guest: (_) => showSignInModal(context),
      signedIn: (_) => _toggleFavorite(profile),
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

  void _showSettingsOrSignIn() {
    _tempPauseAudio();
    final userState = ref.read(userProvider2);
    userState.map(
      guest: (_) => showSignInModal(context),
      signedIn: (_) => widget.onShowSettings(),
    );
  }

  void _showLiveLocationModalOrSignIn({
    required LocationVisibility targetVisibility,
  }) {
    _tempPauseAudio();
    final userState = ref.read(userProvider2);
    userState.map(
      guest: (_) => showSignInModal(context),
      signedIn: (_) async {
        final confirm = await (targetVisibility == LocationVisibility.public
            ? _showTurnOnLiveLocationModal(context)
            : _showTurnOffLiveLocationModal(context));
        if (mounted && confirm) {
          ref
              .read(userProvider2.notifier)
              .updateLocationVisibility(targetVisibility);
        }
      },
    );
  }

  void _showConversationsOrSignIn() {
    _tempPauseAudio();
    final userState = ref.read(userProvider2);
    userState.map(
      guest: (_) => showSignInModal(context),
      signedIn: (_) => widget.onShowConversations(),
    );
  }

  void _showLocationPermissionRationale() {
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
              onPressed: () async {
                if (await openAppSettings() && mounted) {
                  ref.read(locationProvider.notifier).retryInitLocation();
                }
                if (mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Enable in Settings'),
            ),
          ],
        );
      },
    );
  }
}

class _Panel extends ConsumerStatefulWidget {
  final Gender? gender;
  final ValueChanged<Gender?> onGenderChanged;
  final List<DiscoverProfile> profiles;
  final DiscoverProfile? selectedProfile;
  final ValueChanged<DiscoverProfile?> onProfileChanged;
  final GlobalKey<ProfileBuilderState> profileBuilderKey;
  final VoidCallback onShowSettings;
  final VoidCallback onToggleFavorite;
  final void Function(Profile profile) onBlockUser;
  final bool pageActive;

  const _Panel({
    super.key,
    required this.gender,
    required this.onGenderChanged,
    required this.profiles,
    required this.selectedProfile,
    required this.onProfileChanged,
    required this.profileBuilderKey,
    required this.onShowSettings,
    required this.onToggleFavorite,
    required this.onBlockUser,
    required this.pageActive,
  });

  @override
  ConsumerState<_Panel> createState() => _PanelState();
}

class _PanelState extends ConsumerState<_Panel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sheetAnimationController;

  @override
  void initState() {
    super.initState();
    _sheetAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  void dispose() {
    _sheetAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const borderSide = BorderSide(
      color: Color.fromRGBO(0xAB, 0xAB, 0xAB, 0.33),
    );
    return Container(
      margin: const EdgeInsets.only(top: 20),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: ColoredBox(
            color: const Color.fromRGBO(0xFF, 0xFF, 0xFF, 0.4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutQuart,
                  child: widget.selectedProfile == null
                      ? const SizedBox(
                          width: double.infinity,
                          height: 0,
                        )
                      : _buildMiniProfile(),
                ),
                Container(
                  height: 72 + MediaQuery.of(context).padding.bottom,
                  alignment: Alignment.center,
                  clipBehavior: Clip.hardEdge,
                  decoration: const BoxDecoration(
                    border: Border(
                      left: borderSide,
                      top: borderSide,
                      right: borderSide,
                    ),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Column(
                        children: [
                          const SizedBox(height: 7),
                          const Center(
                            child: DragHandle(
                              color: Color.fromRGBO(0xCE, 0xCE, 0xCE, 1.0),
                            ),
                          ),
                          Row(
                            children: [
                              const SizedBox(width: 8),
                              Button(
                                onPressed: widget.onShowSettings,
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  clipBehavior: Clip.hardEdge,
                                  margin: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: UserProfileCache(
                                      builder: (context, cachedPhoto) {
                                    return Consumer(
                                      builder: (context, ref, child) {
                                        final myProfile =
                                            ref.watch(userProvider2.select((p) {
                                          return p.map(
                                            guest: (_) => null,
                                            signedIn: (signedIn) =>
                                                signedIn.account.profile,
                                          );
                                        }));
                                        if (myProfile != null) {
                                          return Image(
                                            image:
                                                NetworkImage(myProfile.photo),
                                            fit: BoxFit.cover,
                                            gaplessPlayback: true,
                                          );
                                        } else if (cachedPhoto != null) {
                                          return Image.file(
                                            cachedPhoto,
                                            fit: BoxFit.cover,
                                            gaplessPlayback: true,
                                          );
                                        } else {
                                          return const Icon(
                                            Icons.person,
                                            size: 22,
                                            color: Color.fromRGBO(
                                                0x8D, 0x8D, 0x8D, 1.0),
                                          );
                                        }
                                      },
                                    );
                                  }),
                                ),
                              ),
                              Expanded(
                                child: Button(
                                  onPressed: () async {
                                    final prevGender = widget.gender;
                                    final gender =
                                        await _showPreferencesSheet();
                                    if (mounted && gender != prevGender) {
                                      widget.onGenderChanged(gender);
                                    }
                                  },
                                  child: Container(
                                    height: 32,
                                    clipBehavior: Clip.hardEdge,
                                    margin: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(11),
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        SizedBox(width: 18),
                                        Icon(
                                          Icons.search,
                                          size: 18,
                                          color: Color.fromRGBO(
                                              0x8D, 0x8D, 0x8D, 1.0),
                                        ),
                                        SizedBox(width: 6),
                                        Padding(
                                          padding: EdgeInsets.only(top: 2),
                                          child: Text(
                                            'Who are you searching for?',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w400,
                                              color: Color.fromRGBO(
                                                  0x8D, 0x8D, 0x8D, 1.0),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                          ),
                        ],
                      ),
                      Positioned(
                        left: 0,
                        top: 0,
                        right: 0,
                        bottom: MediaQuery.of(context).padding.bottom,
                        child: GestureDetector(
                          onVerticalDragUpdate: (details) {
                            if (details.delta.dy < 0) {
                              widget.onShowSettings();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniProfile() {
    // Must live above PageView.builder (otherwise duplicate global key)
    return ProfileBuilder(
      key: widget.profileBuilderKey,
      profile: widget.selectedProfile?.profile,
      play: widget.pageActive,
      builder: (context, playbackState, playbackInfoStream) {
        final selectedProfile = widget.selectedProfile;
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
          playbackState: playbackState,
          playbackInfoStream: playbackInfoStream,
          onPlay: () => widget.profileBuilderKey.currentState?.play(),
          onPause: () => widget.profileBuilderKey.currentState?.pause(),
          onToggleFavorite: widget.onToggleFavorite,
          onProfilePressed: () {
            ref.read(analyticsProvider).trackViewFullProfile();
            showProfileBottomSheet(
              context: context,
              transitionAnimationController: _sheetAnimationController,
              profile: selectedProfile.profile,
              existingProfileBuilderKey: widget.profileBuilderKey,
              existingPlaybackInfoStream: playbackInfoStream,
            );
          },
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
                    'Who are you searching for?',
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
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(10)),
        boxShadow: [
          BoxShadow(
            offset: Offset(0, 4),
            blurRadius: 14,
            color: Color.fromRGBO(0x00, 0x00, 0x00, 0.15),
          )
        ],
      ),
      child: Button(
        onPressed: onPressed,
        child: OverflowBox(
          minWidth: 56,
          minHeight: 56,
          maxWidth: 56,
          maxHeight: 56,
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }
}

Future<void> showSafetyAndPrivacyModal(BuildContext context) {
  return showCupertinoDialog(
    context: context,
    builder: (context) {
      return CupertinoAlertDialog(
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shield,
              size: 16,
            ),
            SizedBox(width: 8),
            Text('Safety & Privacy'),
          ],
        ),
        content: const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            children: [
              Text(
                'Safety and privacy is our top priority:',
                textAlign: TextAlign.left,
              ),
              SizedBox(height: 16),
              _DotPoint(
                message: Text(
                  'Your exact location will not be shown',
                  textAlign: TextAlign.left,
                ),
              ),
              _DotPoint(
                message: Text(
                  'Locations are approximate and within a half-mile radius',
                  textAlign: TextAlign.left,
                ),
              ),
              _DotPoint(
                message: Text(
                  'We do not share your exact location with others, only you can',
                  textAlign: TextAlign.left,
                ),
              ),
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: Navigator.of(context).pop,
            child: const Text('I understand'),
          ),
        ],
      );
    },
  );
}

Future<bool> _showTurnOffLiveLocationModal(BuildContext context) async {
  final result = await showCupertinoDialog<bool>(
    context: context,
    builder: (context) {
      return CupertinoAlertDialog(
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_on,
              size: 16,
            ),
            SizedBox(width: 8),
            Text('Live Location'),
          ],
        ),
        content: const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            children: [
              Text(
                'Turning off location will prevent the following:',
                textAlign: TextAlign.left,
              ),
              SizedBox(height: 16),
              _DotPoint(
                message: Text(
                  'You will not be visible on the map',
                  textAlign: TextAlign.left,
                ),
              ),
              _DotPoint(
                message: Text(
                  'You will not receive messages from new people',
                  textAlign: TextAlign.left,
                ),
              ),
              _DotPoint(
                message: Text(
                  'You and your friends can still message each other',
                  textAlign: TextAlign.left,
                ),
              ),
              _DotPoint(
                message: Text(
                  'You will not be able to message anyone on the map',
                  textAlign: TextAlign.left,
                ),
              ),
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: Navigator.of(context).pop,
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Turn off',
              style: TextStyle(
                color: Color.fromRGBO(0xFF, 0x00, 0x00, 1.0),
              ),
            ),
          ),
        ],
      );
    },
  );
  return result == true;
}

Future<bool> _showTurnOnLiveLocationModal(BuildContext context) async {
  final result = await showCupertinoDialog<bool>(
    context: context,
    builder: (context) {
      return CupertinoAlertDialog(
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_on,
              size: 16,
            ),
            SizedBox(width: 8),
            Text('Live Location'),
          ],
        ),
        content: const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            children: [
              Text(
                'Your safety is our top priority:',
                textAlign: TextAlign.left,
              ),
              SizedBox(height: 16),
              _DotPoint(
                message: Text(
                  'Your exact location will not be shown',
                  textAlign: TextAlign.left,
                ),
              ),
              _DotPoint(
                message: Text(
                  'Locations are approximate and within a half-mile radius',
                  textAlign: TextAlign.left,
                ),
              ),
              _DotPoint(
                message: Text(
                  'We do not share your location with others, only you can',
                  textAlign: TextAlign.left,
                ),
              ),
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: Navigator.of(context).pop,
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Turn on'),
          ),
        ],
      );
    },
  );
  return result == true;
}

Future<void> showSignupGuestModal(
  BuildContext context, {
  required VoidCallback onShowSignup,
}) {
  return showCupertinoDialog(
    context: context,
    builder: (context) {
      return Consumer(
        builder: (context, ref, child) {
          final dynamicConfigReady =
              ref.watch(dynamicConfigStateProvider) == DynamicConfigState.ready;
          final canContinueAsGuest =
              ref.watch(dynamicConfigProvider.select((p) => !p.loginRequired));
          return CupertinoAlertDialog(
            title: const Text('Sign up'),
            content: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                children: [
                  Text(
                    'Sign up or log in for free and gain these abilities:',
                    textAlign: TextAlign.left,
                  ),
                  SizedBox(height: 16),
                  _DotPoint(
                    message: Text(
                      'Let people know what you\'re up to by broadcasting a voice message',
                      textAlign: TextAlign.left,
                    ),
                  ),
                  _DotPoint(
                    message: Text(
                      'Send messages to anyone, anytime',
                      textAlign: TextAlign.left,
                    ),
                  ),
                  _DotPoint(
                    message: Text(
                      'Enhance your photos into cinematic photos',
                      textAlign: TextAlign.left,
                    ),
                  ),
                  _DotPoint(
                    message: Text(
                      'Receive voice messages from other people',
                      textAlign: TextAlign.left,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              if (!dynamicConfigReady)
                const CupertinoDialogAction(
                  child: LoadingIndicator(
                    size: 10,
                  ),
                )
              else ...[
                CupertinoDialogAction(
                  onPressed: onShowSignup,
                  child: const Text(
                    'Sign up or log in',
                    style:
                        TextStyle(color: Color.fromRGBO(0x2C, 0x80, 0xFF, 1.0)),
                  ),
                ),
                if (canContinueAsGuest)
                  CupertinoDialogAction(
                    onPressed: Navigator.of(context).pop,
                    child: const Text('Continue as guest'),
                  ),
              ]
            ],
          );
        },
      );
    },
  );
}

class _DotPoint extends StatelessWidget {
  final Text message;
  const _DotPoint({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•'),
          const SizedBox(width: 8),
          Expanded(
            child: message,
          ),
        ],
      ),
    );
  }
}
