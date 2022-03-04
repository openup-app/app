import 'package:flutter/material.dart';
import 'package:openup/widgets/back_button.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/male_female_connection_image.dart';
import 'package:openup/widgets/photo_grid.dart';
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          height: MediaQuery.of(context).padding.top + 32,
        ),
        Stack(
          alignment: Alignment.center,
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: BackIconButton(
                color: Colors.black,
              ),
            ),
            Text(
              'Add a photo',
              style: Theming.of(context).text.body.copyWith(
                    color: const Color.fromRGBO(0x62, 0xCD, 0xE3, 1.0),
                    fontWeight: FontWeight.w400,
                    fontSize: 30,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.center,
          child: Text(
            'You can add upto six pictures in your profile',
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
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: PhotoGrid(
                horizontal: true,
              ),
            ),
          ),
        ),
        SignificantButton.blue(
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
