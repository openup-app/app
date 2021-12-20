import 'dart:async';
import 'dart:math';

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:openup/widgets/button.dart';
import 'package:record/record.dart';

class EmojiInputBox extends StatelessWidget {
  final void Function(String emoji) onEmoji;

  const EmojiInputBox({
    Key? key,
    required this.onEmoji,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EmojiPicker(
      onEmojiSelected: (category, emoji) {
        onEmoji(emoji.emoji);
      },
      config: const Config(initCategory: Category.SMILEYS),
    );
  }
}

class AudioInputBox extends StatefulWidget {
  final void Function(String path) onRecord;
  const AudioInputBox({
    Key? key,
    required this.onRecord,
  }) : super(key: key);

  @override
  _AudioInputBoxState createState() => _AudioInputBoxState();
}

class _AudioInputBoxState extends State<AudioInputBox> {
  final _recorder = Record();
  bool _recording = false;
  Timer? _timer;
  double _amplitude = 0.0;

  @override
  void initState() {
    super.initState();
    _recorder.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = (_recording ? 128 * _amplitude : 0) + 96.0;
    return Center(
      child: Button(
        onPressed: _recording ? _endRecording : _startRecording,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: _recording ? Colors.red : Colors.white,
            shape: BoxShape.circle,
          ),
          child: _recording
              ? const Icon(
                  Icons.stop,
                  size: 56,
                )
              : const Icon(
                  Icons.mic,
                  color: Colors.red,
                  size: 56,
                ),
        ),
      ),
    );
  }

  void _startRecording() async {
    await _recorder.start();
    if (mounted) {
      setState(() => _recording = true);
      _timer = Timer.periodic(const Duration(milliseconds: 50), (_) async {
        final amplitude = await _recorder.getAmplitude();
        const maxAmplitude = 60.0;
        final value =
            1 - min(maxAmplitude, amplitude.current.abs()) / maxAmplitude;
        if (mounted) {
          setState(() => _amplitude = value);
        }
      });
    }
  }

  void _endRecording() async {
    final result = await _recorder.stop();
    _timer?.cancel();
    if (mounted) {
      setState(() {
        _recording = false;
        _timer = null;
      });
      if (result != null) {
        widget.onRecord(result);
      }
    }
  }
}
