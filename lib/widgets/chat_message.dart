import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:openup/platform/just_audio_audio_player.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/theming.dart';
import 'package:video_player/video_player.dart';

class AudioChatMessage extends StatefulWidget {
  final String audioUrl;
  final String? photoUrl;
  final Widget date;
  final bool fromMe;

  const AudioChatMessage({
    Key? key,
    required this.audioUrl,
    this.photoUrl,
    required this.date,
    required this.fromMe,
  }) : super(key: key);

  @override
  _AudioChatMessageState createState() => _AudioChatMessageState();
}

class _AudioChatMessageState extends State<AudioChatMessage> {
  final _audio = JustAudioAudioPlayer();
  late final StreamSubscription _subscription;

  PlaybackInfo _playbackInfo = const PlaybackInfo(
    position: Duration.zero,
    duration: Duration.zero,
    state: PlaybackState.loading,
  );

  @override
  void initState() {
    super.initState();
    _audio.setUrl(widget.audioUrl);
    _subscription = _audio.playbackInfoStream.listen(_onPlaybackInfo);
  }

  @override
  void dispose() {
    super.dispose();
    _audio.dispose();
    _subscription.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: widget.fromMe
            ? const Color.fromRGBO(0x5E, 0x5C, 0x5C, 0.3)
            : const Color.fromRGBO(0xC4, 0xC4, 0xC4, 0.30),
        border: Border.all(
          color: const Color.fromRGBO(0x60, 0x5E, 0x5E, 1.0),
          width: 2,
        ),
        borderRadius: const BorderRadius.all(
          Radius.circular(36),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!widget.fromMe) _buildAvatar(widget.photoUrl),
          SizedBox(
            width: 48,
            height: 48,
            child: _playbackInfo.state == PlaybackState.loading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : Button(
                    onPressed: () {
                      switch (_playbackInfo.state) {
                        case PlaybackState.playing:
                          _audio.pause();
                          break;
                        case PlaybackState.paused:
                        case PlaybackState.idle:
                          _audio.play();
                          break;
                        default:
                        // Do nothing
                      }
                    },
                    child: Center(
                      child: Builder(
                        builder: (context) {
                          switch (_playbackInfo.state) {
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
          Stack(
            alignment: Alignment.center,
            children: [
              Row(
                children: [
                  if (_playbackInfo.state != PlaybackState.disabled)
                    SizedBox(
                      width: 100,
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          thumbShape: AudioSliderThumbShape(),
                          trackShape: AudioSliderTrackShape(),
                          overlayColor: Colors.transparent,
                        ),
                        child: Slider(
                          min: Duration.zero.inMilliseconds.toDouble(),
                          max: _playbackInfo.duration.inMilliseconds.toDouble(),
                          value:
                              _playbackInfo.position.inMilliseconds.toDouble(),
                          onChanged: (value) => _audio
                              .seek(Duration(milliseconds: value.toInt())),
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      width: 100,
                      child: Text(
                        'Audio failed',
                        style: Theming.of(context).text.body,
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      _formatDuration(
                          _playbackInfo.state == PlaybackState.playing
                              ? _playbackInfo.position
                              : _playbackInfo.duration),
                      style: Theming.of(context)
                          .text
                          .body
                          .copyWith(fontWeight: FontWeight.normal),
                    ),
                  ),
                ],
              ),
              Positioned(
                right: widget.fromMe ? 0 : 8,
                child: Padding(
                  padding: const EdgeInsets.only(top: 40.0, right: 8.0),
                  child: widget.date,
                ),
              ),
            ],
          ),
          if (widget.fromMe) _buildAvatar(widget.photoUrl),
        ],
      ),
    );
  }

  Widget _buildAvatar(String? photoUrl) {
    if (photoUrl == null) {
      return Container();
    }
    return CircleAvatar(
      radius: 26,
      backgroundImage: NetworkImage(
        photoUrl,
      ),
    );
  }

  String _formatDuration(Duration duration) =>
      '${min(duration.inMinutes, 99).toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';

  void _onPlaybackInfo(PlaybackInfo info) =>
      setState(() => _playbackInfo = info);
}

class AudioSliderThumbShape extends RoundSliderThumbShape {
  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    final left = parentBox.size.centerLeft(Offset.zero).dx;
    final width = parentBox.size.width;
    const horizontalPadding = 8;
    canvas.drawCircle(
      Offset(left + horizontalPadding + (width - horizontalPadding * 2) * value,
          center.dy),
      8,
      Paint()..color = const Color.fromRGBO(0xFF, 0x87, 0x87, 1.0),
    );
  }
}

class AudioSliderTrackShape extends SliderTrackShape {
  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool? isEnabled,
    bool? isDiscrete,
  }) {
    return offset & parentBox.size;
  }

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required Offset thumbCenter,
    bool? isEnabled,
    bool? isDiscrete,
    required TextDirection textDirection,
  }) {
    final canvas = context.canvas;
    const height = 2.0;
    const horizontalPadding = 8.0;
    final rect = parentBox.size
            .centerLeft(const Offset(horizontalPadding, -height / 2)) &
        Size(parentBox.size.width - horizontalPadding * 2, height);
    canvas.drawRect(
      rect,
      Paint()..color = const Color.fromRGBO(0xFF, 0x87, 0x87, 1.0),
    );
  }
}

class VideoChatMessage extends StatefulWidget {
  final String videoUrl;
  final Widget date;
  final bool fromMe;

  const VideoChatMessage({
    Key? key,
    required this.videoUrl,
    required this.date,
    required this.fromMe,
  }) : super(key: key);

  @override
  _VideoChatMessageState createState() => _VideoChatMessageState();
}

class _VideoChatMessageState extends State<VideoChatMessage> {
  late final VideoPlayerController _controller;
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl);
    _controller.initialize().whenComplete(() {
      if (mounted) {
        setState(() {});
      }
    });
    _controller.addListener(() async {
      if (_controller.value.isPlaying != _playing) {
        if (mounted) {
          setState(() => _playing = _controller.value.isPlaying);
        }
        if (_controller.value.position == _controller.value.duration) {
          await _controller.seekTo(Duration.zero);
          if (mounted) {
            setState(() {});
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.all(
        Radius.circular(36),
      ),
      child: Button(
        onPressed: () async {
          final playing = _controller.value.isPlaying;
          if (!playing) {
            await _controller.play();
          } else {
            await _controller.pause();
          }
          if (mounted) {
            setState(() => _playing = _controller.value.isPlaying);
          }
        },
        child: SizedBox(
          width: 200,
          height: 250,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.all(
                  Radius.circular(34),
                ),
                child: Builder(
                  builder: (context) {
                    if (_controller.value.isInitialized) {
                      return FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: _controller.value.size.width,
                          height: _controller.value.size.height,
                          child: VideoPlayer(_controller),
                        ),
                      );
                    } else {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                  },
                ),
              ),
              if (!_playing)
                BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 10,
                    sigmaY: 10,
                  ),
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      color: Color.fromRGBO(0xFF, 0xFF, 0xFF, 0.3),
                    ),
                  ),
                ),
              Positioned(
                right: 24,
                bottom: 12,
                child: widget.date,
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color.fromRGBO(0x9E, 0x9E, 0x9E, 1.0),
                    width: 2,
                  ),
                  borderRadius: const BorderRadius.all(
                    Radius.circular(36),
                  ),
                ),
                child: const SizedBox.expand(),
              ),
              if (_controller.value.isInitialized && !_playing)
                const Center(
                  child: Icon(
                    Icons.play_arrow,
                    size: 48,
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }
}
