import 'dart:math';

import 'package:async/async.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:dartz/dartz.dart' show Either;
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Chip;
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/chat_api.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/home_screen.dart';
import 'package:openup/platform/just_audio_audio_player.dart';
import 'package:openup/util/location_service.dart';
import 'package:openup/widgets/app_lifecycle.dart';
import 'package:openup/widgets/back_button.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/carousel.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/gallery.dart';
import 'package:openup/widgets/icon_with_shadow.dart';
import 'package:permission_handler/permission_handler.dart';

class DiscoverPage extends ConsumerStatefulWidget {
  final ScrollToDiscoverTopNotifier scrollToTopNotifier;
  final GlobalKey<CarouselState> carouselKey;

  const DiscoverPage({
    Key? key,
    required this.scrollToTopNotifier,
    required this.carouselKey,
  }) : super(key: key);

  @override
  ConsumerState<DiscoverPage> createState() => DiscoverPageState();
}

class DiscoverPageState extends ConsumerState<DiscoverPage> {
  bool _loading = false;
  bool _hasLocation = false;

  CancelableOperation<Either<ApiError, DiscoverResults>>? _discoverOperation;
  final _profiles = <Profile>[];
  double _nextMinRadius = 0.0;
  int _nextPage = 0;

  int _currentProfileIndex = 0;
  Topic? _selectedTopic;
  final _invitedUsers = <String>{};

  final _swipeKey = GlobalKey<__SwipableState>();
  final _nextScaleAnimation = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    _fetchPageOfProfiles().then((_) {
      _maybeRequestNotification();
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
      profile.gallery.forEach((photo) {
        precacheImage(NetworkImage(photo), context);
        precacheImage(NetworkImage('${photo}_depth'), context);
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
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
      final profile = ref.read(userProvider).profile;
      final notifier = ref.read(userProvider.notifier);
      await updateLocation(
        context: context,
        profile: profile!,
        notifier: notifier,
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
      topic: _selectedTopic,
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
    if (_profiles.isEmpty) {
      if (_loading) {
        return const Center(
          child: LoadingIndicator(),
        );
      } else {
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
                        _selectedTopic == null
                            ? 'Couldn\'t find any profiles'
                            : 'Couldn\'t find any "${topicLabel(_selectedTopic!)}" profiles',
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
                    final status = await locationService.requestPermission();
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
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        if (_profiles.length > _currentProfileIndex)
          for (var i = _currentProfileIndex + 1; i >= _currentProfileIndex; i--)
            Builder(
              key: ValueKey(i),
              builder: (context) {
                final frontProfile = i == _currentProfileIndex;
                if (i >= _profiles.length) {
                  return const Center(
                    child: LoadingIndicator(),
                  );
                }
                final profile = _profiles[i];
                return ValueListenableBuilder<double>(
                  valueListenable: frontProfile
                      ? const AlwaysStoppedAnimation(1.0)
                      : _nextScaleAnimation,
                  builder: (context, value, child) {
                    return ScaleTransition(
                      scale: AlwaysStoppedAnimation(value),
                      child: child!,
                    );
                  },
                  child: IgnorePointer(
                    ignoring: !frontProfile,
                    child: _Swipable(
                      key: frontProfile ? _swipeKey : null,
                      onSwipe: (right) {
                        setState(() => _currentProfileIndex++);
                        _nextScaleAnimation.value = 0.0;
                        _precacheImageAndDepth(
                          _profiles,
                          from: _currentProfileIndex + 1,
                          count: 2,
                        );

                        if (_currentProfileIndex >= _profiles.length - 4 &&
                            !_loading) {
                          _fetchPageOfProfiles();
                        }
                      },
                      onUpdate: (value) {
                        _nextScaleAnimation.value = value.abs() * 0.3 + 0.7;
                      },
                      child: _UserProfileDisplay(
                        key: ValueKey(profile.uid),
                        profile: profile,
                        play: frontProfile,
                        invited: _invitedUsers.contains(profile.uid),
                        onInvite: () {
                          GetIt.instance.get<Mixpanel>().track(
                            "send_invite",
                            properties: {"type": "discover"},
                          );
                          setState(() => _invitedUsers.add(profile.uid));
                        },
                        onNext: () => _swipeKey.currentState?.animateLeft(),
                        onPrevious: !frontProfile
                            ? () {}
                            : (_currentProfileIndex <= 0
                                ? null
                                : () {
                                    setState(() => _currentProfileIndex--);
                                    SchedulerBinding.instance
                                        .addPostFrameCallback((_) {
                                      if (mounted) {
                                        _swipeKey.currentState?.reverse();
                                      }
                                    });
                                  }),
                        onBlocked: () => setState(() => _profiles
                            .removeWhere(((p) => p.uid == profile.uid))),
                        onBeginRecording: () {},
                        onMenu: () {
                          widget.carouselKey.currentState?.showMenu = true;
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
      ],
    );
  }
}

class _UserProfileDisplay extends StatefulWidget {
  final Profile profile;
  final bool play;
  final bool invited;
  final VoidCallback onInvite;
  final VoidCallback onBeginRecording;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;
  final VoidCallback onBlocked;
  final VoidCallback onMenu;

  const _UserProfileDisplay({
    Key? key,
    required this.profile,
    required this.play,
    required this.invited,
    required this.onInvite,
    required this.onBeginRecording,
    required this.onNext,
    required this.onPrevious,
    required this.onBlocked,
    required this.onMenu,
  }) : super(key: key);

  @override
  State<_UserProfileDisplay> createState() => __UserProfileDisplayState();
}

class __UserProfileDisplayState extends State<_UserProfileDisplay> {
  bool _uploading = false;

  final _player = JustAudioAudioPlayer();
  bool _audioPaused = false;

  @override
  void initState() {
    super.initState();
    final audio = widget.profile.audio;
    if (audio != null) {
      _player.setUrl(audio);
    }

    if (widget.play) {
      _player.play(loop: true);
    }
    _player.playbackInfoStream.listen((playbackInfo) {
      final isPaused = playbackInfo.state == PlaybackState.idle;
      if (!_audioPaused && isPaused) {
        setState(() => _audioPaused = true);
      } else if (_audioPaused && !isPaused) {
        setState(() => _audioPaused = false);
      }
    });

    currentTabNotifier.addListener(_currentTabListener);
  }

  @override
  void didUpdateWidget(covariant _UserProfileDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.play && !oldWidget.play) {
      _player.play(loop: true);
    } else if (!widget.play && oldWidget.play) {
      _player.stop();
    }
  }

  @override
  void dispose() {
    _player.stop();
    _player.dispose();
    currentTabNotifier.removeListener(_currentTabListener);
    super.dispose();
  }

  void _currentTabListener() {
    if (currentTabNotifier.value != HomeTab.discover) {
      _player.pause();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (ModalRoute.of(context)?.isCurrent == false) {
      _player.stop();
    }
    return AppLifecycle(
      onPaused: _player.pause,
      child: Stack(
        fit: StackFit.loose,
        children: [
          // Stops becoming see through when fade transitioning or when tapped
          const Positioned.fill(
            child: ColoredBox(
              color: Colors.black,
            ),
          ),
          Button(
            onPressed: () {
              if (_audioPaused) {
                _player.play(loop: true);
              } else {
                _player.pause();
              }
            },
            child: Gallery(
              slideshow: widget.play && !_audioPaused,
              gallery: widget.profile.gallery,
              withWideBlur: false,
              blurPhotos: widget.profile.blurPhotos,
            ),
          ),

          Positioned(
            right: 16,
            top: 16 + MediaQuery.of(context).padding.top,
            child: Column(
              children: [
                Button(
                  onPressed: widget.onNext,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Color.fromRGBO(0x5A, 0x5A, 0x5A, 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 13),
                Button(
                  onPressed: _showPreferencesSheet,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Color.fromRGBO(0x5A, 0x5A, 0x5A, 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Image.asset(
                        'assets/images/preferences_icon.png',
                        color: Colors.white,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.medium,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 13),
                Button(
                  onPressed: widget.onPrevious,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Color.fromRGBO(0x5A, 0x5A, 0x5A, 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.undo,
                        size: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 13),
                ReportBlockPopupMenu2(
                  uid: widget.profile.uid,
                  name: widget.profile.name,
                  onBlock: widget.onBlocked,
                  builder: (context) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        width: 26,
                        height: 26,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Color.fromRGBO(0x5A, 0x5A, 0x5A, 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          CupertinoIcons.ellipsis,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          if (_audioPaused)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 72.0),
                child: IgnorePointer(
                  child: IconWithShadow(
                    Icons.play_arrow,
                    size: 80,
                  ),
                ),
              ),
            ),
          if (widget.profile.blurPhotos)
            Center(
              child: IgnorePointer(
                child: Padding(
                  padding: const EdgeInsets.only(top: 72.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Hidden pictures',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontSize: 22,
                          shadows: [
                            const BoxShadow(
                              color: Color.fromRGBO(0x00, 0x00, 0x00, 0.5),
                              offset: Offset(0, 2),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'To view pics ask them to show you!',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          shadows: [
                            const BoxShadow(
                              color: Color.fromRGBO(0x00, 0x00, 0x00, 0.5),
                              offset: Offset(0, 2),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 48 + MediaQuery.of(context).padding.bottom,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Spacer(),
                    SizedBox(
                      width: 44,
                      height: 46,
                      child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Button(
                              onPressed: widget.onMenu,
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(
                                  color: Color.fromRGBO(0x5A, 0x5A, 0x5A, 0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: Image.asset(
                                  'assets/images/app_icon_new.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Button(
                              onPressed: () {},
                              child: Container(
                                width: 18,
                                height: 18,
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      Color.fromRGBO(0xC6, 0x0A, 0x0A, 1.0),
                                      Color.fromRGBO(0xFA, 0x4F, 0x4F, 1.0),
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '2',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium!
                                      .copyWith(fontSize: 14),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 11),
                if (widget.play)
                  Container(
                    height: 4,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(2)),
                      color: Color.fromRGBO(0xFF, 0xFF, 0xFF, 0.5),
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: StreamBuilder<PlaybackInfo>(
                        stream: _player.playbackInfoStream,
                        initialData: const PlaybackInfo(),
                        builder: (context, snapshot) {
                          final value = snapshot.requireData;
                          final position = value.position.inMilliseconds;
                          final duration = value.duration.inMilliseconds;
                          final ratio =
                              duration == 0 ? 0.0 : position / duration;
                          return FractionallySizedBox(
                            widthFactor: ratio < 0 ? 0 : ratio,
                            alignment: Alignment.centerLeft,
                            child: Container(
                              decoration: const BoxDecoration(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(2)),
                                color: Color.fromRGBO(0xFF, 0xFF, 0xFF, 1.0),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              AutoSizeText(
                                widget.profile.name,
                                maxFontSize: 26,
                                minFontSize: 18,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium!
                                    .copyWith(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(width: 8),
                              OnlineIndicatorBuilder(
                                uid: widget.profile.uid,
                                builder: (context, online) {
                                  return online
                                      ? const OnlineIndicator()
                                      : const SizedBox.shrink();
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          AutoSizeText(
                            widget.profile.location,
                            overflow: TextOverflow.ellipsis,
                            minFontSize: 2,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                  fontWeight: FontWeight.w300,
                                  fontSize: 15,
                                ),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Consumer(
                        builder: (context, ref, _) {
                          return _RecordButtonNew();
                          return RecordButton(
                            label: 'send invitation',
                            submitLabel: 'send message',
                            submitting: _uploading,
                            submitted: widget.invited,
                            onSubmit: (path) async {
                              setState(() => _uploading = true);
                              final uid = ref.read(userProvider).uid;
                              final api = GetIt.instance.get<Api>();
                              final result = await api.sendMessage(
                                uid,
                                widget.profile.uid,
                                ChatType.audio,
                                path,
                              );
                              if (mounted) {
                                setState(() => _uploading = false);
                                result.fold(
                                  (l) {
                                    if (l is ApiClientError &&
                                        l.error is ClientErrorForbidden) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Failed to send invite, try again later'),
                                        ),
                                      );
                                    } else {
                                      displayError(context, l);
                                    }
                                  },
                                  (r) => widget.onInvite(),
                                );
                              }
                            },
                            onBeginRecording: () {
                              _player.stop();
                              widget.onBeginRecording();
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!kReleaseMode)
            Positioned(
              left: 8,
              right: 8,
              bottom: 8 + MediaQuery.of(context).padding.bottom,
              child: Container(
                decoration: const BoxDecoration(
                  color: Color.fromRGBO(0x00, 0x00, 0x00, 0.4),
                  borderRadius: BorderRadius.all(
                    Radius.circular(24),
                  ),
                ),
                padding: const EdgeInsets.all(8),
                alignment: Alignment.center,
                child: AutoSizeText(
                  widget.profile.uid,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showPreferencesSheet() {
    showModalBottomSheet(
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
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    'I\'m interested in seeing...',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium!
                        .copyWith(fontSize: 16, fontWeight: FontWeight.w300),
                  ),
                ),
                const SizedBox(height: 16),
                RadioTile(
                  label: 'Men',
                  onTap: () {},
                  radioAtEnd: true,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium!
                      .copyWith(fontSize: 19, fontWeight: FontWeight.w300),
                ),
                RadioTile(
                  label: 'Women',
                  onTap: () {},
                  radioAtEnd: true,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium!
                      .copyWith(fontSize: 19, fontWeight: FontWeight.w300),
                ),
                RadioTile(
                  label: 'Non-Binary',
                  selected: true,
                  onTap: () {},
                  radioAtEnd: true,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium!
                      .copyWith(fontSize: 19, fontWeight: FontWeight.w300),
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
  }
}

class _Swipable extends StatefulWidget {
  final void Function(bool right) onSwipe;
  final ValueChanged<double>? onUpdate;
  final Widget child;

  const _Swipable({
    super.key,
    required this.onSwipe,
    required this.onUpdate,
    required this.child,
  });

  @override
  State<_Swipable> createState() => __SwipableState();
}

class __SwipableState extends State<_Swipable>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
    value: 0.5,
  );

  double _lastValue = 0.5;

  @override
  void initState() {
    _controller.addListener(() {
      final status = _controller.status;
      if (_lastValue != _controller.value) {
        if (status == AnimationStatus.completed && _controller.value == 1.0) {
          widget.onSwipe(true);
          _controller.value = 0.5;
        } else if (status == AnimationStatus.dismissed &&
            _controller.value == 0.0) {
          widget.onSwipe(false);
          _controller.value = 0.5;
        }

        widget.onUpdate?.call(_controller.value * 2 - 1);
        _lastValue = _controller.value;
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void animateRight() {
    _controller.forward();
  }

  void animateLeft() {
    _controller.reverse();
  }

  void reverse() {
    _controller.value = 0.0001;
    _controller.animateTo(0.5);
  }

  void reset() {
    _controller.value = 0.5;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onPanDown: (_) => _controller.stop(),
          onPanUpdate: (details) =>
              _controller.value += details.delta.dx / constraints.maxWidth / 4,
          onPanEnd: (details) {
            final flung = details.velocity.pixelsPerSecond.dx.abs() > 450;
            final releasedLeft = _controller.value <= 0.3;
            final releasedRight = _controller.value >= 0.6;
            if (flung) {
              if (details.velocity.pixelsPerSecond.dx.isNegative) {
                animateLeft();
              } else {
                animateRight();
              }
            } else if (releasedLeft) {
              animateLeft();
            } else if (releasedRight) {
              animateRight();
            } else {
              _controller.animateTo(
                0.5,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOut,
              );
            }
          },
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.translate(
                offset: Tween<Offset>(
                  begin: Offset(-constraints.maxWidth, 0.0),
                  end: Offset(constraints.maxWidth, 0.0),
                ).evaluate(_controller),
                child: Transform.rotate(
                  angle: (_controller.value * 2 - 1) * pi / 8,
                  alignment: const Alignment(0.0, 3.0),
                  child: child,
                ),
              );
            },
            child: widget.child,
          ),
        );
      },
    );
  }
}

class _RecordButtonNew extends StatelessWidget {
  const _RecordButtonNew({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showRecordSheet(context),
      child: Container(
        width: 156,
        height: 50,
        decoration: const BoxDecoration(
          color: Color.fromRGBO(0xFF, 0x00, 0x00, 0.5),
          borderRadius: BorderRadius.all(
            Radius.circular(72),
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: 14,
              color: Color.fromRGBO(0x00, 0x00, 0x00, 0.25),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mic_none),
            const SizedBox(width: 4),
            Text(
              'send invitation',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium!
                  .copyWith(fontSize: 16, fontWeight: FontWeight.w300),
            ),
          ],
        ),
      ),
    );
  }

  void _showRecordSheet(BuildContext context) {
    showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      builder: (context) {
        return const Surface(
          child: RecordPanel(),
        );
      },
    );
  }
}

class SharedProfilePage extends StatefulWidget {
  final String uid;
  const SharedProfilePage({
    super.key,
    required this.uid,
  });

  @override
  State<SharedProfilePage> createState() => _SharedProfilePageState();
}

class _SharedProfilePageState extends State<SharedProfilePage> {
  bool _loading = true;
  Profile? _profile;
  bool _invited = false;
  final _audioPlayer = JustAudioAudioPlayer();

  @override
  void initState() {
    super.initState();
    final api = GetIt.instance.get<Api>();
    api.getProfile(widget.uid).then((value) {
      if (!mounted) {
        return;
      }
      value.fold(
        (l) {
          displayError(context, l);
          setState(() => _loading = false);
        },
        (r) {
          setState(() {
            _profile = r;
            _loading = false;
          });
        },
      );
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: const BackIconButton(),
        title: const Text(
          'back to discover',
        ),
      ),
      backgroundColor: Colors.black,
      body: Builder(
        builder: (context) {
          if (_loading) {
            return const Center(
              child: LoadingIndicator(),
            );
          }

          final profile = _profile;
          if (profile == null) {
            return Center(
              child: Text(
                'Unable to get profile',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium!
                    .copyWith(fontSize: 22),
              ),
            );
          }
          return SafeArea(
            bottom: true,
            child: _UserProfileDisplay(
              profile: profile,
              play: true,
              invited: _invited,
              onInvite: () {
                GetIt.instance.get<Mixpanel>().track(
                  "send_invite",
                  properties: {"type": "deep_link"},
                );
                setState(() => _invited = true);
              },
              onBeginRecording: () => _audioPlayer.stop(),
              onNext: () {},
              onPrevious: () {},
              onBlocked: () => Navigator.of(context).pop(),
              onMenu: () {},
            ),
          );
        },
      ),
    );
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
