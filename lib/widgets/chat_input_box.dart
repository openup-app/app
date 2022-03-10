import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:dartz/dartz.dart' show Tuple2;
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/icon_with_shadow.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:vector_math/vector_math.dart' hide Colors;

const _kMaxRecordingDuration = Duration(seconds: 30);

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
        child: Container(
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

class ImageVideoInputBox extends StatefulWidget {
  const ImageVideoInputBox({
    Key? key,
  }) : super(key: key);

  @override
  State<ImageVideoInputBox> createState() => _ImageVideoInputBoxState();
}

class _ImageVideoInputBoxState extends State<ImageVideoInputBox> {
  bool _ready = false;

  final _photoController = PictureController();
  final _captureModeNotifier = ValueNotifier<CaptureModes>(CaptureModes.PHOTO);
  final _cameraLensNotifier = ValueNotifier<Sensors>(Sensors.BACK);
  final _photoSizeNotifier = ValueNotifier<Size>(const Size(1920, 1080));
  final _flashNotifier = ValueNotifier<CameraFlashes>(CameraFlashes.NONE);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          CameraAwesome(
            captureMode: _captureModeNotifier,
            selectDefaultSize: _pickPhotoSize,
            photoSize: _photoSizeNotifier,
            switchFlashMode: _flashNotifier,
            sensor: _cameraLensNotifier,
            onCameraStarted: () => setState(() => _ready = true),
          ),
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: EdgeInsets.only(
                top: 16 + MediaQuery.of(context).padding.top,
                left: 0,
              ),
              child: IconButton(
                onPressed: Navigator.of(context).pop,
                icon: const IconWithShadow(Icons.close),
              ),
            ),
          ),
          if (_ready) ...[
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: Button(
                  onPressed: () async {
                    final dir = await getTemporaryDirectory();
                    final imagePath = path.join(dir.path,
                        'chat_image_${DateTime.now().toString()}.jpg');
                    await _photoController.takePicture(imagePath);
                    if (mounted) {
                      final send = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (context) {
                            return _ImagePreview(
                              previewPath: imagePath,
                              flip: _cameraLensNotifier.value == Sensors.FRONT,
                            );
                          },
                        ),
                      );
                      if (send == true) {
                        Navigator.of(context).pop(imagePath);
                      }
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.elasticOut,
                    width: 48,
                    height: 48,
                    child: CustomPaint(
                      painter: _CaptureButtonPainter(recordDuration: null),
                    ),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: EdgeInsets.only(
                  top: 16 + MediaQuery.of(context).padding.top,
                  right: 0,
                ),
                child: IconButton(
                  onPressed: () {
                    _cameraLensNotifier.value =
                        _cameraLensNotifier.value == Sensors.BACK
                            ? Sensors.FRONT
                            : Sensors.BACK;
                  },
                  icon: const IconWithShadow(Icons.flip_camera_ios),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Size _pickPhotoSize(List<Size> sizes) {
    final list = sizes.map((size) {
      final pixels = (size.width * size.height).toInt();
      return Tuple2(size, pixels);
    }).toList();
    list.sort((a, b) => a.value2.compareTo(b.value2));
    return list.firstWhere((element) => element.value2 > 800 * 800).value1;
  }
}

class _ImagePreview extends StatelessWidget {
  final String previewPath;
  final bool flip;
  const _ImagePreview({
    Key? key,
    required this.previewPath,
    required this.flip,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WillPopScope(
        onWillPop: () {
          Navigator.of(context).pop(false);
          return Future.value(false);
        },
        child: DecoratedBox(
          decoration: const BoxDecoration(color: Colors.black),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Transform.scale(
                scaleX: flip ? -1 : 1,
                child: Image.file(
                  File(previewPath),
                  fit: BoxFit.cover,
                ),
              ),
              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: EdgeInsets.only(
                    top: 16 + MediaQuery.of(context).padding.top,
                    left: 0,
                  ),
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: const IconWithShadow(Icons.arrow_back),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: 16 + MediaQuery.of(context).padding.bottom,
                    right: 16,
                  ),
                  child: Button(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const IconWithShadow(
                      Icons.send,
                      size: 48,
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

class _CaptureButtonPainter extends CustomPainter {
  final Duration? recordDuration;

  _CaptureButtonPainter({
    required this.recordDuration,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final radius = min(size.width, size.height);

    canvas.drawCircle(
      size.center(Offset.zero),
      radius - 8,
      Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6,
    );

    final endDegrees = recordDuration == null
        ? 0.0
        : (recordDuration!.inMilliseconds /
                (_kMaxRecordingDuration.inMilliseconds)) *
            360.0;
    final boundary =
        (Offset.zero - Offset(size.width, size.height) * 0.5) & size * 2;
    canvas.drawArc(
      boundary.deflate(8),
      radians(-90.0),
      radians(endDegrees),
      false,
      Paint()
        ..color = Colors.red
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = ui.StrokeCap.round,
    );

    canvas.drawCircle(
      size.center(Offset.zero),
      radius - 16,
      Paint()..color = Colors.red.withOpacity(0.8),
    );
  }

  @override
  bool shouldRepaint(_CaptureButtonPainter oldDelegate) =>
      recordDuration != oldDelegate.recordDuration;

  @override
  bool shouldRebuildSemantics(_CaptureButtonPainter oldDelegate) => false;
}
