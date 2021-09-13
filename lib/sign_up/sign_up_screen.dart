import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:openup/button.dart';
import 'package:openup/common.dart';
import 'package:openup/input_area.dart';
import 'package:openup/male_female_connection_image.dart';
import 'package:openup/sign_up/title_and_tagline.dart';
import 'package:openup/theming.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theming.of(context).friendBlue1,
            Theming.of(context).friendBlue2,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        top: true,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const TitleAndTagline(),
            const Spacer(),
            const InputArea(
              child: TextField(
                textAlign: TextAlign.center,
                decoration: InputDecoration.collapsed(
                  hintText: 'Phone number or email',
                ),
              ),
            ),
            const SizedBox(height: 20),
            const InputArea(
              child: TextField(
                textAlign: TextAlign.center,
                obscureText: true,
                decoration: InputDecoration.collapsed(
                  hintText: 'Password',
                ),
              ),
            ),
            const SizedBox(height: 20),
            const InputArea(
              child: TextField(
                textAlign: TextAlign.center,
                decoration: InputDecoration.collapsed(
                  hintText: 'Birthday',
                ),
              ),
            ),
            const SizedBox(height: 20),
            PrimaryButton.large(
              child: const Text('Send code'),
              onPressed: () =>
                  Navigator.of(context).pushNamed('phone-verification'),
            ),
            const SizedBox(height: 15),
            Button(
              child: const Text('forgot info?'),
              onPressed: () =>
                  Navigator.of(context).pushNamed('forgot-password'),
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
