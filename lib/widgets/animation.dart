import 'package:flutter/material.dart';
import 'package:openup/util/noise.dart';
import 'package:openup/widgets/common.dart';

const _seed = 585384;

class WigglePosition extends StatefulWidget {
  final double frequency;
  final double amplitude;
  final int? seed;
  final Widget child;

  const WigglePosition({
    super.key,
    required this.frequency,
    required this.amplitude,
    this.seed,
    required this.child,
  });

  @override
  State<WigglePosition> createState() => _WigglePositionState();
}

class _WigglePositionState extends State<WigglePosition> {
  late final _noise = PerlinNoise(size: 2000, seed: widget.seed ?? _seed);
  late DateTime _start;

  @override
  void initState() {
    super.initState();
    _start = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return TickerBuilder(
      builder: (context) {
        final now = DateTime.now();
        final elapsed = now.difference(_start);
        final t = elapsed.inMilliseconds / 1000;
        final seedX = 481812 + (widget.seed ?? 0);
        final seedY = 117856 + (widget.seed ?? 0);
        final x = _noise.at(
          t,
          frequency: widget.frequency,
          amplitude: widget.amplitude,
          seed: seedX,
        );
        final y = _noise.at(
          t,
          frequency: widget.frequency,
          amplitude: widget.amplitude,
          seed: seedY,
        );
        return Transform.translate(
          offset: Offset(x, y),
          child: widget.child,
        );
      },
    );
  }
}

enum _RotationAxis { x, y, z }

class WiggleRotation extends StatefulWidget {
  final double frequency;
  final double amplitude;
  final _RotationAxis _axis;
  final int? seed;
  final Widget child;

  const WiggleRotation.x({
    super.key,
    required this.frequency,
    required this.amplitude,
    this.seed,
    required this.child,
  }) : _axis = _RotationAxis.x;

  const WiggleRotation.y({
    super.key,
    required this.frequency,
    required this.amplitude,
    this.seed,
    required this.child,
  }) : _axis = _RotationAxis.y;

  const WiggleRotation.z({
    super.key,
    required this.frequency,
    required this.amplitude,
    required this.child,
    this.seed,
  }) : _axis = _RotationAxis.z;

  @override
  State<WiggleRotation> createState() => _WiggleRotationState();
}

class _WiggleRotationState extends State<WiggleRotation> {
  late final _noise = PerlinNoise(size: 2000, seed: widget.seed ?? _seed);
  late DateTime _start;

  @override
  void initState() {
    super.initState();
    _start = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    const perspectiveDivide = 0.002;
    return TickerBuilder(
      builder: (context) {
        final now = DateTime.now();
        final elapsed = now.difference(_start);
        final t = elapsed.inMilliseconds / 1000;
        final angle = _noise.at(
          t,
          frequency: widget.frequency,
          amplitude: widget.amplitude,
        );
        final transform = Matrix4.identity()..setEntry(3, 2, perspectiveDivide);
        switch (widget._axis) {
          case _RotationAxis.x:
            transform.rotateX(angle);
          case _RotationAxis.y:
            transform.rotateY(angle);
          case _RotationAxis.z:
            transform.rotateZ(angle);
        }
        return Transform(
          transform: transform,
          alignment: Alignment.center,
          child: widget.child,
        );
      },
    );
  }
}
