import 'dart:async';

import 'package:flutter/material.dart';
import 'package:openup/platform/just_audio_audio_player.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';

class AudioChatMessage extends StatefulWidget {
  final String audioUrl;
  final Duration? duration;
  final String photoUrl;
  final Widget date;
  final bool fromMe;
  final PlaybackInfo playbackInfo;
  final VoidCallback onPlay;
  final VoidCallback onPause;
  final void Function(Duration position)? onSeek;

  const AudioChatMessage({
    Key? key,
    required this.audioUrl,
    this.duration,
    required this.photoUrl,
    required this.date,
    required this.fromMe,
    required this.playbackInfo,
    required this.onPlay,
    required this.onPause,
    required this.onSeek,
  }) : super(key: key);

  @override
  State<AudioChatMessage> createState() => _AudioChatMessageState();
}

class _AudioChatMessageState extends State<AudioChatMessage> {
  final _tempAudioPlayer = JustAudioAudioPlayer();
  Duration? _duration;
  StreamSubscription? _subscription;
  bool _wasPlayingBeforeSeeking = false;

  @override
  void initState() {
    super.initState();
    // Duration isn't known until playback, we load the audio here too
    _duration = widget.duration;
    if (_duration == null) {
      _tempAudioPlayer.setUrl(widget.audioUrl);
      _subscription =
          _tempAudioPlayer.playbackInfoStream.listen((playbackInfo) {
        if (playbackInfo.state == PlaybackState.idle) {
          setState(() => _duration = playbackInfo.duration);
        }
      });
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _tempAudioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double minMillis = 0.0;
    final double maxMillis = _duration?.inMilliseconds.toDouble() ?? 1.0;
    final double value = widget.playbackInfo.position.inMilliseconds
        .toDouble()
        .clamp(minMillis, maxMillis);
    return Column(
      crossAxisAlignment:
          widget.fromMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Container(
          height: 69,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: widget.fromMe
                ? const LinearGradient(
                    colors: [
                      Color.fromRGBO(0xB0, 0x05, 0x05, 1.0),
                      Color.fromRGBO(0xFF, 0x15, 0x15, 1.0),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : const LinearGradient(
                    colors: [
                      Color.fromRGBO(0x64, 0x64, 0x64, 1.0),
                      Color.fromRGBO(0x3E, 0x3E, 0x3E, 1.0),
                    ],
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                  ),
            borderRadius: const BorderRadius.all(
              Radius.circular(20),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!widget.fromMe) _buildAvatar(widget.photoUrl),
              Row(
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: widget.playbackInfo.state == PlaybackState.loading
                        ? const Center(
                            child: LoadingIndicator(size: 24),
                          )
                        : Button(
                            onPressed: () {
                              switch (widget.playbackInfo.state) {
                                case PlaybackState.playing:
                                  widget.onPause();
                                  break;
                                case PlaybackState.paused:
                                case PlaybackState.idle:
                                  widget.onPlay();
                                  break;
                                default:
                                // Do nothing
                              }
                            },
                            child: Center(
                              child: Builder(
                                builder: (context) {
                                  switch (widget.playbackInfo.state) {
                                    case PlaybackState.playing:
                                      return const Icon(
                                        Icons.pause,
                                        size: 40,
                                      );
                                    case PlaybackState.paused:
                                    case PlaybackState.idle:
                                      return const Icon(
                                        Icons.play_arrow,
                                        size: 40,
                                      );
                                    default:
                                      return const Icon(
                                        Icons.error,
                                        size: 40,
                                      );
                                  }
                                },
                              ),
                            ),
                          ),
                  ),
                  if (widget.playbackInfo.state == PlaybackState.disabled)
                    SizedBox(
                      width: 120,
                      child: Text(
                        'Audio failed',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    )
                  else
                    SizedBox(
                      width: 120,
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          thumbColor: Colors.white,
                          activeTrackColor: Colors.white,
                          inactiveTrackColor: Colors.white,
                          trackHeight: 1,
                        ),
                        child: Slider(
                          min: minMillis,
                          max: maxMillis,
                          value: value,
                          onChangeStart: (_) {
                            setState(() => _wasPlayingBeforeSeeking =
                                widget.playbackInfo.state ==
                                    PlaybackState.playing);
                            widget.onPause();
                          },
                          onChangeEnd: (_) {
                            if (_wasPlayingBeforeSeeking) {
                              widget.onPlay();
                            }
                          },
                          onChanged: (value) => widget.onSeek
                              ?.call(Duration(milliseconds: value.toInt())),
                        ),
                      ),
                    ),
                  Builder(
                    builder: (context) {
                      if (widget.playbackInfo.position != Duration.zero) {
                        return Text(
                          formatDuration(widget.playbackInfo.position,
                              canBeZero: true),
                          style:
                              Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w300,
                                  ),
                        );
                      } else {
                        final tempDuration = _duration;
                        if (tempDuration == null) {
                          return const LoadingIndicator(size: 28);
                        } else {
                          return Text(
                            formatDuration(tempDuration),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w300,
                                ),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
              if (widget.fromMe)
                Padding(
                  padding: const EdgeInsets.only(left: 4.0),
                  child: _buildAvatar(widget.photoUrl),
                ),
              if (!widget.fromMe) const SizedBox(width: 4),
            ],
          ),
        ),
        SizedBox(
          height: 32,
          child: Row(
            mainAxisAlignment:
                widget.fromMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: widget.date,
              ),
              // if (widget.fromMe)
              //   Container(
              //     width: 20,
              //     height: 20,
              //     clipBehavior: Clip.hardEdge,
              //     decoration: const BoxDecoration(
              //       shape: BoxShape.circle,
              //     ),
              //     child: Image.network(
              //       widget.photoUrl,
              //       fit: BoxFit.cover,
              //     ),
              //   ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(String? photoUrl) {
    if (photoUrl == null) {
      return Container();
    }
    return Container(
      width: 52,
      height: 52,
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(0x00, 0x00, 0x00, 0.25),
            offset: Offset(0.0, 4.0),
            blurRadius: 4.0,
          ),
        ],
      ),
      child: ProfileImage(
        photoUrl,
      ),
    );
  }
}
