import 'package:flutter/material.dart';
import 'package:openup/widgets/back_button.dart';
import 'package:openup/widgets/button.dart';
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
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.fromRGBO(0x00, 0x51, 0x6E, 1.0),
            Color.fromRGBO(0x00, 0x00, 0x00, 1.0),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: MediaQuery.of(context).padding.top + 16,
            child: const BackIconButton(),
          ),
          Positioned(
            top: 80,
            left: 38,
            right: 8,
            child: Text(
              'Would you like to add pictures',
              style: Theming.of(context).text.body.copyWith(
                    fontWeight: FontWeight.w300,
                    fontSize: 32,
                  ),
            ),
          ),
          Positioned(
            top: 170,
            left: 38,
            right: 8,
            child: Text(
              'Adding pictures will increase your chances of meeting new people.',
              style: Theming.of(context).text.body.copyWith(
                    fontWeight: FontWeight.w300,
                    fontSize: 24,
                  ),
            ),
          ),
          const Positioned(
            top: 250,
            left: 8,
            right: 8,
            child: SizedBox(
              height: 340,
              child: PhotoGrid(
                horizontal: true,
                itemColor: Color.fromRGBO(0x00, 0x00, 0x00, 0.5),
              ),
            ),
          ),
          Positioned(
            right: 24,
            bottom: 24,
            child: Button(
              onPressed: () =>
                  Navigator.of(context).pushNamed('sign-up-welcome-info'),
              child: const Icon(Icons.chevron_right, size: 48),
            ),
          ),
        ],
      ),
    );
  }
}
