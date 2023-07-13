import 'dart:async';
import 'dart:math';

import 'package:openup/platform/just_audio_audio_player.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:rxdart/subjects.dart';

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
    this.maxDuration = const Duration(seconds: 30),
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
