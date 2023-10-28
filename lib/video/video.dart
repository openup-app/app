import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:openup/video/flutter_video_player.dart';
import 'package:openup/video/video_player.dart';
import 'package:video_player/video_player.dart' as vp;

class VideoBuilder extends StatefulWidget {
  final Uri uri;
  final bool autoPlay;
  final void Function(VideoController controller)? onController;
  final Widget Function(
    BuildContext context,
    Widget video,
    VideoController controller,
  ) builder;

  const VideoBuilder({
    super.key,
    required this.uri,
    this.autoPlay = false,
    this.onController,
    required this.builder,
  });

  @override
  State<VideoBuilder> createState() => _VideoBuilderState();
}

class _VideoBuilderState extends State<VideoBuilder> {
  late vp.VideoPlayerController _vpController;
  late final VideoController _controller;

  @override
  void initState() {
    super.initState();
    _initPlayer();
    _controller = VideoController._(FlutterVideoPlayer(_vpController));
    widget.onController?.call(_controller);
  }

  @override
  void didUpdateWidget(covariant VideoBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uri != widget.uri) {
      _vpController.dispose();
      _initPlayer();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _vpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(
      context,
      vp.VideoPlayer(_vpController),
      _controller,
    );
  }

  void _initPlayer() async {
    _vpController = vp.VideoPlayerController.networkUrl(
      widget.uri,
      videoPlayerOptions: vp.VideoPlayerOptions(
        // Enabled to play video with separate audio source on Android
        mixWithOthers: true,
      ),
    );
    _vpController.setLooping(true);
    _vpController.setVolume(0);
    if (widget.autoPlay) {
      _vpController.play();
    }
    await _vpController.initialize();
    if (mounted) {
      // Show first frame
      setState(() {});
    }
  }
}

class VideoController {
  final VideoPlayer _player;
  late final StreamSubscription _playbackSubscription;

  final PlaybackNotifier _playbackNotifier =
      PlaybackNotifier(const VideoPlayback());

  VideoController._(this._player) {
    _playbackSubscription = _player.playbackStream.listen(_onPlaybackChanged);
  }

  void dispose() {
    _playbackSubscription.cancel();
  }

  Stream<VideoPlayback> get playbackStream => _player.playbackStream;

  Stream<VideoState> get videoStateStream =>
      _player.playbackStream.map((e) => e.state);

  PlaybackNotifier get playback => _playbackNotifier;

  void play() => _player.play();

  void pause() => _player.pause();

  void stop() => _player.stop();

  void togglePlayPause() =>
      _player.isPlaying ? _player.pause() : _player.play();

  void seek(double ratio) => _player.seek(ratio);

  void _onPlaybackChanged(VideoPlayback playback) =>
      _playbackNotifier.value = playback;
}

class PlaybackNotifier extends ValueNotifier<VideoPlayback> {
  PlaybackNotifier(super.value);
}
