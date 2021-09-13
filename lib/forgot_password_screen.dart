import 'package:flutter/material.dart';
import 'package:openup/common.dart';
import 'package:openup/input_area.dart';
import 'package:openup/male_female_connection_image.dart';
import 'package:openup/sign_up/title_and_tagline.dart';
import 'package:openup/theming.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theming.of(context).friendBlue1,
            Theming.of(context).friendBlue2,
          ],
        ),
      ),
      child: SafeArea(
        top: true,
        child: Column(
          children: [
            const TitleAndTagline(),
            const Spacer(),
            Text(
              'Enter new password',
              textAlign: TextAlign.center,
              style: Theming.of(context).text.subheading.copyWith(
                shadows: [
                  Shadow(
                    color: Theming.of(context).shadow,
                    blurRadius: 6,
                    offset: const Offset(0.0, 3.0),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const InputArea(
              child: TextField(
                textAlign: TextAlign.center,
                obscureText: true,
                decoration: InputDecoration.collapsed(
                  hintText: 'update password',
                ),
              ),
            ),
            const SizedBox(height: 20),
            const InputArea(
              child: TextField(
                textAlign: TextAlign.center,
                obscureText: true,
                decoration: InputDecoration.collapsed(
                  hintText: 'retype password',
                ),
              ),
            ),
            const SizedBox(height: 20),
            PrimaryButton.large(
              onPressed: () => Navigator.of(context).pushReplacementNamed('/'),
              child: const Text('Log in'),
            ),
            const Spacer(),
            const Hero(
              tag: 'male_female_connection',
              child: MaleFemaleConnectionImageApart(),
            ),
          ],
        ),
      ),
    );
  }
}
