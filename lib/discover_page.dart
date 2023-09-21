import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Chip;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openup/analytics/analytics.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/discover/discover_provider.dart';
import 'package:openup/discover_provider.dart';
import 'package:openup/location/location_provider.dart';
import 'package:openup/shell_page.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/discover_dialogs.dart';
import 'package:openup/widgets/discover_map_mini_list.dart';
import 'package:openup/widgets/map_display.dart';
import 'package:openup/widgets/map_rendering.dart';
import 'package:openup/widgets/profile_display.dart';
import 'package:openup/widgets/record.dart';
import 'package:permission_handler/permission_handler.dart';

class DiscoverPage extends ConsumerStatefulWidget {
  const DiscoverPage({
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<DiscoverPage> createState() => DiscoverPageState();
}

class DiscoverPageState extends ConsumerState<DiscoverPage>
    with SingleTickerProviderStateMixin {
  bool _pageActive = false;

  final _invitedUsers = <String>{};

  final _profileBuilderKey = GlobalKey<ProfileBuilderState>();
  final _mapKey = GlobalKey<MapDisplayState>();

  final _rendererKey = GlobalKey<MapRenderingState>();
  MarkerRenderStatus _markerRenderStatus = MarkerRenderStatus.ready;

  bool _firstDidChangeDeps = false;

  @override
  void initState() {
    super.initState();
    ref.listenManual<LocationMessage?>(locationMessageProvider,
        (previous, next) {
      if (next == null) {
        return;
      }
      switch (next) {
        case LocationMessage.permissionRationale:
          showLocationPermissionRationale(context);
          break;
      }
    });

    ref.listenManual<DiscoverAction?>(
      discoverActionProvider,
      (previous, next) {
        if (next == null) {
          return;
        }

        next.map(
          viewProfile: (viewProfile) {
            final profile = viewProfile.profile;
            _mapKey.currentState?.recenterMap(profile.location.latLong);
            ref
                .read(discoverProvider.notifier)
                .uidToSelectWhenAvailable(profile.profile.uid);
          },
        );
      },
    );

    ref.listenManual<String?>(discoverAlertProvider, (previous, next) {
      if (next == null) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(next),
        ),
      );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_firstDidChangeDeps) {
      _firstDidChangeDeps = false;
      // Location permission also requested from NotificationManager
      _maybeRequestNotification();
    }

    final readyState = ref.read(_discoverReadyProvider);
    if (readyState != null) {
      _precacheImageAndDepth(readyState.profiles, from: 1, count: 2);
    }
  }

  AlwaysAliveProviderListenable<DiscoverReadyState?>
      get _discoverReadyProvider {
    return discoverProvider.select((s) {
      return s.map(
        init: (_) => null,
        ready: (ready) => ready,
      );
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
    final routeCurrent = ModalRoute.of(context)?.isCurrent == true;
    if (!routeCurrent) {
      return;
    }

    final isSignedIn = ref.read(userProvider2.select((p) {
      return p.map(
        guest: (_) => false,
        signedIn: (_) => true,
      );
    }));
    if (isSignedIn) {
      final status = await Permission.notification.status;
      if (!(status.isGranted || status.isLimited)) {
        await Permission.notification.request();
      }
    }
  }

  void _tempPauseAudio() {
    _profileBuilderKey.currentState?.pause();
  }

  void _onProfileChanged(DiscoverProfile? selectedProfile) {
    ref.read(discoverProvider.notifier).selectProfile(selectedProfile);
    _profileBuilderKey.currentState?.play();
  }

  @override
  Widget build(BuildContext context) {
    final readyState = ref.watch(_discoverReadyProvider);
    final profiles = readyState?.profiles ?? [];
    final selectedProfile = readyState?.selectedProfile;
    return ActivePage(
      onActivate: () {
        setState(() => _pageActive = true);
        ref.read(discoverProvider.notifier).performQuery();
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
                child: MapRendering(
                  items: profiles.map((p) => ProfileMapItem(p)).toList(),
                  selectedItem: selectedProfile == null
                      ? null
                      : ProfileMapItem(selectedProfile),
                  frameCount: 12,
                  onMarkerRenderStatus: (status) =>
                      setState(() => _markerRenderStatus = status),
                  builder: (context, renderedItems, renderedSelectedItem) {
                    return MapDisplay(
                      key: _mapKey,
                      items: renderedItems,
                      selectedItem: renderedSelectedItem,
                      onSelectionChanged: (i) =>
                          _onProfileChanged((i as ProfileMapItem?)?.profile),
                      itemAnimationSpeedMultiplier: 1.0,
                      initialLocation: Location(
                        latLong: ref.read(locationProvider).initialLatLong,
                        radius: 1800,
                      ),
                      onLocationChanged:
                          ref.read(discoverProvider.notifier).locationChanged,
                      obscuredRatio: 326 / height,
                      onShowRecordPanel: () {
                        if (selectedProfile != null) {
                          _showRecordInvitePanelOrSignIn(
                              context, selectedProfile.profile.uid);
                        }
                      },
                    );
                  },
                ),
              );
            },
          ),
          if (!kReleaseMode)
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
                        if (readyState != null) {
                          ref.read(discoverProvider.notifier).showDebugUsers =
                              !readyState.showDebugUsers;
                        }
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
                              value: readyState?.showDebugUsers ?? false,
                              onChanged: (show) {
                                ref
                                    .read(discoverProvider.notifier)
                                    .showDebugUsers = show;
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
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).padding.bottom,
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
                                        Color.fromRGBO(0x22, 0x22, 0x22, 1.0),
                                  ),
                                );
                              },
                            ),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutQuart,
                              width: 0,
                              height: selectedProfile == null ? 0 : 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Builder(
                      builder: (context) {
                        final searching = (readyState?.loading == true ||
                            _markerRenderStatus ==
                                MarkerRenderStatus.rendering);
                        return Button(
                          onPressed: searching
                              ? null
                              : ref
                                  .read(discoverProvider.notifier)
                                  .performQuery,
                          useFadeWheNoPressedCallback: false,
                          child: Container(
                            width: 86,
                            height: 26,
                            padding: const EdgeInsets.only(top: 1),
                            margin: const EdgeInsets.only(bottom: 56),
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
                                        '${profiles.length} result${profiles.length == 1 ? '' : 's'}',
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
                  gender: readyState?.gender,
                  onGenderChanged: (gender) {
                    ref.read(discoverProvider.notifier).genderChanged(gender);
                    _rendererKey.currentState?.resetMarkers();
                  },
                  profiles: profiles,
                  selectedProfile: selectedProfile,
                  onProfileChanged: (profile) {
                    ref.read(analyticsProvider).trackViewMiniProfile();
                    ref.read(discoverProvider.notifier).selectProfile(profile);
                  },
                  profileBuilderKey: _profileBuilderKey,
                  onToggleFavorite: () {
                    if (selectedProfile != null) {
                      _toggleFavoriteOrShowSignIn(context, selectedProfile);
                    }
                  },
                  onBlockUser: (profile) {
                    ref
                        .read(discoverProvider.notifier)
                        .userBlocked(profile.uid);
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
          submitLabel: const Text('Tap to send'),
        );

        if (result == null) {
          return;
        }
        if (!mounted) {
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
    ref
        .read(discoverProvider.notifier)
        .setFavorite(profile.profile.uid, !profile.favorite);
  }
}

class _Panel extends ConsumerStatefulWidget {
  final Gender? gender;
  final ValueChanged<Gender?> onGenderChanged;
  final List<DiscoverProfile> profiles;
  final DiscoverProfile? selectedProfile;
  final ValueChanged<DiscoverProfile?> onProfileChanged;
  final GlobalKey<ProfileBuilderState> profileBuilderKey;
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
        return DiscoverMapMiniList(
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
