import 'dart:async';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'audio_player.freezed.dart';

abstract class AudioPlayer {
  bool get isPlaying;
  Stream<Playback> get playbackStream;
  Future<void> dispose();
  Future<void> precache(Uri uri);
  Future<void> play([Uri? uri]);
  Future<void> pause();
  Future<void> setLoop(bool looping);
  Future<void> stop();
  Future<void> seek(double ratio);
}

enum AudioState {
  none(),
  stopped(),
  loading(),
  playing(),
  paused();

  const AudioState();

  bool get isPlayingOrLoading =>
      this == AudioState.playing || this == AudioState.loading;
}

@freezed
class Playback with _$Playback {
  const factory Playback({
    @Default(AudioState.none) AudioState state,
    @Default(Duration.zero) Duration position,
    @Default(Duration.zero) Duration duration,
  }) = _PlaybackInfo;

  const Playback._();

  double get seekRatio => duration.inMicroseconds == 0
      ? 0
      : position.inMicroseconds / duration.inMicroseconds;
}
