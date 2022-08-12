import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/theming.dart';

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
      onPressed: onPressed,
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
    );
  }
}

class BlurredSurface extends StatelessWidget {
  final Widget child;
  const BlurredSurface({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const blur = 75.0;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: child,
      ),
    );
  }
}

class RecordButton extends StatelessWidget {
  final String label;
  const RecordButton({
    Key? key,
    required this.label,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Button(
      onPressed: () {},
      child: Container(
        height: 67,
        decoration: BoxDecoration(
          border:
              Border.all(color: const Color.fromRGBO(0xA9, 0xA9, 0xA9, 1.0)),
          borderRadius: const BorderRadius.all(
            Radius.circular(40),
          ),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white),
                  shape: BoxShape.circle,
                ),
                child: Container(
                  decoration: const BoxDecoration(
                      color: Colors.red, shape: BoxShape.circle),
                ),
              ),
              const SizedBox(width: 14),
              Text(
                label,
                style: Theming.of(context)
                    .text
                    .body
                    .copyWith(fontSize: 20, fontWeight: FontWeight.w300),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onSelected;
  const Chip({
    Key? key,
    required this.label,
    required this.selected,
    this.onSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Button(
      onPressed: onSelected,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? Colors.white
              : const Color.fromRGBO(0x77, 0x77, 0x77, 1.0),
          borderRadius: const BorderRadius.all(Radius.circular(50)),
          border: selected
              ? null
              : Border.all(
                  color: const Color.fromRGBO(0xB9, 0xB9, 0xB9, 1.0),
                ),
        ),
        child: Text(
          label,
          style: Theming.of(context).text.body.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w300,
              color: selected ? Colors.black : null),
        ),
      ),
    );
  }
}
