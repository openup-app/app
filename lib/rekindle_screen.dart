import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:openup/api/users/profile.dart';
import 'package:openup/widgets/slide_control.dart';
import 'package:openup/widgets/theming.dart';

class RekindleScreen extends StatelessWidget {
  final List<PublicProfile> profiles;
  final int index;
  const RekindleScreen({
    Key? key,
    required this.profiles,
    required this.index,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final profile = profiles[index];
    String? photo;
    try {
      photo = profile.gallery.first;
    } on StateError {
      // Nothing to do
    }

    return Stack(
      alignment: Alignment.center,
      fit: StackFit.expand,
      children: [
        ImageFiltered(
          imageFilter: ImageFilter.blur(
            sigmaX: 8.0,
            sigmaY: 8.0,
          ),
          child: photo != null
              ? Image.network(
                  photo,
                  fit: BoxFit.cover,
                )
              : Image.asset(
                  'assets/images/profile.png',
                  fit: BoxFit.fitHeight,
                ),
        ),
        Container(
          color: const Color.fromARGB(0x4F, 0x3F, 0xC8, 0xFD),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Spacer(),
            const Spacer(),
            Text(profile.name, style: Theming.of(context).text.headline),
            Text('2/18/2020', style: Theming.of(context).text.subheading),
            Text('expires 2 days', style: Theming.of(context).text.subheading),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SlideControl(
                thumbContents: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      '5',
                      style: Theming.of(context).text.headline.copyWith(
                          fontSize: 42,
                          fontWeight: FontWeight.w800,
                          color: Colors.grey),
                    ),
                  ),
                ),
                trackContents: const Text('slide to connect'),
                onSlideComplete: () => _moveToNextScreen(context),
                trackBorder: true,
                trackGradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.fromARGB(0xBF, 0x86, 0xCA, 0xE7),
                    Color.fromARGB(0xBF, 0x03, 0x78, 0xA5),
                  ],
                ),
              ),
            ),
            TextButton(
              onPressed: () => _moveToNextScreen(context),
              child: const Text('Skip'),
            ),
            const Spacer(),
          ],
        ),
      ],
    );
  }

  void _moveToNextScreen(BuildContext context) {
    if (index + 1 < profiles.length) {
      Navigator.of(context).pushReplacementNamed(
        'rekindle',
        arguments: RekindleScreenArguments(
          profiles: profiles,
          index: index + 1,
        ),
      );
    } else {
      Navigator.of(context).pop();
    }
  }
}

class RekindleScreenArguments {
  final List<PublicProfile> profiles;
  final int index;

  RekindleScreenArguments({
    required this.profiles,
    required this.index,
  });
}
