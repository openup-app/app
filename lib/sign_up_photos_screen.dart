import 'package:flutter/material.dart';
import 'package:openup/public_profile_edit_screen.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/male_female_connection_image.dart';
import 'package:openup/widgets/theming.dart';

class SignUpPhotosScreen extends StatefulWidget {
  const SignUpPhotosScreen({Key? key}) : super(key: key);

  @override
  State<SignUpPhotosScreen> createState() => _SignUpPhotosScreenState();
}

class _SignUpPhotosScreenState extends State<SignUpPhotosScreen> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: MediaQuery.of(context).padding.top + 32,
        ),
        Align(
          alignment: Alignment.center,
          child: Text(
            'Add a photo',
            style: Theming.of(context).text.body.copyWith(
                  color: const Color.fromRGBO(0x62, 0xCD, 0xE3, 1.0),
                  fontWeight: FontWeight.w400,
                  fontSize: 30,
                ),
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.center,
          child: Text(
            'You can add upto six pictures in your profile section',
            textAlign: TextAlign.center,
            style: Theming.of(context).text.body.copyWith(
                  color: const Color.fromRGBO(0x99, 0x99, 0x99, 1.0),
                  fontWeight: FontWeight.w400,
                  fontSize: 18,
                ),
          ),
        ),
        const Expanded(
          child: Center(
            child: PhotoGrid(
              horizontal: true,
            ),
          ),
        ),
        SignificantButton.pink(
          onPressed: () {
            Navigator.of(context).pushNamed('sign-up-audio-bio');
          },
          child: const Text('Continue'),
        ),
        const MaleFemaleConnectionImageApart(),
      ],
    );
  }
}
