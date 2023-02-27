import 'dart:async';
import 'dart:ui' hide Image;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

FragmentProgram? _tempFragmentProgram;

class Photo3dDisplay extends StatefulWidget {
  final ImageProvider image;
  final ImageProvider? depth;
  final bool animate;

  const Photo3dDisplay({
    super.key,
    required this.image,
    this.depth,
    this.animate = true,
  });

  @override
  State<Photo3dDisplay> createState() => _Photo3dDisplayState();
}

class _Photo3dDisplayState extends State<Photo3dDisplay> {
  ui.Image? _image;
  ui.Image? _depth;

  FragmentProgram? _fragmentProgram;

  var _secondsWhenPaused = 0.0;
  var _start = DateTime.now();

  @override
  void initState() {
    super.initState();
    _decodeImage(widget.image).then((image) {
      if (mounted) {
        setState(() {
          _image = image;
          _start = DateTime.now();
        });
      }
    });
    final depth = widget.depth;
    if (depth != null) {
      _decodeImage(depth).then((image) {
        _blurDepthMap(image, 30).then((image) {
          if (mounted) {
            setState(() {
              _depth = image;
              _start = DateTime.now();
            });
          }
        });
      });
    }

    // TODO: Prepare shader on app startup and access via inherited widget or Riverpod
    if (_tempFragmentProgram == null) {
      _prepareShader();
    } else {
      _fragmentProgram = _tempFragmentProgram;
    }
  }

  @override
  void didUpdateWidget(Photo3dDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animate != widget.animate) {
      if (!widget.animate) {
        final time = DateTime.now().difference(_start);
        setState(() {
          _secondsWhenPaused =
              time.inSeconds + (time.inMilliseconds % 1000) / 1000;
        });
      } else {
        setState(() => _start = DateTime.now().subtract(
            Duration(milliseconds: (_secondsWhenPaused * 1000).toInt())));
      }
    }
  }

  Future<void> _prepareShader() async {
    final program =
        await FragmentProgram.fromAsset('assets/shaders/depth.frag');
    if (mounted) {
      setState(() => _fragmentProgram = program);
    }
  }

  Future<ui.Image> _decodeImage(ImageProvider provider) {
    final completer = Completer<ui.Image>();
    final listener = ImageStreamListener((imageInfo, _) {
      completer.complete(imageInfo.image);
    }, onError: (error, stackTrace) {
      completer.completeError(error, stackTrace);
    });
    provider.resolve(ImageConfiguration.empty).addListener(listener);
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.depth == null) {
      return Image(
        image: widget.image,
        fit: BoxFit.cover,
      );
    } else if (_image != null && _depth != null && _fragmentProgram != null) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // Run animation
          setState(() {});
        }
      });

      final time = DateTime.now().difference(_start);
      final seconds = widget.animate
          ? (time.inSeconds + (time.inMilliseconds % 1000) / 1000)
          : _secondsWhenPaused;
      return Transform.scale(
        scale: 1.1,
        child: _DisplacedImage(
          image: _image!,
          depth: _depth!,
          fragmentProgram: _fragmentProgram!,
          displacementX: 0.01 * seconds - 0.05,
          displacementY: 0,
          displacementZ: (0.075 * seconds - 0.20).clamp(-0.3, 0.3),
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}

class _DisplacedImage extends StatefulWidget {
  final ui.Image image;
  final ui.Image depth;
  final FragmentProgram fragmentProgram;
  final double displacementX;
  final double displacementY;
  final double displacementZ;

  const _DisplacedImage({
    super.key,
    required this.image,
    required this.depth,
    required this.fragmentProgram,
    this.displacementX = 0,
    this.displacementY = 0,
    this.displacementZ = 0,
  });

  @override
  State<_DisplacedImage> createState() => _DisplacedImageState();
}

class _DisplacedImageState extends State<_DisplacedImage> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: CustomPaint(
              painter: _DisplacedImagePainter(
                fragmentProgram: widget.fragmentProgram,
                image: widget.image,
                depth: widget.depth,
                scale: 1.0,
                xDisp: widget.displacementX,
                yDisp: widget.displacementY,
                zDisp: widget.displacementZ,
              ),
            ),
          ),
        );
      },
    );
  }
}

Future<ui.Image> _blurDepthMap(ui.Image image, double sigma) async {
  final p = PictureRecorder();
  final c = Canvas(p);

  c.drawImage(
    image,
    Offset.zero,
    Paint()..imageFilter = ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
  );

  final picture = p.endRecording();
  return picture.toImage(image.width, image.height);
}

class _DisplacedImagePainter extends CustomPainter {
  final FragmentProgram fragmentProgram;
  final ui.Image image;
  final ui.Image depth;
  final double xDisp;
  final double yDisp;
  final double zDisp;
  final double scale;

  _DisplacedImagePainter({
    required this.fragmentProgram,
    required this.image,
    required this.depth,
    required this.xDisp,
    required this.yDisp,
    required this.zDisp,
    required this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final shader = fragmentProgram.fragmentShader()
      ..setImageSampler(0, image)
      ..setImageSampler(1, depth)
      ..setFloat(0, image.width.toDouble())
      ..setFloat(1, image.height.toDouble())
      ..setFloat(2, size.width)
      ..setFloat(3, size.height)
      ..setFloat(4, xDisp)
      ..setFloat(5, yDisp)
      ..setFloat(6, zDisp)
      ..setFloat(7, scale);
    canvas.drawRect(
      Offset.zero & size,
      Paint()..shader = shader,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
