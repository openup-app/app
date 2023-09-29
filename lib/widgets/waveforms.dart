import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/rendering.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart' as rec;

class RecorderWithoutWaveforms {
  bool _recording = false;
  final _recorder = rec.Record();
  StreamSubscription? _amplitudeSubscription;

  void Function(Uint8List? audioBytes)? _onComplete;

  void dispose() {
    _recorder.dispose();
    _amplitudeSubscription?.cancel();
  }

  Future<bool> checkAndGetPermission() => _recorder.hasPermission();

  Future<void> startRecording({
    required void Function(double current, double max) onAmplitude,
    required void Function(Uint8List?) onComplete,
  }) async {
    if (_recording) {
      throw 'Already recording';
    }

    final amplitudeStream =
        _recorder.onAmplitudeChanged(const Duration(milliseconds: 16));
    _amplitudeSubscription?.cancel();
    _amplitudeSubscription = amplitudeStream.listen((value) {
      // See dBFS calculation section: https://audiointerfacing.com/dbfs-in-audio/
      final current = pow(10, value.current / 20) * value.max;
      final max = value.max;
      onAmplitude(current, max);
    });

    _recording = true;
    _onComplete = onComplete;

    final tempDir = await getTemporaryDirectory();
    final filePath = path.join(
        tempDir.path, 'recording_${DateTime.now().toIso8601String()}.m4a');
    await _recorder.start(
      path: filePath,
      encoder: rec.AudioEncoder.aacLc,
    );
  }

  Future<void> stopRecording() async {
    if (!_recording) {
      // throw 'Not recording';
      return;
    }

    _amplitudeSubscription?.cancel();
    _recording = false;
    final filePath = await _recorder.stop();
    if (filePath == null) {
      _onComplete?.call(null);
      return;
    }

    final file = File(filePath);
    if (!await file.exists()) {
      _onComplete?.call(null);
      return;
    }

    final bytes = await file.readAsBytes();
    _onComplete?.call(Uint8List.fromList(bytes));
    _onComplete = null;
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
