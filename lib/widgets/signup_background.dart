import 'package:flutter/material.dart';

const _kAssetImage = 'assets/images/signup_background.jpg';

class SignupBackground extends StatelessWidget {
  final Widget child;

  const SignupBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          _kAssetImage,
          fit: BoxFit.cover,
        ),
        child,
      ],
    );
  }

  static precache(BuildContext context) =>
      precacheImage(const AssetImage(_kAssetImage), context);
}
