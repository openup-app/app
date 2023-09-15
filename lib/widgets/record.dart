import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/wobbly_rings.dart';

Future<RecordResult?> showRecordPanel({
  required BuildContext context,
  required Widget title,
  required Widget submitLabel,
}) async {
  return showModalBottomSheet<RecordResult>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    useRootNavigator: true,
    builder: (context) {
      return _PanelSurface(
        child: WobblyRingsRecorder(
          onCancel: Navigator.of(context).pop,
          onRecordingComplete: (audio, duration) {
            Navigator.of(context).pop(RecordResult(audio, duration));
            return Future.value();
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

class WobblyRingsRecorder extends StatefulWidget {
  final Duration minDuration;
  final VoidCallback onCancel;
  final Future<void> Function(Uint8List audio, Duration duration)
      onRecordingComplete;

  const WobblyRingsRecorder({
    super.key,
    this.minDuration = const Duration(seconds: 2),
    required this.onCancel,
    required this.onRecordingComplete,
  });

  @override
  State<WobblyRingsRecorder> createState() => _WobblyRingsRecorderState();
}

class _WobblyRingsRecorderState extends State<WobblyRingsRecorder> {
  final _key = GlobalKey<RecorderBuilderState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.endOfFrame.then((_) {
      if (mounted) {
        _key.currentState?.startRecording();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return RecorderBuilder(
      key: _key,
      onRecordingEnded: _onRecordingEnded,
      builder: (context, state, duration) {
        final short = duration < widget.minDuration;
        return Stack(
          alignment: Alignment.center,
          children: [
            Button(
              onPressed: short ? null : _stopRecording,
              useFadeWheNoPressedCallback: false,
              child: const WobblyRings(),
            ),
            switch (state) {
              RecorderState.none => const SizedBox.shrink(),
              RecorderState.recording ||
              RecorderState.recorded =>
                IgnorePointer(
                  child: DefaultTextStyle(
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                    child: AnimatedCrossFade(
                      duration: const Duration(milliseconds: 300),
                      crossFadeState: short
                          ? CrossFadeState.showFirst
                          : CrossFadeState.showSecond,
                      alignment: Alignment.center,
                      firstChild: const Text('Recording'),
                      secondChild: const Text('Tap to send'),
                    ),
                  ),
                ),
            },
            Positioned(
              top: 6,
              right: 6,
              child: Button(
                onPressed: widget.onCancel,
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'cancel',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _stopRecording() => _key.currentState?.stopRecording();

  void _onRecordingEnded(Uint8List? audio, Duration duration) async {
    if (audio == null) {
      Navigator.of(context).pop();
      return;
    }

    await widget.onRecordingComplete(audio, duration);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}

class _PanelSurface extends StatelessWidget {
  final Widget child;

  const _PanelSurface({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 336 + MediaQuery.of(context).padding.bottom,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(
          color: Color.fromRGBO(0x00, 0x00, 0x00, 0.5),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 48, sigmaY: 48),
          child: Stack(
            fit: StackFit.expand,
            children: [
              child,
              IgnorePointer(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Container(
                      width: 48,
                      height: 2,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.all(
                          Radius.circular(1),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
