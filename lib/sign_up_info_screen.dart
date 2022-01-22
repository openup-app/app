import 'package:flutter/material.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/male_female_connection_image.dart';
import 'package:openup/widgets/theming.dart';

class SignUpInfoScreen extends StatelessWidget {
  const SignUpInfoScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Who are you?',
              style: Theming.of(context).text.body.copyWith(
                    color: const Color.fromRGBO(0x62, 0xCD, 0xE3, 1.0),
                    fontWeight: FontWeight.w400,
                    fontSize: 48,
                  ),
            ),
            const SizedBox(height: 28),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 350),
              child: Text(
                'Openup is about building real connections in a real way.  Please respond to the following information to help those wanting to find someone like you, find you',
                textAlign: TextAlign.center,
                style: Theming.of(context).text.body.copyWith(
                      color: const Color.fromRGBO(0x99, 0x99, 0x99, 1.0),
                      fontWeight: FontWeight.w400,
                      fontSize: 18,
                    ),
              ),
            ),
            const SizedBox(height: 24),
            SignificantButton.blue(
              onPressed: () =>
                  Navigator.of(context).pushNamed('sign-up-private-profile'),
              child: const Text('Continue'),
            ),
          ],
        ),
        const Align(
          alignment: Alignment.bottomCenter,
          child: MaleFemaleConnectionImageApart(),
        ),
      ],
    );
  }
}
