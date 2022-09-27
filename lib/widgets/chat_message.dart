import 'dart:async';

import 'package:flutter/material.dart';
import 'package:openup/platform/just_audio_audio_player.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';

class AudioChatMessage extends StatefulWidget {
  final String audioUrl;
  final String photoUrl;
  final bool blurPhotos;
  final Widget date;
  final bool fromMe;
  final PlaybackInfo playbackInfo;
  final VoidCallback onPlay;
  final VoidCallback onPause;

  const AudioChatMessage({
    Key? key,
    required this.audioUrl,
    required this.photoUrl,
    required this.blurPhotos,
    required this.date,
    required this.fromMe,
    required this.playbackInfo,
    required this.onPlay,
    required this.onPause,
  }) : super(key: key);

  @override
  State<AudioChatMessage> createState() => _AudioChatMessageState();
}

class _AudioChatMessageState extends State<AudioChatMessage> {
  final _audio = JustAudioAudioPlayer();
  Duration? _tempDuration;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    // Duration isn't known until playback, we load the audio here too
    _audio.setUrl(widget.audioUrl);
    _subscription = _audio.playbackInfoStream.listen((playbackInfo) {
      if (playbackInfo.state == PlaybackState.idle) {
        setState(() {
          _tempDuration = playbackInfo.duration;
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _audio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          widget.fromMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Container(
          height: 69,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: widget.fromMe
                ? const Color.fromRGBO(0xFF, 0x00, 0x00, 0.5)
                : const Color.fromRGBO(0xC4, 0xC4, 0xC4, 0.3),
            borderRadius: const BorderRadius.all(
              Radius.circular(37),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!widget.fromMe)
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: _buildAvatar(widget.photoUrl),
                ),
              Row(
                textDirection:
                    widget.fromMe ? TextDirection.ltr : TextDirection.rtl,
                children: [
                  SizedBox(
                    width: 64,
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
                      width: 100,
                      child: Text(
                        'Audio failed',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  Builder(
                    builder: (context) {
                      if (widget.playbackInfo.position != Duration.zero) {
                        return Text(
                          formatDuration(widget.playbackInfo.position),
                          style:
                              Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w300,
                                  ),
                        );
                      } else {
                        final tempDuration = _tempDuration;
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
                  padding: const EdgeInsets.only(left: 12.0),
                  child: _buildAvatar(widget.photoUrl),
                ),
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
      decoration: const BoxDecoration(shape: BoxShape.circle),
      child: ProfileImage(
        photoUrl,
        blur: widget.blurPhotos,
        blurSigma: 5.0,
      ),
    );
  }
}
