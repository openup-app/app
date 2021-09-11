import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:openup/button.dart';
import 'package:openup/common.dart';
import 'package:openup/sign_up/input_area.dart';
import 'package:openup/sign_up/title_and_tagline.dart';
import 'package:openup/theming.dart';

class SignUpPage extends StatelessWidget {
  const SignUpPage({Key? key}) : super(key: key);

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
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          const Spacer(),
          const TitleAndTagline(),
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
            onPressed: () {},
          ),
          const SizedBox(height: 10),
          Button(
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('forgot info?'),
            ),
            onPressed: () {},
          ),
          SizedBox(
            height: 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Image.asset(
                  'assets/images/connection_female.png',
                  fit: BoxFit.fitHeight,
                ),
                Image.asset(
                  'assets/images/connection_male.png',
                  fit: BoxFit.fitHeight,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
