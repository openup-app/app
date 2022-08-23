import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:just_audio/just_audio.dart';

part 'just_audio_audio_player.freezed.dart';

/// Audio playback implemented by package:just_audio.
class JustAudioAudioPlayer {
  final _playbackInfoController = StreamController<PlaybackInfo>.broadcast();
  final _player = AudioPlayer(
    audioLoadConfiguration: AudioLoadConfiguration(
      androidLoadControl: AndroidLoadControl(
        backBufferDuration: const Duration(seconds: 10),
      ),
      darwinLoadControl: DarwinLoadControl(
        preferredForwardBufferDuration: const Duration(seconds: 10),
      ),
    ),
  );

  late final StreamSubscription _stateSubscription;
  late final StreamSubscription _positionSubscription;
  late final StreamSubscription _durationSubscription;

  PlaybackInfo _playbackInfo = const PlaybackInfo();

  JustAudioAudioPlayer() {
    _stateSubscription = _player.playerStateStream.listen((state) async {
      switch (state.processingState) {
        case ProcessingState.buffering:
        case ProcessingState.loading:
        case ProcessingState.idle:
          _playbackInfo = _playbackInfo.copyWith(
              state: state.processingState == ProcessingState.idle
                  ? PlaybackState.disabled
                  : PlaybackState.loading);
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

    _positionSubscription = _player.positionStream.listen((position) {
      _playbackInfo = _playbackInfo.copyWith(position: position);
      _playbackInfoController.add(_playbackInfo);
    });

    _durationSubscription = _player.durationStream.listen((duration) {
      if (duration != null) {
        _playbackInfo = _playbackInfo.copyWith(duration: duration);
        _playbackInfoController.add(_playbackInfo);
      }
    });
  }

  void dispose() {
    _stateSubscription.cancel();
    _positionSubscription.cancel();
    _durationSubscription.cancel();
    _playbackInfoController.close();
    _player.dispose();
  }

  Stream<PlaybackInfo> get playbackInfoStream => _playbackInfoController.stream;

  Future<void> setUrl(String url) =>
      _setAudioHandleErrors(() => _player.setUrl(url));

  Future<void> setPath(String path) =>
      _setAudioHandleErrors(() => _player.setFilePath(path));

  Future<void> _setAudioHandleErrors(Future<void> Function() setAudio) async {
    try {
      await setAudio();
    } on PlayerInterruptedException {
      // Player disposed before audio loaded, safe to ignore
    } on PlayerException catch (e) {
      // Audio unplayable, ignore
      debugPrint(e.toString());
    }
  }

  Future<void> play({bool loop = false}) {
    _player.setLoopMode(loop ? LoopMode.all : LoopMode.off);
    return _player.play();
  }

  Future<void> pause() => _player.pause();

  Future<void> stop() async {
    // Calling justAudio.AudioPlayer.stop() seems to unload the audio sometimes
    await pause();
    return seek(Duration.zero);
  }

  Future<void> seek(Duration position) => _player.seek(position);
}

@freezed
class PlaybackInfo with _$PlaybackInfo {
  const factory PlaybackInfo({
    @Default(Duration.zero) Duration position,
    @Default(Duration.zero) Duration duration,
    @Default(PlaybackState.idle) PlaybackState state,
  }) = _PlaybackInfo;
}

enum PlaybackState { loading, playing, paused, idle, disabled }
