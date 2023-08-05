import 'package:flutter/material.dart';

class DragHandle extends StatelessWidget {
  final double width;
  final Color color;
  const DragHandle({
    super.key,
    this.width = 32,
    this.color = const Color.fromRGBO(0xCE, 0xCE, 0xCE, 1.0),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 4,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(2.5)),
          color: color,
        ),
      ),
    );
  }
}
