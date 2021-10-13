import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:just_audio/just_audio.dart';

part 'just_audio_audio_player.freezed.dart';

/// Audio playback implemented by package:just_audio.
class JustAudioAudioPlayer {
  final _playbackInfoController = StreamController<PlaybackInfo>.broadcast();
  final _player = AudioPlayer();

  PlaybackInfo _playbackInfo = const PlaybackInfo();

  JustAudioAudioPlayer() {
    _player.playerStateStream.listen((state) async {
      switch (state.processingState) {
        case ProcessingState.buffering:
        case ProcessingState.loading:
        case ProcessingState.idle:
          _playbackInfo.copyWith(state: PlaybackState.loading);
          break;
        case ProcessingState.ready:
        case ProcessingState.completed:
          _playbackInfo = _playbackInfo.copyWith(
              state: state.playing &&
                      state.processingState == ProcessingState.ready
                  ? PlaybackState.playing
                  : PlaybackState.idle);
          if (_player.processingState == ProcessingState.completed) {
            _player.pause();
            _player.seek(Duration.zero);
          }
          break;
      }

      _playbackInfoController.add(_playbackInfo);
    });

    _player.positionStream.listen((position) {
      _playbackInfo = _playbackInfo.copyWith(position: position);
      _playbackInfoController.add(_playbackInfo);
    });

    _player.durationStream.listen((duration) {
      if (duration != null) {
        _playbackInfo = _playbackInfo.copyWith(duration: duration);
        _playbackInfoController.add(_playbackInfo);
      }
    });
  }

  void dispose() {
    _playbackInfoController.close();
    _player.dispose();
  }

  Stream<PlaybackInfo> get playbackInfoStream => _playbackInfoController.stream;

  Stream<Duration> get recordingDurationStream => const Stream.empty();

  Future<void> play({String? uri}) async {
    if (uri != null) {
      await _player.setUrl(uri);
    }
    return _player.play();
  }

  Future<void> pause() {
    return _player.pause();
  }

  Future<void> stop() {
    return _player.stop();
  }
}

@freezed
class PlaybackInfo with _$PlaybackInfo {
  const factory PlaybackInfo({
    @Default(Duration.zero) Duration position,
    @Default(Duration.zero) Duration duration,
    @Default(PlaybackState.idle) PlaybackState state,
  }) = _PlaybackInfo;
}

enum PlaybackState { loading, playing, paused, idle }
