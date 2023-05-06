import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
  final bokehBaseDuration = Duration(seconds: 16);
  final colorSet = [
    Color(0xff0361a4),
    Color(0xff018e6d),
    Color(0xff900005),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          AnimatedContainer(
            duration: Duration(seconds: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xff7b0420),
                  Color(0xff045471),
                  Color(0xff0262a3),
                ],
                stops: [0.0, 0.5, 1.0],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                transform: GradientRotation(-pi / 4),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xff006f8e),
                  Color(0xff8e000e),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: OverflowBox(
              maxWidth: double.infinity,
              maxHeight: double.infinity,
              child: Stack(
                children: List.generate(
                  bokehCount,
                  (index) => Positioned(
                    left: Random().nextDouble() * 100,
                    top: Random().nextDouble() * 100,
                    width: Random().nextDouble() * bokehBaseSize,
                    height: Random().nextDouble() * bokehBaseSize,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(1),
                        color: colorSet[Random().nextInt(colorSet.length)],
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black54,
                            blurRadius: Random().nextDouble() * 10 + 5,
                            spreadRadius: Random().nextDouble() * 2,
                          )
                        ],
                        filter: ColorFilter.mode(
                          Colors.white.withOpacity(
                            bokehBaseOpacity / 100 +
                                Random().nextDouble() * 0.8 * 0.15,
                          ),
                          BlendMode.modulate,
                        ),
                      ),
                      child: RotationTransition(
                        turns: AlwaysStoppedAnimation(1),
                        child: SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
