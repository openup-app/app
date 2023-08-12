import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:openup/widgets/common.dart';

Future<RecordResult?> showRecordPanel({
  required BuildContext context,
  required Widget title,
}) async {
  return showModalBottomSheet<RecordResult>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return RecordPanelSurface(
        child: RecordPanel(
          title: title,
          onCancel: Navigator.of(context).pop,
          onSubmit: (audio, duration) {
            Navigator.of(context).pop(RecordResult(audio, duration));
            return Future.value(true);
          },
        ),
      );
    },
  );
}

class RecordResult {
  final Uint8List audio;
  final Duration duration;

  const RecordResult(this.audio, this.duration);
}
