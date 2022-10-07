import 'package:async/async.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:dartz/dartz.dart' show Either;
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Chip;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/chat_api.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/home_screen.dart';
import 'package:openup/platform/just_audio_audio_player.dart';
import 'package:openup/report_screen.dart';
import 'package:openup/util/location_service.dart';
import 'package:openup/widgets/app_lifecycle.dart';
import 'package:openup/widgets/back_button.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/gallery.dart';
import 'package:openup/widgets/icon_with_shadow.dart';
import 'package:openup/widgets/share_button.dart';
import 'package:permission_handler/permission_handler.dart';

class DiscoverPage extends ConsumerStatefulWidget {
  final ScrollToDiscoverTopNotifier scrollToTopNotifier;
  const DiscoverPage({
    Key? key,
    required this.scrollToTopNotifier,
  }) : super(key: key);

  @override
  ConsumerState<DiscoverPage> createState() => DiscoverPageState();
}

class DiscoverPageState extends ConsumerState<DiscoverPage> {
  bool _loading = false;

  CancelableOperation<Either<ApiError, DiscoverResults>>? _discoverOperation;
  final _profiles = <Profile>[];
  double _nextMinRadius = 0.0;
  int _nextPage = 0;

  int _currentProfileIndex = 0;
  Topic? _selectedTopic;
  bool _showingFavorites = false;
  final _invitedUsers = <String>{};
  PageController? _pageController;

  double _paddingRatio = 1.1;

  @override
  void initState() {
    super.initState();
    _fetchStatuses().then((_) {
      _maybeRequestNotification();
    });
    widget.scrollToTopNotifier.addListener(_onScrollToTop);
  }

  @override
  void dispose() {
    _pageController?.dispose();
    widget.scrollToTopNotifier.removeListener(_onScrollToTop);
    super.dispose();
  }

  Future<void> _maybeRequestNotification() async {
    final status = await Permission.notification.status;
    if (!(status.isGranted || status.isLimited)) {
      await Permission.notification.request();
    }
  }

  Future<void> _maybeRequestLocation() async {
    final status = await Permission.location.status;
    if (!(status.isGranted || status.isLimited)) {
      final result = await Permission.location.request();
      if ((result.isGranted || status.isLimited)) {
        await _updateLocation();
      } else {
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
      }
    }
  }

  Future<void> _updateLocation() async {
    setState(() => _loading = true);

    final profile = ref.read(userProvider).profile;
    final notifier = ref.read(userProvider.notifier);
    final locationService = LocationService();
    final location = await locationService.getLatLong();
    await location.when(
      value: (lat, long) {
        return updateLocation(
          context: context,
          profile: profile!,
          notifier: notifier,
          latitude: lat,
          longitude: long,
        );
      },
      denied: () {
        // Nothing to do
      },
      failure: () {
        // Nothing to do
      },
    );
  }

  void _initPageController({
    required double fullHeight,
    required double itemExtent,
    required double paddingRatio,
  }) {
    _pageController = PageController(
      viewportFraction: 1 / paddingRatio,
    );
    _pageController?.addListener(() {
      final oldIndex = _currentProfileIndex;
      final index = _pageController?.page?.round() ?? _currentProfileIndex;
      final forward = index > oldIndex;
      if (_currentProfileIndex != index) {
        setState(() => _currentProfileIndex = index);
        if (!_showingFavorites &&
            index > _profiles.length - 4 &&
            !_loading &&
            forward) {
          _fetchStatuses();
        }
      }
    });
  }

  Future<void> _fetchStatuses() async {
    if (!mounted) {
      return;
    }

    await _maybeRequestLocation();

    if (!mounted) {
      return;
    }

    setState(() => _loading = true);
    final myUid = ref.read(userProvider).uid;
    final api = GetIt.instance.get<Api>();
    _discoverOperation?.cancel();
    final discoverFuture = api.getDiscover(
      myUid,
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

  Future<void> _fetchFavorites() async {
    if (!mounted) {
      return;
    }

    setState(() => _loading = true);
    final myUid = ref.read(userProvider).uid;
    final api = GetIt.instance.get<Api>();
    final profiles = await api.getFavorites(myUid);

    if (!mounted) {
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
          _profiles
            ..clear()
            ..addAll(r.map((e) => e.profile));
        });
      },
    );
  }

  void _onScrollToTop() {
    _pageController?.animateTo(
      0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final obscuredHeight = MediaQuery.of(context).padding.bottom;
    return LayoutBuilder(
      builder: (context, constraints) {
        // Can build the PageController based on the height provided this frame
        if (_pageController == null) {
          Future.delayed(Duration.zero, () {
            if (mounted) {
              final fullHeight = constraints.maxHeight;
              final itemExtent = fullHeight - obscuredHeight * 2;
              setState(() => _paddingRatio = fullHeight / itemExtent);
              _initPageController(
                fullHeight: fullHeight,
                itemExtent: itemExtent,
                paddingRatio: _paddingRatio,
              );
            }
          });
        }

        return Stack(
          children: [
            if (_pageController != null)
              Positioned.fill(
                child: RefreshIndicator(
                  edgeOffset: MediaQuery.of(context).padding.top + 50,
                  onRefresh: () {
                    setState(() {
                      _discoverOperation?.cancel();
                      _profiles.clear();
                      _nextMinRadius = 0;
                      _nextPage = 0;
                    });
                    if (_showingFavorites) {
                      return _fetchFavorites();
                    } else {
                      return _fetchStatuses();
                    }
                  },
                  child: PageView.builder(
                    controller: _pageController,
                    scrollDirection: Axis.vertical,
                    itemCount: _profiles.length,
                    itemBuilder: (context, index) {
                      final profile = _profiles[index];
                      return _UserProfileDisplay(
                        profile: profile,
                        play: _currentProfileIndex == index,
                        invited: _invitedUsers.contains(profile.uid),
                        favourite: profile.favorite,
                        onInvite: () {
                          GetIt.instance.get<Mixpanel>().track(
                            "send_invite",
                            properties: {"type": "discover"},
                          );
                          setState(() => _invitedUsers.add(profile.uid));
                        },
                        onFavorite: (favorite) async {
                          if (favorite) {
                            GetIt.instance
                                .get<Mixpanel>()
                                .track("add_favorite");
                          } else {
                            GetIt.instance
                                .get<Mixpanel>()
                                .track("remove_favorite");
                          }
                          if (_showingFavorites && !favorite) {
                            setState(() => _profiles.removeAt(index));
                          }
                          final uid = ref.read(userProvider).uid;
                          final api = GetIt.instance.get<Api>();
                          final result = favorite
                              ? await api.addFavorite(uid, profile.uid)
                              : await api.removeFavorite(uid, profile.uid);
                          if (!mounted) {
                            return;
                          }
                          result.fold(
                            (l) {},
                            (r) {
                              setState(() {
                                _profiles[index] = _profiles[index]
                                    .copyWith(favorite: favorite);
                              });
                            },
                          );
                        },
                        onBlock: () => setState(() => _profiles
                            .removeWhere(((p) => p.uid == profile.uid))),
                        onReport: () {
                          context.goNamed(
                            'report',
                            extra: ReportScreenArguments(uid: profile.uid),
                          );
                        },
                        onBeginRecording: () {},
                      );
                    },
                  ),
                ),
              ),
            if (_profiles.isEmpty && !_loading)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
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
                        if (!_showingFavorites) {
                          if (mounted) {
                            setState(() => _loading = true);
                          }

                          final locationService = LocationService();
                          if (!await locationService.hasPermission()) {
                            final status =
                                await locationService.requestPermission();
                            if (status) {
                              await _updateLocation();
                            }
                          }
                        }

                        if (!mounted) {
                          return;
                        }

                        setState(() {
                          _nextMinRadius = 0;
                          _nextPage = 0;
                        });
                        if (_showingFavorites) {
                          _fetchFavorites();
                        } else {
                          _fetchStatuses();
                        }
                      },
                      child: const Text('Refresh'),
                    ),
                  ],
                ),
              )
            else if (_profiles.isEmpty)
              const Center(
                child: LoadingIndicator(),
              ),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: obscuredHeight,
              child: Stack(
                children: [
                  Container(
                    padding: EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [
                          0.9,
                          1.0,
                        ],
                        colors: [
                          Colors.black,
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            'Discover New Friends',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(fontSize: 20),
                          ),
                        ),
                        SizedBox(
                          height: 31,
                          child: ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            scrollDirection: Axis.horizontal,
                            children: [
                              Chip(
                                height: 31,
                                label: 'All',
                                selected: _selectedTopic == null &&
                                    !_showingFavorites,
                                onSelected: () {
                                  if (_selectedTopic != null ||
                                      _showingFavorites) {
                                    setState(() {
                                      _discoverOperation?.cancel();
                                      _profiles.clear();
                                      _selectedTopic = null;
                                      _nextMinRadius = 0;
                                      _nextPage = 0;
                                      _showingFavorites = false;
                                    });
                                    _fetchStatuses();
                                  }
                                },
                              ),
                              Chip(
                                label: 'Favorites',
                                selected: _showingFavorites,
                                onSelected: () async {
                                  if (!_showingFavorites) {
                                    setState(() {
                                      _discoverOperation?.cancel();
                                      _profiles.clear();
                                      _selectedTopic = null;
                                      _nextMinRadius = 0;
                                      _nextPage = 0;
                                      _showingFavorites = true;
                                    });
                                  }
                                  _fetchFavorites();
                                },
                              ),
                              for (final topic in Topic.values)
                                Chip(
                                  label: topicLabel(topic),
                                  selected: _selectedTopic == topic,
                                  onSelected: () {
                                    if (_selectedTopic != topic) {
                                      setState(() {
                                        _discoverOperation?.cancel();
                                        _profiles.clear();
                                        _selectedTopic = topic;
                                        _nextMinRadius = 0;
                                        _nextPage = 0;
                                        _showingFavorites = false;
                                      });
                                      _fetchStatuses();
                                    }
                                  },
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _UserProfileDisplay extends StatefulWidget {
  final Profile profile;
  final bool play;
  final bool invited;
  final bool favourite;
  final VoidCallback onInvite;
  final VoidCallback onBeginRecording;
  final void Function(bool favorite) onFavorite;
  final VoidCallback onBlock;
  final VoidCallback onReport;

  const _UserProfileDisplay({
    Key? key,
    required this.profile,
    required this.play,
    required this.invited,
    required this.favourite,
    required this.onInvite,
    required this.onBeginRecording,
    required this.onFavorite,
    required this.onBlock,
    required this.onReport,
  }) : super(key: key);

  @override
  State<_UserProfileDisplay> createState() => __UserProfileDisplayState();
}

class __UserProfileDisplayState extends State<_UserProfileDisplay> {
  bool _uploading = false;
  late bool _localFavorite;

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
    _localFavorite = widget.favourite;
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
    if (widget.favourite != oldWidget.favourite) {
      _localFavorite = widget.favourite;
    }

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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          children: [
            const SizedBox(height: 8),
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
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w300,
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
                      Row(
                        children: [
                          SvgPicture.asset(
                            'assets/images/earth.svg',
                            width: 16,
                            height: 16,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: AutoSizeText(
                              widget.profile.location,
                              overflow: TextOverflow.ellipsis,
                              minFontSize: 2,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(
                                    fontWeight: FontWeight.w300,
                                    fontSize: 16,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SizedBox(
                      height: 24,
                      child: ReportBlockPopupMenu(
                        uid: widget.profile.uid,
                        name: widget.profile.name,
                        onBlock: widget.onBlock,
                        onReport: widget.onReport,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0, bottom: 4),
                      child: Text(
                        topicLabel(widget.profile.topic),
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w300,
                            ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Button(
                onPressed: () {
                  if (_audioPaused) {
                    _player.play(loop: true);
                  } else {
                    _player.pause();
                  }
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  clipBehavior: Clip.hardEdge,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(24)),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Gallery(
                        slideshow: widget.play && !_audioPaused,
                        gallery: widget.profile.gallery,
                        withWideBlur: false,
                        blurPhotos: widget.profile.blurPhotos,
                      ),
                      Positioned(
                        right: 16,
                        top: 16,
                        child: Column(
                          children: [
                            Button(
                              onPressed: () {
                                setState(() {
                                  _localFavorite = !widget.favourite;
                                });
                                widget.onFavorite(!widget.favourite);
                              },
                              child: IconWithShadow(
                                _localFavorite
                                    ? Icons.bookmark
                                    : Icons.bookmark_outline,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                            const SizedBox(height: 18),
                            ShareButton(
                              profile: widget.profile,
                            ),
                          ],
                        ),
                      ),
                      if (!kReleaseMode)
                        Positioned(
                          left: 8,
                          right: 8,
                          bottom: 8,
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
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium!
                                        .copyWith(
                                      fontSize: 22,
                                      shadows: [
                                        const BoxShadow(
                                          color: Color.fromRGBO(
                                              0x00, 0x00, 0x00, 0.5),
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
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium!
                                        .copyWith(
                                      shadows: [
                                        const BoxShadow(
                                          color: Color.fromRGBO(
                                              0x00, 0x00, 0x00, 0.5),
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
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (widget.play)
              Align(
                alignment: Alignment.centerLeft,
                child: StreamBuilder<PlaybackInfo>(
                  stream: _player.playbackInfoStream,
                  initialData: const PlaybackInfo(),
                  builder: (context, snapshot) {
                    final value = snapshot.requireData;
                    final position = value.position.inMilliseconds;
                    final duration = value.duration.inMilliseconds;
                    final ratio = duration == 0 ? 0.0 : position / duration;
                    return FractionallySizedBox(
                      widthFactor: ratio < 0 ? 0 : ratio,
                      alignment: Alignment.centerLeft,
                      child: Container(
                        height: 13,
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(3)),
                          color: Color.fromRGBO(0xD9, 0xD9, 0xD9, 1.0),
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            Consumer(
              builder: (context, ref, _) {
                return RecordButton(
                  label: 'Invite to voice chat',
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
                            ScaffoldMessenger.of(context).showSnackBar(
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
            const SizedBox(height: 16),
          ],
        ),
      ),
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
              favourite: profile.favorite,
              onInvite: () {
                GetIt.instance.get<Mixpanel>().track(
                  "send_invite",
                  properties: {"type": "deep_link"},
                );
                setState(() => _invited = true);
              },
              onBeginRecording: () => _audioPlayer.stop(),
              onFavorite: (favorite) {
                if (favorite) {
                  GetIt.instance.get<Mixpanel>().track("add_favorite");
                } else {
                  GetIt.instance.get<Mixpanel>().track("remove_favorite");
                }
                setState(() => _profile = profile.copyWith(favorite: favorite));
              },
              onBlock: () => Navigator.of(context).pop(),
              onReport: () {
                context.goNamed(
                  'report',
                  extra: ReportScreenArguments(uid: profile.uid),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class ScrollToDiscoverTopNotifier extends ValueNotifier<void> {
  ScrollToDiscoverTopNotifier() : super(null);

  void scrollToTop() => notifyListeners();
}
