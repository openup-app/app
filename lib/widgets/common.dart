import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/theming.dart';

/// Prominent button with a horizontal pink gradient styling, comes in three
/// sizes.
class PrimaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final BorderRadius borderRadius;
  final double height;

  const PrimaryButton.large({
    Key? key,
    required this.onPressed,
    required this.child,
  })  : borderRadius = const BorderRadius.all(Radius.circular(32)),
        height = 64.0,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Button(
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
                Theming.of(context).datingRed2,
                Theming.of(context).datingRed1,
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
      ),
    );
  }
}

/// Prominent button with an icon.
class PrimaryIconButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget icon;
  final Color color;
  final Widget child;

  const PrimaryIconButton({
    Key? key,
    required this.onPressed,
    required this.icon,
    required this.color,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Button(
      child: Container(
        height: 116,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(58)),
          boxShadow: [
            BoxShadow(
              color: Theming.of(context).shadow,
              offset: const Offset(0.0, 4.0),
              blurRadius: 12.0,
            ),
          ],
          color: color,
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Row(
            children: [
              const SizedBox(width: 8),
              SizedBox(
                width: 80,
                child: icon,
              ),
              const SizedBox(width: 8),
              Expanded(child: child),
            ],
          ),
        ),
      ),
      onPressed: onPressed,
    );
  }
}
