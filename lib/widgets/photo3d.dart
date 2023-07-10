import 'dart:async';
import 'dart:math';
import 'dart:ui' hide Image;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

FragmentProgram? _tempFragmentProgram;

class Photo3dDisplay extends StatefulWidget {
  final ImageProvider image;
  final ImageProvider? depth;
  final bool animate;
  final Duration duration;

  const Photo3dDisplay({
    super.key,
    required this.image,
    this.depth,
    this.animate = true,
    required this.duration,
  });

  @override
  State<Photo3dDisplay> createState() => _Photo3dDisplayState();
}

class _Photo3dDisplayState extends State<Photo3dDisplay> {
  ui.Image? _image;
  ui.Image? _depth;

  FragmentProgram? _fragmentProgram;

  double _xIntensity = 1.0;
  double _yIntensity = 1.0;
  double _displacementX = 0;
  double _displacementY = 0;
  double _displacementZ = 0;

  late final Ticker _ticker;

  Duration _ellapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _decodeImage(widget.image).then((image) {
      if (mounted) {
        setState(() => _image = image);
        _initAnimation();
      }
    });
    final depth = widget.depth;
    if (depth != null) {
      _decodeImage(depth).then((image) {
        _blurDepthMap(image, 30).then((image) {
          if (mounted) {
            setState(() => _depth = image);
            _initAnimation();
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

    _ticker = Ticker(_tickUpdate);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _initAnimation() {
    const intensity = 20.0;
    final r = Random();
    final startX = (r.nextBool() ? -1 : 1) * (r.nextDouble() * 0.7 + 0.3);
    _xIntensity = startX * intensity;
    _yIntensity = 0;
    if (!_ticker.isActive) {
      _ticker.start();
    }
  }

  void _tickUpdate(Duration ellapsed) {
    final ratio = (ellapsed.inMilliseconds / widget.duration.inMilliseconds)
        .clamp(0.0, 1.0);
    final t = CurvedAnimation(
      parent: AlwaysStoppedAnimation(ratio),
      curve: Curves.linear,
    ).value;
    setState(() {
      _ellapsed = ellapsed;
      _displacementX = -_xIntensity / 2 + t * _xIntensity;
      _displacementY = 0.0;
      _displacementZ = t * 0.04;
    });
  }

  @override
  void didUpdateWidget(Photo3dDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animate != widget.animate) {
      if (!widget.animate) {
        _ticker.stop();
      } else {
        if (!_ticker.isActive) {
          _ticker.start();
        }
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
      final ratio = (_ellapsed.inMilliseconds / widget.duration.inMilliseconds)
          .clamp(0.0, 1.0);
      final t = CurvedAnimation(
        parent: AlwaysStoppedAnimation(ratio),
        curve: Curves.linear,
      ).value;
      return Transform.scale(
        scale: 1.0 + t * 0.1,
        child: _DisplacedImage(
          image: _image!,
          depth: _depth!,
          fragmentProgram: _fragmentProgram!,
          displacementX: _displacementX,
          displacementY: _displacementY,
          displacementZ: _displacementZ,
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
    return ClipRect(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              child: ClipRect(
                clipBehavior: Clip.hardEdge,
                child: CustomPaint(
                  painter: _DisplacedImagePainter(
                    fragmentProgram: widget.fragmentProgram,
                    image: widget.image,
                    depth: widget.depth,
                    xDisp: widget.displacementX,
                    yDisp: widget.displacementY,
                    zDisp: widget.displacementZ,
                    // Reduces the effect if the widget is small
                    effectIntensity: constraints.maxWidth /
                        MediaQuery.of(context).size.width,
                  ),
                ),
              ),
            ),
          );
        },
      ),
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
  final double effectIntensity;

  _DisplacedImagePainter({
    required this.fragmentProgram,
    required this.image,
    required this.depth,
    required this.xDisp,
    required this.yDisp,
    required this.zDisp,
    required this.effectIntensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
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
      ..setFloat(7, effectIntensity);
    canvas.drawRect(
      Offset.zero & size,
      Paint()..shader = shader,
    );
  }

  @override
  bool shouldRepaint(covariant _DisplacedImagePainter oldDelegate) =>
      fragmentProgram != oldDelegate.fragmentProgram ||
      !image.isCloneOf(oldDelegate.image) ||
      !depth.isCloneOf(oldDelegate.depth) ||
      xDisp != oldDelegate.xDisp ||
      yDisp != oldDelegate.yDisp ||
      zDisp != oldDelegate.zDisp ||
      effectIntensity != oldDelegate.effectIntensity;
}
