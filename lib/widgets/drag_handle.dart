import 'package:flutter/material.dart';

class DragHandle extends StatelessWidget {
  final double width;
  final Color color;
  final BoxShadow? shadow;
  const DragHandle({
    super.key,
    this.width = 32,
    this.color = const Color.fromRGBO(0xB4, 0xB4, 0xB4, 1.0),
    this.shadow,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 5,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(2.5)),
          color: color,
          boxShadow: shadow != null ? [shadow!] : null,
        ),
      ),
    );
  }
}
