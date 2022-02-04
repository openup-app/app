import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:openup/api/chat/chat_api.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/icon_with_shadow.dart';
import 'package:record/record.dart';
import 'package:vector_math/vector_math.dart' hide Colors;
import 'package:video_player/video_player.dart';

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

class ImageVideoInputBox extends StatefulWidget {
  final void Function(ChatType chatType, String path) onCapture;
  const ImageVideoInputBox({
    Key? key,
    required this.onCapture,
  }) : super(key: key);

  @override
  _ImageVideoInputBoxState createState() => _ImageVideoInputBoxState();
}

class _ImageVideoInputBoxState extends State<ImageVideoInputBox>
    with WidgetsBindingObserver {
  CameraController? _controller;
  bool _ready = false;
  bool _takingImage = false;
  DateTime? _recordStartTime;

  ChatType? _chatType;
  File? _imageFile;
  File? _videoFile;

  late List<CameraDescription> _cameras;
  late CameraLensDirection _cameraLensDirection;
  bool _switchingCamera = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  void _initCamera({List<CameraDescription>? cameras}) async {
    cameras = cameras ?? await availableCameras();
    _cameras = cameras;
    _controller?.dispose();
    if (mounted) {
      final camera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras!.first,
      );

      _cameraLensDirection = camera.lensDirection;
      _controller = CameraController(camera, ResolutionPreset.max);
      _controller?.setFlashMode(FlashMode.off);
    }
    await _controller?.initialize();
    if (mounted) {
      setState(() => _ready = true);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller?.value.isInitialized != true) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      setState(() => _ready = false);
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatType = _chatType;
    final imageTaken = chatType != null && _imageFile != null;
    final videoTaken = chatType != null && _videoFile != null;
    if (!imageTaken && !videoTaken) {
      return Stack(
        children: [
          if (_ready) ...[
            if (!_switchingCamera)
              Positioned.fill(
                child: CameraPreview(_controller!),
              )
            else
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(color: Colors.black),
                ),
              ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: Button(
                  onPressed: _takingImage ? null : _takeImage,
                  onLongPressStart: _takingImage
                      ? null
                      : () {
                          WidgetsBinding.instance?.addPostFrameCallback(
                              (_) => _updateRecordingDuration());
                          setState(() {
                            _recordStartTime = DateTime.now();
                          });
                          _takeVideo();
                        },
                  onLongPressEnd: () {
                    if (_recordStartTime != null) {
                      _completeVideo();
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.elasticOut,
                    width: _recordStartTime == null ? 48 : 54,
                    height: _recordStartTime == null ? 48 : 54,
                    child: CustomPaint(
                      painter: _CaptureButtonPainter(
                        recordDuration: _recordStartTime == null
                            ? null
                            : DateTime.now().difference(_recordStartTime!),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ] else ...[
            const Center(
              child: CircularProgressIndicator(),
            ),
          ],
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
          if (!_takingImage && _recordStartTime == null && _chatType == null)
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: EdgeInsets.only(
                  top: 16 + MediaQuery.of(context).padding.top,
                  right: 0,
                ),
                child: IgnorePointer(
                  ignoring: _switchingCamera,
                  child: IconButton(
                    onPressed: _switchCamera,
                    icon: const IconWithShadow(Icons.flip_camera_ios),
                  ),
                ),
              ),
            ),
        ],
      );
    } else {
      return WillPopScope(
        onWillPop: _exitPreview,
        child: Builder(
          builder: (context) {
            return _ImageVideoPreviewControls(
              onBack: () => _exitPreview(),
              onSend: () async {
                String? path;
                if (_chatType == ChatType.image) {
                  path = _imageFile?.path;
                } else {
                  path = _videoFile?.path;
                }
                if (path != null) {
                  widget.onCapture(chatType!, path);
                }
              },
              previewBuilder: (context) {
                if (imageTaken) {
                  return Image.file(_imageFile!);
                } else {
                  return _VideoPreview(
                    file: _videoFile!,
                  );
                }
              },
            );
          },
        ),
      );
    }
  }

  void _switchCamera() async {
    setState(() => _switchingCamera = true);
    await _controller?.dispose();
    if (mounted) {
      setState(() => _controller = null);
    }
    final newCameraLensDirection =
        _cameraLensDirection == CameraLensDirection.front
            ? CameraLensDirection.back
            : CameraLensDirection.front;
    final camera = _cameras.firstWhere(
      (camera) => camera.lensDirection == newCameraLensDirection,
      orElse: () => _cameras.first,
    );

    _cameraLensDirection = camera.lensDirection;
    _controller = CameraController(camera, ResolutionPreset.max);
    _controller?.setFlashMode(FlashMode.off);
    _controller?.addListener(() {
      if (mounted) {
        setState(() {
          _switchingCamera = false;
        });
      }
    });
    _controller?.initialize();
  }

  Future<bool> _exitPreview() async {
    await _controller?.resumePreview();
    setState(() {
      _chatType = null;
      _imageFile = null;
      _videoFile = null;
    });
    return false;
  }

  void _takeImage() async {
    await _controller?.pausePreview();
    setState(() => _takingImage = true);
    final file = await _controller!.takePicture();
    if (mounted) {
      setState(() {
        _chatType = ChatType.image;
        _imageFile = File(file.path);
        _takingImage = false;
      });
    }
  }

  void _takeVideo() async {
    try {
      await _controller?.startVideoRecording();
    } on CameraException {
      // Nothing to do
    }
  }

  void _completeVideo() async {
    final recordStartTime = _recordStartTime;
    if (recordStartTime != null) {
      final duration = DateTime.now().difference(recordStartTime);
      setState(() => _recordStartTime = null);

      if (duration < const Duration(seconds: 2)) {
        try {
          await _controller?.stopVideoRecording();
        } on CameraException {
          // Nothing to do
        }
        return;
      }

      try {
        final result = await _controller?.stopVideoRecording();
        if (mounted && result != null) {
          final file = File(result.path);
          setState(() {
            _chatType = ChatType.video;
            _videoFile = file;
          });
        }
      } on CameraException {
        Navigator.of(context).pop();
      }
    }
  }

  void _updateRecordingDuration() {
    if (mounted) {
      final recordStartTime = _recordStartTime;
      if (recordStartTime != null) {
        if (DateTime.now().difference(recordStartTime) >
            _kMaxRecordingDuration) {
          _completeVideo();
        }
        setState(() {});
      }
    }
    WidgetsBinding.instance
        ?.addPostFrameCallback((_) => _updateRecordingDuration());
  }
}

class _VideoPreview extends StatefulWidget {
  final File file;

  const _VideoPreview({
    Key? key,
    required this.file,
  }) : super(key: key);

  @override
  _VideoPreviewState createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<_VideoPreview> {
  late final VideoPlayerController _playerController;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _playerController = VideoPlayerController.file(widget.file);
    _playerController.initialize().then((controller) {
      if (mounted) {
        _playerController.setLooping(true);
        _playerController.play();
        setState(() => _ready = true);
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _playerController.setVolume(0);
    _playerController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    return VideoPlayer(_playerController);
  }
}

class _ImageVideoPreviewControls extends StatelessWidget {
  final WidgetBuilder previewBuilder;
  final VoidCallback onBack;
  final VoidCallback onSend;

  const _ImageVideoPreviewControls({
    Key? key,
    required this.previewBuilder,
    required this.onBack,
    required this.onSend,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Transform.scale(
            scaleX: -1,
            child: previewBuilder(context),
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
              onPressed: onBack,
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
              onPressed: onSend,
              child: const IconWithShadow(
                Icons.send,
                size: 48,
              ),
            ),
          ),
        ),
      ],
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

class _ImagePainter extends CustomPainter {
  final ui.Image image;

  _ImagePainter({
    required this.image,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fittedSizes = applyBoxFit(
        BoxFit.contain,
        Size(
          image.width.toDouble(),
          image.height.toDouble(),
        ),
        size);
    canvas.drawImageRect(
      image,
      Offset.zero & fittedSizes.source,
      Offset.zero & fittedSizes.destination,
      Paint(),
    );
  }

  @override
  bool shouldRepaint(_ImagePainter oldDelegate) => image != oldDelegate.image;

  @override
  bool shouldRebuildSemantics(_ImagePainter oldDelegate) => false;
}
