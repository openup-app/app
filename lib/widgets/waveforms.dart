import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:fftea/fftea.dart';
import 'package:ffmpeg_kit_flutter_audio/ffmpeg_kit.dart' as ffmpeg;
import 'package:ffmpeg_kit_flutter_audio/ffmpeg_session.dart' as ffmpeg_session;
import 'package:flutter/rendering.dart';
import 'package:mic_stream/mic_stream.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class RecorderWithWaveforms {
  static const _kChunkSize = 2048;

  bool _recording = false;
  StreamSubscription? _micStreamSubscription;

  void Function(Uint8List audioBytes)? _onComplete;
  void Function(Float64x2List frequencies)? _onFrequencies;
  final _totalSamples = <int>[];

  int _bitDepth = 0;
  int _sampleRate = 0;
  int _channels = 0;

  void dispose() {
    _micStreamSubscription?.cancel();
  }

  Future<void> stopRecording() async {
    if (!_recording) {
      // throw 'Not recording';
      return;
    }

    _recording = false;
    _micStreamSubscription?.cancel();

    final encoder = _AacEncoder(
      Uint8List.fromList(_totalSamples),
      _bitDepth,
      _sampleRate,
      _channels,
    );
    final aacFile = await encoder.result;
    final bytes = await aacFile.readAsBytes();
    _onComplete?.call(Uint8List.fromList(bytes));
    _totalSamples.clear();

    _onComplete = null;
    _onFrequencies = null;
  }

  Future<void> startRecording({
    required void Function(Float64x2List frequencies) onFrequencies,
    required void Function(Uint8List) onComplete,
  }) async {
    if (_recording) {
      throw 'Already recording';
    }

    _recording = true;
    _onFrequencies = onFrequencies;
    _onComplete = onComplete;

    final micStream = await MicStream.microphone();
    final bitDepth = await MicStream.bitDepth;
    final micBufferSize = await MicStream.bufferSize;
    final sampleRate = await MicStream.sampleRate;

    if (micStream == null ||
        bitDepth == null ||
        micBufferSize == null ||
        sampleRate == null) {
      return;
    }

    _bitDepth = bitDepth.toInt();
    _sampleRate = sampleRate.toInt();
    _channels = 1;

    final fft = FFT(micBufferSize);
    final stft = STFT(_kChunkSize, Window.hanning(_kChunkSize));

    _micStreamSubscription = micStream.listen((samples) {
      if (bitDepth == 16) {
        final newSamples = samples.map((e) => e ~/ 256).toList();
        _onMicData(newSamples, fft, stft);
      } else {
        _onMicData(samples, fft, stft);
      }
    });
  }

  void _onMicData(List<int> samples, FFT fft, STFT stft) {
    _totalSamples.addAll(samples);
    final doubles =
        Float64List.fromList(samples.map((s) => s.toDouble()).toList());
    final normalized = normalizeRmsVolume(doubles, 0.5);
    final frequencies = fft.realFft(normalized);
    _onFrequencies?.call(frequencies);
  }

  Float64List normalizeRmsVolume(List<double> samples, double target) {
    final samplesF64List = Float64List.fromList(samples);
    final squareSum = samplesF64List.fold<double>(0, (p, e) => p + e * e);
    final factor = target * sqrt(samplesF64List.length / squareSum);
    for (int i = 0; i < samplesF64List.length; ++i) {
      samplesF64List[i] *= factor;
    }
    return samplesF64List;
  }

  Uint64List linSpace(int end, int steps) {
    final iterations = Uint64List(steps);
    for (int i = 1; i < steps; i++) {
      iterations[i - 1] = (end * i) ~/ steps;
    }
    iterations[steps - 1] = end;
    return iterations;
  }
}

class FrequenciesPainter extends CustomPainter {
  final Iterable<num> frequencies;
  final int barCount;
  final Color color;

  const FrequenciesPainter({
    required this.frequencies,
    int? barCount,
    required this.color,
  }) : barCount = barCount ?? frequencies.length;

  @override
  void paint(Canvas canvas, Size size) {
    if (barCount > frequencies.length) {
      return;
    }

    final paint = Paint()..color = color;
    const thickness = 4.0;
    final countPerBar = frequencies.length ~/ barCount;
    for (var bar = 1; bar < barCount; bar++) {
      var peak = 0.0;
      frequencies.skip(countPerBar * bar).take(countPerBar).forEach((f) {
        peak = max(peak, f.toDouble()).clamp(0.0, 1.0);
      });
      final ratio = bar / barCount;
      final x = size.width * ratio;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(x, size.height / 2),
            width: thickness,
            height: max(size.height * peak, 4),
          ),
          const Radius.circular(2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant FrequenciesPainter oldDelegate) {
    return oldDelegate.barCount != barCount ||
        oldDelegate.frequencies != frequencies;
  }
}

class _AacEncoder {
  ffmpeg_session.FFmpegSession? _session;

  final _completer = Completer<File>();

  _AacEncoder(Uint8List pcm, int bitDepth, int rate, int channels) {
    _encode(pcm, bitDepth, rate, channels);
  }

  Future<File> get result => _completer.future;

  void dispose() {
    _session?.cancel();
  }

  void _encode(Uint8List samples, int bitDepth, int rate, int channels) async {
    final dir = await getTemporaryDirectory();
    final id = DateTime.now().toIso8601String();
    final input = await File(join(dir.path, '$id.pcm')).create(recursive: true);
    final output = File(join(dir.path, '$id.aac'));
    await input.writeAsBytes(samples);
    _session = await ffmpeg.FFmpegKit.executeAsync(
      '-f u$bitDepth -ar $rate -ac $channels -i ${input.path} ${output.path}',
      (session) async {
        final res = await session.getAllLogs();

        final logs = res.where((log) => log.getLevel() <= 16);
        for (final log in logs) {
          debugPrint('Log ${log.getLevel()}) ${log.getMessage()}');
        }

        final returnCode = await session.getReturnCode();
        if (returnCode == null || returnCode.isValueError()) {
          _completer
              .completeError('FFmpeg error ${returnCode?.getValue() ?? -1}');
        } else if (returnCode.isValueSuccess()) {
          _completer.complete(output);
        }
      },
    );
  }
}
