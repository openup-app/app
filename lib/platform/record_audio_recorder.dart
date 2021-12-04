import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Audio recording implemented by package:record.
class RecordAudioRecorder {
  final _record = Record();

  Future<bool> start() async {
    if (await _record.hasPermission()) {
      if (!await _record.isRecording()) {
        final tempDir = await getTemporaryDirectory();
        final path = join(tempDir.path, 'audio.m4a');
        _record.start(path: path);
        return true;
      }
    }
    return false;
  }

  Future<Uint8List?> stop() async {
    if (!await _record.isRecording()) {
      return null;
    }

    final path = await _record.stop();
    if (path != null) {
      final file = File(path);
      final bytes = await file.readAsBytes();
      await file.delete();
      return bytes;
    }
  }

  Future<void> dispose() async {
    await _record.dispose();
  }
}
