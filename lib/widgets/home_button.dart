import 'package:flutter/material.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/theming.dart';

class HomeButton extends StatelessWidget {
  const HomeButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Button(
      onPressed: () => Navigator.popUntil(
        context,
        ModalRoute.withName('/'),
      ),
      child: SizedBox(
        width: 48,
        height: 48,
        child: Icon(
          Icons.home,
          size: 48.0,
          color: Theming.of(context).friendBlue4,
        ),
      ),
    );
  }
}
