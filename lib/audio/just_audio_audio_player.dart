import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:openup/audio/audio_player.dart';

typedef _JaState = ja.ProcessingState;

class JustAudioAudioPlayer extends AudioPlayer {
  final _justAudio = ja.AudioPlayer(
    audioLoadConfiguration: ja.AudioLoadConfiguration(
      androidLoadControl: ja.AndroidLoadControl(
        backBufferDuration: const Duration(seconds: 30),
      ),
      darwinLoadControl: ja.DarwinLoadControl(
        preferredForwardBufferDuration: const Duration(seconds: 10),
      ),
    ),
  );
  final _playbackController = StreamController<Playback>.broadcast();

  Playback _playback = const Playback();

  JustAudioAudioPlayer() {
    _justAudio.playerStateStream.listen((playerState) {
      if (_justAudio.processingState == ja.ProcessingState.ready) {
        _playback = _playback.copyWith(
            state: _justAudio.playerState.playing
                ? AudioState.playing
                : AudioState.paused);
        if (!_playbackController.isClosed) {
          _playbackController.add(_playback);
        }
      }
    });

    _justAudio.processingStateStream.listen((processingState) {
      _playback = switch (processingState) {
        _JaState.idle => const Playback(state: AudioState.none),
        _JaState.loading ||
        _JaState.buffering =>
          const Playback(state: AudioState.loading),
        _JaState.ready => Playback(
            position: _justAudio.position,
            duration: _justAudio.duration ?? Duration.zero,
          ),
        _JaState.completed => _playback.copyWith(state: AudioState.stopped),
      };

      if (!_playbackController.isClosed) {
        _playbackController.add(_playback);
      }
    });

    _justAudio.positionStream.listen((position) {
      _playback = _playback.copyWith(position: position);

      if (!_playbackController.isClosed) {
        _playbackController.add(_playback);
      }
    });
  }

  @override
  Future<void> dispose() => _justAudio.dispose();

  @override
  bool get isPlaying => _justAudio.playing;

  @override
  Stream<Playback> get playbackStream => _playbackController.stream;

  @override
  Future<bool> precache(Uri uri) => _setAudioSource(uri, preload: true);

  @override
  Future<void> play([Uri? uri]) async {
    bool ready = true;
    if (uri != null) {
      ready = await _setAudioSource(uri);
    }

    if (ready) {
      if (uri != null) {
        await _setAudioSource(uri);
      }

      await _justAudio.play();
    }
  }

  @override
  Future<void> pause() => _justAudio.pause();

  @override
  Future<void> setLoop(bool looping) =>
      _justAudio.setLoopMode(looping ? ja.LoopMode.all : ja.LoopMode.off);

  @override
  Future<void> seek(double ratio) =>
      _justAudio.seek(_playback.duration * ratio);

  @override
  Future<void> stop() async {
    // Pausing rather than stopping keeps decoders alive for fast play
    await _justAudio.pause();
    await _justAudio.seek(Duration.zero);
  }

  Future<bool> _setAudioSource(
    Uri uri, {
    bool preload = false,
  }) async {
    try {
      await _justAudio.setAudioSource(
        ja.AudioSource.uri(uri),
        preload: true,
      );
    } on ja.PlayerInterruptedException {
      // Player disposed before audio loaded, safe to ignore
      return false;
    } on ja.PlayerException catch (e) {
      // Audio unplayable
      debugPrint(e.toString());
      return false;
    }
    return true;
  }
}
