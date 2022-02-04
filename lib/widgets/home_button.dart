import 'package:flutter/material.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/icon_with_shadow.dart';
import 'package:openup/widgets/theming.dart';

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
        ModalRoute.withName('home'),
      ),
      child: SizedBox(
        width: 48,
        height: 48,
        child: IconWithShadow(
          Icons.home,
          size: 48.0,
          color: color ?? Theming.of(context).friendBlue4,
        ),
      ),
    );
  }
}
