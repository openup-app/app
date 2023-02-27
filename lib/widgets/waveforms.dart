import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:fftea/fftea.dart';
import 'package:flutter/rendering.dart';
import 'package:mic_stream/mic_stream.dart';

class RecorderWithWaveforms {
  static const _kChunkSize = 2048;

  bool _recording = false;
  StreamSubscription? _micStreamSubscription;

  void Function(Uint8List audioBytes)? _onComplete;
  void Function(Float64x2List frequencies)? _onFrequencies;
  final _totalSamples = <int>[];

  void dispose() {
    _micStreamSubscription?.cancel();
  }

  void stopRecording() {
    if (!_recording) {
      // throw 'Not recording';
      return;
    }

    _recording = false;
    _micStreamSubscription?.cancel();

    _onComplete?.call(Uint8List.fromList(_totalSamples));
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
    final micBufferSize = await MicStream.bufferSize;
    final sampleRate = await MicStream.sampleRate;

    if (micStream == null || micBufferSize == null || sampleRate == null) {
      return;
    }

    final fft = FFT(micBufferSize);
    final stft = STFT(_kChunkSize, Window.hanning(_kChunkSize));

    _micStreamSubscription =
        micStream.listen((samples) => _onMicData(samples, fft, stft));
  }

  void _onMicData(Uint8List samples, FFT fft, STFT stft) {
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
