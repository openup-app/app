import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:openup/platform/just_audio_audio_player.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/theming.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:rxdart/subjects.dart';

import 'disable.dart';

class AudioBioRecordButton extends StatelessWidget {
  final AudioBioController controller;
  final Widget Function(BuildContext context, bool recording, double size)?
      micBuilder;
  const AudioBioRecordButton({
    Key? key,
    required this.controller,
    this.micBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<RecordInfo>(
      initialData: const RecordInfo(),
      stream: controller.recordInfoStream,
      builder: (context, snapshot) {
        final recordInfo = snapshot.requireData;
        final size = recordInfo.recording
            ? 64.0 + 64 * recordInfo.recordingAmplitude
            : 128.0;
        return Button(
          onPressed: () {
            if (recordInfo.recording) {
              controller.stopRecording();
            } else {
              controller.startRecording();
            }
          },
          child: Container(
            width: 128,
            height: 128,
            alignment: Alignment.center,
            child: micBuilder?.call(context, recordInfo.recording, size) ??
                Container(
                  width: size,
                  height: size,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: recordInfo.recording ? Colors.red : Colors.white,
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(0x00, 0x00, 0x00, 0.25),
                        blurRadius: 14,
                        offset: Offset(0.0, 1.0),
                        blurStyle: BlurStyle.outer,
                      ),
                    ],
                    shape: BoxShape.circle,
                  ),
                  child: recordInfo.recording
                      ? const Icon(
                          Icons.stop,
                          size: 48,
                          color: Colors.white,
                        )
                      : const Icon(
                          Icons.mic,
                          size: 88,
                          color: Color.fromRGBO(0xFF, 0x5E, 0x5E, 1.0),
                        ),
                ),
          ),
        );
      },
    );
  }
}

class AudioBioPlaybackControls extends StatefulWidget {
  final String? playbackUrl;
  final AudioBioController audioBioController;

  const AudioBioPlaybackControls({
    Key? key,
    required this.playbackUrl,
    required this.audioBioController,
  }) : super(key: key);

  @override
  State<AudioBioPlaybackControls> createState() =>
      _AudioBioPlaybackControlsState();
}

class _AudioBioPlaybackControlsState extends State<AudioBioPlaybackControls> {
  @override
  void initState() {
    super.initState();
    updatePlaybackUrl(widget.playbackUrl);
  }

  @override
  void didUpdateWidget(covariant AudioBioPlaybackControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.playbackUrl != oldWidget.playbackUrl) {
      updatePlaybackUrl(widget.playbackUrl);
    }
  }

  void updatePlaybackUrl(String? playbackUrl) {
    if (playbackUrl != null) {
      widget.audioBioController.stop();
      widget.audioBioController.setPlaybackUrl(playbackUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Disable(
      disabling: widget.playbackUrl == null,
      child: StreamBuilder<PlaybackInfo>(
        initialData: const PlaybackInfo(),
        stream: widget.audioBioController.playbackInfoStream,
        builder: (context, snapshot) {
          final playbackInfo = snapshot.requireData;
          return Container(
            width: 233,
            height: 74,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(37)),
              color: Color.fromRGBO(0xFF, 0x73, 0x73, 1.0),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(width: 20),
                Button(
                  onPressed: widget.playbackUrl == null
                      ? null
                      : () {
                          if (playbackInfo.state == PlaybackState.playing) {
                            widget.audioBioController.pause();
                          } else if (playbackInfo.state ==
                                  PlaybackState.paused ||
                              playbackInfo.state == PlaybackState.idle) {
                            widget.audioBioController.play();
                          }
                        },
                  child: Builder(
                    builder: (context) {
                      if (widget.playbackUrl == null) {
                        return SvgPicture.asset(
                          'assets/images/play_icon.svg',
                          width: 30,
                          height: 30,
                        );
                      }
                      switch (playbackInfo.state) {
                        case PlaybackState.playing:
                          return SvgPicture.asset(
                            'assets/images/pause_icon.svg',
                            width: 30,
                            height: 30,
                          );
                        case PlaybackState.idle:
                        case PlaybackState.paused:
                          return SvgPicture.asset(
                            'assets/images/play_icon.svg',
                            width: 30,
                            height: 30,
                          );
                        case PlaybackState.loading:
                        case PlaybackState.disabled:
                          return const SizedBox(
                            width: 26,
                            height: 26,
                            child: LoadingIndicator(),
                          );
                      }
                    },
                  ),
                ),
                Expanded(
                  child: IgnorePointer(
                    ignoring: playbackInfo.state != PlaybackState.idle ||
                        playbackInfo.state != PlaybackState.playing ||
                        playbackInfo.state != PlaybackState.paused,
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        thumbColor: Colors.white,
                        activeTrackColor: Colors.white,
                        inactiveTrackColor: Colors.white,
                      ),
                      child: Slider(
                        min: 0,
                        max: playbackInfo.duration.inMilliseconds.toDouble(),
                        value: playbackInfo.position.inMilliseconds
                            .clamp(0, playbackInfo.duration.inMilliseconds)
                            .toDouble(),
                        onChanged: (millis) {
                          widget.audioBioController
                              .seek(Duration(milliseconds: millis.toInt()));
                        },
                      ),
                    ),
                  ),
                ),
                Text(
                  _formatTimeSeconds(
                      playbackInfo.state == PlaybackState.playing ||
                              playbackInfo.state == PlaybackState.paused
                          ? playbackInfo.position
                          : playbackInfo.duration),
                  style: Theming.of(context).text.body.copyWith(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(width: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}

String _formatTimeSeconds(Duration duration) {
  final seconds = duration.inSeconds;
  return seconds.toString().padLeft(2, '0');
}

class AudioBioController {
  final _audio = JustAudioAudioPlayer();
  final _recorder = Record();
  final _playbackController =
      BehaviorSubject<PlaybackInfo>.seeded(const PlaybackInfo());
  final _recordController =
      BehaviorSubject<RecordInfo>.seeded(const RecordInfo());

  late final StreamSubscription _playbackInfoSubscription;

  Timer? _recordingLimitTimer;
  Timer? _amplitudeTimer;

  final void Function(String path) _onRecordingComplete;
  final Duration maxDuration;

  AudioBioController({
    required void Function(String path) onRecordingComplete,
    this.maxDuration = const Duration(seconds: 10),
  }) : _onRecordingComplete = onRecordingComplete {
    _playbackInfoSubscription = _audio.playbackInfoStream.listen((info) {
      if (_playbackController.value != info) {
        _playbackController.add(info);
      }
    });
  }

  Future<void> dispose() {
    _recordingLimitTimer?.cancel();
    _amplitudeTimer?.cancel();
    _playbackController.close();
    _recordController.close();
    _playbackInfoSubscription.cancel();
    _audio.dispose();
    return _recorder.dispose();
  }

  Stream<PlaybackInfo> get playbackInfoStream => _playbackController.stream;

  Stream<RecordInfo> get recordInfoStream => _recordController.stream;

  Future<void> setPlaybackUrl(String url) => _audio.setUrl(url);

  Future<void> play() => _audio.play();

  Future<void> pause() => _audio.pause();

  Future<void> stop() => _audio.stop();

  Future<void> seek(Duration position) => _audio.seek(position);

  Future<void> startRecording() async {
    if (!await _recorder.hasPermission() || await _recorder.isRecording()) {
      return;
    }
    final dir = await getTemporaryDirectory();
    final path = join(dir.path, 'audio.m4a');
    await _recorder.start(path: path);
    _recordController.add(_recordController.value.copyWith(recording: true));

    _recordingLimitTimer?.cancel();
    _recordingLimitTimer = Timer(maxDuration, () {
      stopRecording();
    });

    _amplitudeTimer?.cancel();
    _amplitudeTimer =
        Timer.periodic(const Duration(milliseconds: 50), (_) async {
      final amplitude = await _recorder.getAmplitude();
      const maxAmplitude = 60.0;
      final value =
          1 - min(maxAmplitude, amplitude.current.abs()) / maxAmplitude;
      if (!_recordController.isClosed) {
        _recordController
            .add(_recordController.value.copyWith(recordingAmplitude: value));
      }
    });
  }

  Future<void> stopRecording() async {
    _recordingLimitTimer?.cancel();
    final path = await _recorder.stop();
    _recordController.add(_recordController.value.copyWith(recording: false));
    if (path != null) {
      _onRecordingComplete(path);
    }
  }
}

class RecordInfo {
  final bool recording;
  final double recordingAmplitude;

  const RecordInfo({
    this.recording = false,
    this.recordingAmplitude = 0.0,
  });

  RecordInfo copyWith({
    bool? recording,
    double? recordingAmplitude,
  }) {
    return RecordInfo(
      recording: recording ?? this.recording,
      recordingAmplitude: recordingAmplitude ?? this.recordingAmplitude,
    );
  }

  @override
  int get hashCode => Object.hashAll([recording, recordingAmplitude]);

  @override
  bool operator ==(dynamic other) {
    return other is RecordInfo &&
        other.recording == recording &&
        other.recordingAmplitude == recordingAmplitude;
  }
}
