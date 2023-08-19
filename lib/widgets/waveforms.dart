import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:ffmpeg_kit_flutter_audio/ffmpeg_kit.dart' as ffmpeg;
import 'package:ffmpeg_kit_flutter_audio/ffmpeg_session.dart' as ffmpeg_session;
import 'package:flutter/rendering.dart';
import 'package:mic_stream/mic_stream.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class RecorderWithoutWaveforms {
  bool _recording = false;
  StreamSubscription? _micStreamSubscription;

  void Function(Uint8List audioBytes)? _onComplete;
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
  }

  Future<void> startRecording({
    required void Function(Float64x2List frequencies) onFrequencies,
    required void Function(Uint8List) onComplete,
  }) async {
    if (_recording) {
      throw 'Already recording';
    }

    _recording = true;
    _onComplete = onComplete;

    final micStream = await MicStream.microphone(
      audioFormat: Platform.isIOS
          ? AudioFormat.ENCODING_PCM_16BIT
          : AudioFormat.ENCODING_PCM_8BIT,
    );
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
    _micStreamSubscription = micStream.listen(_totalSamples.addAll);
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
    final output = File(join(dir.path, '$id.m4a'));
    await input.writeAsBytes(samples);
    final String format;
    if (bitDepth == 8) {
      format = 'u8';
    } else if (bitDepth == 16) {
      format = 's16${Endian.host == Endian.little ? 'le' : 'be'}';
    } else {
      throw 'Unable to encode audio with bit depth $bitDepth';
    }
    _session = await ffmpeg.FFmpegKit.executeAsync(
      '-f $format -ar $rate -ac $channels -i ${input.path} -codec:a aac ${output.path}',
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
