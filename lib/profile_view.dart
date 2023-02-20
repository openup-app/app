import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:openup/api/api.dart';
import 'package:openup/home_screen.dart';
import 'package:openup/main.dart';
import 'package:openup/platform/just_audio_audio_player.dart';
import 'package:openup/report_screen.dart';
import 'package:openup/widgets/app_lifecycle.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/gallery.dart';
import 'package:openup/widgets/icon_with_shadow.dart';
import 'package:openup/widgets/share_button.dart';

class ProfileView extends StatefulWidget {
  final Profile profile;
  final DateTime? endTime;
  final HomeTab interestedTab;
  final bool play;

  const ProfileView({
    Key? key,
    required this.profile,
    this.endTime,
    required this.interestedTab,
    this.play = true,
  }) : super(key: key);

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final _player = JustAudioAudioPlayer();
  bool _audioPaused = false;

  @override
  void initState() {
    super.initState();
    print('end time ${widget.endTime}');
    final audio = widget.profile.audio;
    if (audio != null) {
      _player.setUrl(audio);
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
  void didUpdateWidget(covariant ProfileView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.play != widget.play) {
      if (!widget.play) {
        _player.pause();
      }
    }
  }

  @override
  void dispose() {
    _player.dispose();
    currentTabNotifier.removeListener(_currentTabListener);
    super.dispose();
  }

  void _currentTabListener() {
    if (currentTabNotifier.value != widget.interestedTab) {
      _player.pause();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMe = widget.endTime == null;
    return AppLifecycle(
      onPaused: _player.pause,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                          if (widget.endTime != null)
                            Padding(
                              padding:
                                  const EdgeInsets.only(left: 6.0, bottom: 2),
                              child: OnlineIndicatorBuilder(
                                uid: widget.profile.uid,
                                builder: (context, online) {
                                  return online
                                      ? const OnlineIndicator()
                                      : const SizedBox.shrink();
                                },
                              ),
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
                    Container(
                      height: 24,
                      padding: const EdgeInsets.only(right: 8),
                      child: isMe
                          ? null
                          : CountdownTimer(
                              formatter: (remaining) =>
                                  formatCountdown(remaining),
                              endTime: widget.endTime!,
                              onDone: () {},
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w300,
                                  ),
                            ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
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
                  clipBehavior: Clip.hardEdge,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(24)),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Gallery(
                        gallery: widget.profile.gallery,
                        slideshow: !_audioPaused,
                      ),
                      if (!isMe)
                        Positioned(
                          right: 16,
                          top: 16,
                          child: ReportBlockPopupMenu(
                            uid: widget.profile.uid,
                            name: widget.profile.name,
                            onBlock: () {
                              const refreshChat = true;
                              Navigator.of(context).pop(refreshChat);
                            },
                            onReport: () {
                              rootNavigatorKey.currentState?.pushNamed(
                                'call-report',
                                arguments: ReportScreenArguments(
                                    uid: widget.profile.uid),
                              );
                            },
                          ),
                        ),
                      Positioned(
                        right: 16,
                        top: isMe ? 16 : 64,
                        child: ShareButton(
                          profile: widget.profile,
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
                            padding: EdgeInsets.only(bottom: 96.0),
                            child: IgnorePointer(
                              child: IconWithShadow(
                                Icons.play_arrow,
                                size: 80,
                              ),
                            ),
                          ),
                        ),
                      if (widget.profile.blurPhotos && !isMe)
                        Center(
                          child: IgnorePointer(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 166.0),
                              child: Column(
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
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Align(
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
            ),
          ],
        ),
      ),
    );
  }
}
