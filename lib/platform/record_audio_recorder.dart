import 'dart:io';
import 'dart:typed_data';

import 'package:record/record.dart';

/// Audio recording implemented by package:record.
class RecordAudioRecorder {
  final _record = Record();

  Future<void> start() async {
    if (!await _record.isRecording()) {
      return _record.start();
    }
  }

  Future<Uint8List?> stop() async {
    if (!await _record.isRecording()) {
      return null;
    }

    final path = await _record.stop();
    if (path != null) {
      final file = File(path);
      return file.readAsBytes();
    }
  }

  Future<void> dispose() async {
    await _record.dispose();
  }
}
