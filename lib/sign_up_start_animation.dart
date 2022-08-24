import 'package:flutter/material.dart';
import 'package:openup/widgets/theming.dart';

class SignUpStartAnimationScreen extends StatefulWidget {
  const SignUpStartAnimationScreen({Key? key}) : super(key: key);

  @override
  State<SignUpStartAnimationScreen> createState() =>
      _SignUpStartAnimationScreenState();
}

class _SignUpStartAnimationScreenState extends State<SignUpStartAnimationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _controller.addListener(
      () {
        if (_controller.isCompleted) {
          Navigator.of(context).pushReplacementNamed('home');
        }
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final anim = CurvedAnimation(
      curve: Curves.easeOut,
      parent: _controller,
    );
    return GestureDetector(
      onTap: () {
        if (!_controller.isAnimating) {
          _controller.forward();
        }
      },
      child: Container(
        color: Colors.black,
        child: Center(
          child: AnimatedBuilder(
            animation: anim,
            builder: (context, _) {
              return Transform.scale(
                scale: 1 + anim.value * 100,
                child: Text(
                  'Welcome to\nopenup',
                  textAlign: TextAlign.center,
                  style: Theming.of(context)
                      .text
                      .body
                      .copyWith(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
