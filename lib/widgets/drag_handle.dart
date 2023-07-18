import 'package:flutter/material.dart';

class DragHandle extends StatelessWidget {
  const DragHandle({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 32,
      height: 4,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(2.5)),
          color: Color.fromRGBO(0xCE, 0xCE, 0xCE, 1.0),
        ),
      ),
    );
  }
}
