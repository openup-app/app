import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:openup/audio/audio_player.dart';
import 'package:openup/audio/just_audio_audio_player.dart';

class AudioBuilder extends StatefulWidget {
  final Uri uri;
  final bool autoPlay;
  final bool loop;
  final void Function(AudioController controller)? onController;
  final Widget Function(
    BuildContext context,
    Widget? child,
    AudioController controller,
  ) builder;
  final Widget? child;

  const AudioBuilder({
    super.key,
    required this.uri,
    this.autoPlay = false,
    this.loop = false,
    this.onController,
    required this.builder,
    this.child,
  });

  @override
  State<AudioBuilder> createState() => _AudioBuilderState();
}

class _AudioBuilderState extends State<AudioBuilder> {
  final _player = JustAudioAudioPlayer();
  late final AudioController _controller;

  late StreamSubscription _stoppedSubscription;

  @override
  void initState() {
    super.initState();
    _controller = AudioController._(_player);
    _prepareNewAudioSource();
    _updateLoop();

    _stoppedSubscription = _player.playbackStream
        .map((e) => e.state == AudioState.stopped)
        .listen(_onStoppedChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onController?.call(_controller);
    });
  }

  @override
  void didUpdateWidget(covariant AudioBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uri != widget.uri ||
        (widget.autoPlay && oldWidget.autoPlay != widget.autoPlay)) {
      _prepareNewAudioSource();
    }
    if (oldWidget.loop != widget.loop) {
      _updateLoop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _stoppedSubscription.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, widget.child, _controller);
  }

  void _prepareNewAudioSource() {
    if (widget.autoPlay) {
      _player.play(widget.uri);
    } else {
      _player.precache(widget.uri);
    }
  }

  void _updateLoop() => _player.setLoop(widget.loop);

  void _onStoppedChanged(bool stopped) {
    if (stopped) {
      _controller.seek(0.0);
      _player.stop();
    }
  }
}

class AudioController {
  final AudioPlayer _player;
  late final StreamSubscription _playbackSubscription;

  final PlaybackNotifier _playbackNotifier = PlaybackNotifier(const Playback());

  AudioController._(this._player) {
    _playbackSubscription = _player.playbackStream.listen(_onPlaybackChanged);
  }

  void dispose() {
    _playbackSubscription.cancel();
  }

  Stream<Playback> get playbackStream => _player.playbackStream;

  Stream<AudioState> get audioStateStream =>
      _player.playbackStream.map((e) => e.state);

  PlaybackNotifier get playback => _playbackNotifier;

  bool get isPlaying => playback.isPlaying;

  void play() => _player.play();

  void pause() => _player.pause();

  void stop() => _player.stop();

  void togglePlayPause() =>
      _player.isPlaying ? _player.pause() : _player.play();

  void seek(double ratio) => _player.seek(ratio);

  void _onPlaybackChanged(Playback playback) {
    _playbackNotifier.value = playback;
  }
}

class PlaybackNotifier extends ValueNotifier<Playback> {
  PlaybackNotifier(super.value);

  bool get isPlaying => value.state.isPlayingOrLoading;
}
