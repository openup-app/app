import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:openup/widgets/animation.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

class WobblyRings extends StatefulWidget {
  final double scale;
  final double? radius;
  final double thickness;

  const WobblyRings({
    super.key,
    this.scale = 1,
    this.radius,
    this.thickness = 12,
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
    final radius = widget.radius;
    return Stack(
      textDirection: TextDirection.ltr,
      alignment: Alignment.center,
      fit: radius == null ? StackFit.expand : StackFit.loose,
      children: [
        for (var i = 3; i >= 0; i--)
          Builder(
            builder: (context) {
              final delay = Duration(milliseconds: ((i / 3) * 300).toInt());
              return Opacity(
                opacity: 1 - i / 4,
                child: Transform.scale(
                  scale: 1 - i / 9,
                  child: WiggleBuilder(
                    seed: _baseSeed,
                    builder: (context, child, wiggle) {
                      final x = wiggle(
                        frequency: 1.5,
                        amplitude: 1.5,
                        delay: delay,
                      );
                      final y = wiggle(
                        frequency: 1.5,
                        amplitude: 1.5,
                        delay: delay,
                      );
                      final angle = wiggle(
                        frequency: 0.4,
                        amplitude: radians(360),
                        delay: delay,
                      );
                      return TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutQuart,
                        tween: Tween(begin: 1, end: widget.scale),
                        builder: (context, value, child) {
                          return CustomPaint(
                            size: radius == null
                                ? Size.zero
                                : Size.square(radius),
                            painter: _CirclePainter(
                              x: 1 + x * 0.1,
                              y: 1 + y * 0.1,
                              scale: value,
                              angle: angle,
                              thickness: widget.thickness,
                              glow: i == 0,
                            ),
                          );
                        },
                      );
                    },
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
  final double thickness;
  final bool glow;

  _CirclePainter({
    required this.x,
    required this.y,
    required this.scale,
    required this.angle,
    required this.thickness,
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
    final radius = size.shortestSide / 2;
    final rect = Rect.fromCenter(
      center: center,
      width: radius * 2,
      height: radius * 2,
    );

    if (glow) {
      const outerBlue = Color.fromRGBO(0x42, 0xBE, 0xC2, 1.0);
      final glowRadius = radius * 0.9;
      canvas.drawOval(
        Rect.fromCircle(
          center: center,
          radius: glowRadius,
        ),
        Paint()
          ..shader = ui.Gradient.radial(
            center,
            glowRadius,
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

    const whiteRatio = 0.5;
    final scaledThickness = thickness + scale * 0.25;
    final ringRatioOfRect = scaledThickness / radius;
    const innerBlue = Color.fromRGBO(0x56, 0xE6, 0xF5, 1.0);
    canvas.drawOval(
      rect,
      Paint()
        ..shader = ui.Gradient.radial(
          center,
          radius,
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
            0.5 - ringRatioOfRect * 1 / 2,
            0.5 - ringRatioOfRect * 1 / 2,
            0.5 - ringRatioOfRect * whiteRatio / 2,
            0.5 + ringRatioOfRect * whiteRatio / 2,
            0.5 + ringRatioOfRect * 1 / 2,
            0.5 + ringRatioOfRect * 1 / 2,
            1.0,
          ],
          TileMode.decal,
        ),
    );
  }

  @override
  bool shouldRepaint(covariant _CirclePainter oldDelegate) {
    return oldDelegate.x != x ||
        oldDelegate.y != y ||
        oldDelegate.scale != scale ||
        oldDelegate.angle != angle ||
        oldDelegate.thickness != thickness ||
        oldDelegate.glow != glow;
  }
}
