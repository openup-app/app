import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:openup/widgets/button.dart';

/// Prominent button with a horizontal gradient styling.
class SignificantButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final BorderRadius borderRadius;
  final double height;
  final Gradient gradient;

  const SignificantButton({
    Key? key,
    required this.onPressed,
    required this.gradient,
    required this.child,
  })  : borderRadius = const BorderRadius.all(Radius.circular(94)),
        height = 69.0,
        super(key: key);

  const SignificantButton.pink({
    Key? key,
    required this.onPressed,
    required this.child,
  })  : borderRadius = const BorderRadius.all(Radius.circular(94)),
        height = 69.0,
        gradient = const LinearGradient(
          colors: [
            Color.fromRGBO(0xFF, 0x83, 0x83, 1.0),
            Color.fromRGBO(0x8A, 0x0, 0x00, 1.0),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        super(key: key);

  const SignificantButton.blue({
    Key? key,
    required this.onPressed,
    required this.child,
  })  : borderRadius = const BorderRadius.all(Radius.circular(94)),
        height = 69.0,
        gradient = const LinearGradient(
          colors: [
            Color.fromRGBO(0x26, 0xC4, 0xE6, 1.0),
            Color.fromRGBO(0x7B, 0xDC, 0xF1, 1.0),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Button(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 300),
        height: height,
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          gradient: gradient,
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Center(child: child),
        ),
      ),
      onPressed: onPressed,
    );
  }
}
