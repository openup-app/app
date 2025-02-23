import 'package:flutter/material.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/icon_with_shadow.dart';

class HomeButton extends StatelessWidget {
  final Color? color;
  const HomeButton({
    Key? key,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Button(
      onPressed: () => Navigator.popUntil(
        context,
        (route) => route.isFirst,
      ),
      child: SizedBox(
        width: 48,
        height: 48,
        child: IconWithShadow(
          Icons.home,
          size: 48.0,
          color: color ?? const Color.fromARGB(0xFF, 0x11, 0x8E, 0xDD),
        ),
      ),
    );
  }
}
