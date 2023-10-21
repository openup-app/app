import 'dart:async';

import 'package:openup/video/video_player.dart';
import 'package:video_player/video_player.dart' as vp;

class FlutterVideoPlayer implements VideoPlayer {
  final _playbackController = StreamController<VideoPlayback>.broadcast();

  final vp.VideoPlayerController _vpController;

  FlutterVideoPlayer(this._vpController) {
    _vpController.addListener(_onUpdate);
  }

  void _onUpdate() {
    final VideoState state;
    final value = _vpController.value;
    if (!value.isInitialized) {
      state = VideoState.loading;
    } else if (value.isPlaying) {
      state = VideoState.playing;
    } else if (!value.isPlaying) {
      state = VideoState.paused;
    } else if (_vpController.value.isCompleted) {
      state = VideoState.stopped;
    } else {
      state = VideoState.loading;
    }
    _playbackController.add(VideoPlayback(
      state: state,
      position: value.position,
      duration: value.duration,
    ));
  }

  @override
  bool get isPlaying => _vpController.value.isPlaying;

  @override
  Stream<VideoPlayback> get playbackStream => _playbackController.stream;

  @override
  Future<void> dispose() => _playbackController.close();

  @override
  Future<void> play([Uri? uri]) => _vpController.play();

  @override
  Future<void> pause() => _vpController.pause();

  @override
  Future<void> stop() =>
      _vpController.pause()..then((_) => _vpController.seekTo(Duration.zero));

  @override
  Future<void> seek(double ratio) =>
      _vpController.seekTo(_vpController.value.duration * ratio);
}
