import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:openup/widgets/animation.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

class WobblyRings extends StatefulWidget {
  final double scale;

  const WobblyRings({
    super.key,
    this.scale = 1,
  });

  @override
  State<WobblyRings> createState() => _WobblyRingsState();
}

class _WobblyRingsState extends State<WobblyRings> {
  late final int _baseSeed;

  @override
  void initState() {
    super.initState();
    _baseSeed = Random().nextInt(1000000);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      textDirection: TextDirection.ltr,
      children: [
        for (var i = 3; i >= 0; i--)
          Builder(
            builder: (context) {
              final delay = Duration(milliseconds: ((i / 3) * 300).toInt());
              return Opacity(
                opacity: 1 - i / 4,
                child: Transform.scale(
                  scale: 1 - i / 6,
                  child: SizedBox(
                    width: 400,
                    height: 400,
                    child: WiggleBuilder(
                      seed: _baseSeed,
                      builder: (context, child, wiggle) {
                        final x = wiggle(
                          frequency: 2,
                          amplitude: 3,
                          delay: delay,
                        );
                        final y = wiggle(
                          frequency: 2,
                          amplitude: 3,
                          delay: delay,
                        );
                        final angle = wiggle(
                          frequency: 0.4,
                          amplitude: radians(360),
                          delay: delay,
                        );
                        return CustomPaint(
                          painter: _CirclePainter(
                            x: 1 + x * 0.1,
                            y: 1 + y * 0.1,
                            scale: widget.scale,
                            angle: angle,
                            glow: i == 0,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

class _CirclePainter extends CustomPainter {
  final double x;
  final double y;
  final double scale;
  final double angle;
  final bool glow;

  _CirclePainter({
    required this.x,
    required this.y,
    required this.scale,
    required this.angle,
    this.glow = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final transform = Matrix4.identity()
      ..translate(size.width / 2, size.height / 2)
      ..rotateZ(angle)
      ..scale(scale)
      ..scale(x, y)
      ..translate(-size.width / 2, -size.height / 2);
    canvas.transform(transform.storage);

    final center = size.center(Offset.zero);
    final rect = Rect.fromCenter(
      center: center,
      width: size.width,
      height: size.height,
    );

    if (glow) {
      const outerBlue = Color.fromRGBO(0x42, 0xBE, 0xC2, 1.0);
      canvas.drawOval(
        rect,
        Paint()
          ..shader = ui.Gradient.radial(
            center,
            110,
            [
              Colors.transparent,
              outerBlue,
              outerBlue,
              Colors.transparent,
            ],
            [
              0.0,
              0.4,
              0.4,
              1.0,
            ],
            TileMode.decal,
          ),
      );
    }

    final whiteWidth = 12.0 + scale * 50;
    final whiteRatio = whiteWidth / size.longestSide;
    const innerBlue = Color.fromRGBO(0x56, 0xE6, 0xF5, 1.0);
    canvas.drawOval(
      rect,
      Paint()
        ..shader = ui.Gradient.radial(
          center,
          100,
          [
            Colors.transparent,
            Colors.transparent,
            innerBlue,
            Colors.white,
            Colors.white,
            innerBlue,
            Colors.transparent,
            Colors.transparent,
          ],
          [
            0.0,
            0.5 - whiteRatio / 4 - 0.05,
            0.5 - whiteRatio / 4 - 0.05,
            0.5 - whiteRatio / 4,
            0.5 + whiteRatio / 2,
            0.5 + whiteRatio / 2 + 0.05,
            0.5 + whiteRatio / 2 + 0.05,
            1.0,
          ],
          TileMode.decal,
        )
        ..strokeWidth = 10,
    );
  }

  @override
  bool shouldRepaint(covariant _CirclePainter oldDelegate) {
    return oldDelegate.x != x ||
        oldDelegate.y != y ||
        oldDelegate.scale != scale ||
        oldDelegate.angle != angle ||
        oldDelegate.glow != glow;
  }
}
