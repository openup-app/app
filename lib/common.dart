import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:openup/button.dart';
import 'package:openup/theming.dart';

/// Prominent button with a horizontal pink gradient styling, comes in three
/// sizes.
class PrimaryButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onPressed;
  final BorderRadius borderRadius;
  final double height;

  const PrimaryButton.large({
    Key? key,
    required this.child,
    required this.onPressed,
  })  : borderRadius = const BorderRadius.all(Radius.circular(30)),
        height = 60.0,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Button(
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: Theming.of(context).shadow,
              offset: const Offset(0.0, 4.0),
              blurRadius: 1.0,
            ),
          ],
          gradient: LinearGradient(
            colors: [
              Theming.of(context).datingRed1,
              Theming.of(context).datingRed2,
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
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
