import 'package:flutter/material.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/input_area.dart';
import 'package:openup/widgets/male_female_connection_image.dart';
import 'package:openup/widgets/title_and_tagline.dart';
import 'package:openup/widgets/theming.dart';

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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 86),
            const TitleAndTagline(),
            const SizedBox(height: 10),
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
            const SizedBox(height: 22),
            InputArea(
              child: TextField(
                textAlign: TextAlign.center,
                obscureText: true,
                decoration: InputDecoration.collapsed(
                  hintText: 'update password',
                  hintStyle: Theming.of(context)
                      .text
                      .body
                      .copyWith(color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 22),
            InputArea(
              child: TextField(
                textAlign: TextAlign.center,
                obscureText: true,
                decoration: InputDecoration.collapsed(
                  hintText: 'retype password',
                  hintStyle: Theming.of(context)
                      .text
                      .body
                      .copyWith(color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 22),
            SignificantButton.pink(
              onPressed: () =>
                  Navigator.of(context).pushReplacementNamed('home'),
              child: const Text('Log in'),
            ),
            const SizedBox(
              height: 17 + 22 + 25 + 19,
            ),
            const Expanded(
              child: MaleFemaleConnectionImageApart(),
            ),
          ],
        ),
      ),
    );
  }
}
