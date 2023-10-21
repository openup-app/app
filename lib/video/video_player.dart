import 'dart:async';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'video_player.freezed.dart';

abstract class VideoPlayer {
  bool get isPlaying;
  Stream<VideoPlayback> get playbackStream;
  Future<void> dispose();
  Future<void> play([Uri? uri]);
  Future<void> pause();
  Future<void> stop();
  Future<void> seek(double ratio);
}

enum VideoState {
  stopped(),
  loading(),
  playing(),
  paused();

  const VideoState();

  bool get isPlayingOrLoading =>
      this == VideoState.playing || this == VideoState.loading;
}

@freezed
class VideoPlayback with _$VideoPlayback {
  const factory VideoPlayback({
    @Default(VideoState.loading) VideoState state,
    @Default(Duration.zero) Duration position,
    @Default(Duration.zero) Duration duration,
  }) = _VideoPlaybackInfo;

  const VideoPlayback._();

  double get seekRatio => duration.inMicroseconds == 0
      ? 0
      : position.inMicroseconds / duration.inMicroseconds;
}
