import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SignupBackground extends StatefulWidget {
  final Widget child;

  const SignupBackground({
    super.key,
    required this.child,
  });

  @override
  State<SignupBackground> createState() => _SignupBackgroundState();
}

class _SignupBackgroundState extends State<SignupBackground> {
  static const _count = 7;
  final _alignments = List.generate(_count, (index) => Alignment.center);
  late final List<Timer> _timers;

  @override
  void initState() {
    super.initState();

    final r = Random();
    // Set all elements to a random position from -1 to 1 in x and y
    for (var i = 0; i < _count; i++) {
      final a = Alignment(r.nextDouble() * 2 - 1, r.nextDouble() * 2 - 1);
      setState(() => _alignments[i] = a);
    }

    _timers = List.generate(_count, (i) {
      // Randomly change direction every 1 to 2 seconds
      final time = const Duration(seconds: 1) +
          Duration(milliseconds: (1000 * r.nextDouble()).toInt());
      return Timer.periodic(
        time,
        (_) {
          // Set a new random target position for all elements
          final a = Alignment(r.nextDouble() * 2 - 1, r.nextDouble() * 2 - 1);
          setState(() => _alignments[i] = a);
        },
      );
    });
  }

  @override
  void dispose() {
    _timers.forEach((timer) => timer.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const blur = 100.0;
    return Stack(
      fit: StackFit.expand,
      children: [
        ImageFiltered(
          imageFilter: ImageFilter.blur(
            sigmaX: blur,
            sigmaY: blur,
            tileMode: TileMode.mirror,
          ),
          child: Stack(
            children: [
              const Positioned.fill(
                child: ColoredBox(
                  color: Colors.black,
                ),
              ),
              for (var i = 0; i < _count; i++)
                AnimatedAlign(
                  duration: const Duration(milliseconds: 5000),
                  curve: Curves.easeOut,
                  alignment: _alignments[i],
                  child: SvgPicture.asset(
                    'assets/images/signup_background/$i.svg',
                  ),
                ),
            ],
          ),
        ),
        widget.child,
      ],
    );
  }
}
