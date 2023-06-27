import 'dart:math';

import 'package:flutter/material.dart';

class SignupBackground extends StatefulWidget {
  final Widget child;

  const SignupBackground({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<SignupBackground> createState() => _SignupBackgroundState();
}

class _SignupBackgroundState extends State<SignupBackground> {
  final bokehCount = 40;
  final bokehBaseSize = 40.0;
  final bokehBaseOpacity = 20.0;
  final bokehBaseBrightness = 100.0;
  final bokehBaseDuration = const Duration(seconds: 16);
  final colorSet = const [
    Color(0xff0361a4),
    Color(0xff018e6d),
    Color(0xff900005),
  ];

  late final List<BokehValues> _bokeh;

  @override
  void initState() {
    super.initState();
    final r = Random();
    _bokeh = List.generate(bokehCount, (_) {
      return BokehValues(
        offset: Offset(r.nextDouble() * 100, r.nextDouble() * 100),
        size: Size(
          r.nextDouble() * bokehBaseSize,
          r.nextDouble() * bokehBaseSize,
        ),
        color: colorSet[r.nextInt(colorSet.length)],
        blurRadius: r.nextDouble() * 10 + 5,
        spreadRadius: r.nextDouble() * 2,
        opacity: bokehBaseOpacity / 100 + r.nextDouble() * 0.8 * 0.15,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xff006f8e),
              Color(0xff8e000e),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            widget.child,
          ],
        ),
      ),
    );
  }
}

class BokehValues {
  final Offset offset;
  final Size size;
  final Color color;
  final double blurRadius;
  final double spreadRadius;
  final double opacity;

  const BokehValues({
    required this.offset,
    required this.size,
    required this.color,
    required this.blurRadius,
    required this.spreadRadius,
    required this.opacity,
  });
}
