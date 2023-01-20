import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/chat_api.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/home_screen.dart';
import 'package:openup/platform/just_audio_audio_player.dart';
import 'package:openup/widgets/app_lifecycle.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/gallery.dart';
import 'package:openup/widgets/icon_with_shadow.dart';

class UserProfileDisplay extends StatefulWidget {
  final Profile profile;
  final bool play;
  final bool invited;
  final VoidCallback onInvite;
  final VoidCallback onBeginRecording;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;
  final VoidCallback onBlocked;
  final VoidCallback onMenu;

  const UserProfileDisplay({
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
  State<UserProfileDisplay> createState() => _UserProfileDisplayState();
}

class _UserProfileDisplayState extends State<UserProfileDisplay> {
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
  void didUpdateWidget(covariant UserProfileDisplay oldWidget) {
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
