import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:openup/api/users/profile.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/home_button.dart';
import 'package:openup/widgets/male_female_connection_image.dart';
import 'package:openup/widgets/notification_banner.dart';
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

    final dateFormat = DateFormat('MM / dd / yyyy');

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
        Positioned(
          top: MediaQuery.of(context).padding.top,
          left: 0,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
              onPressed: Navigator.of(context).pop,
              icon: const Icon(Icons.arrow_back, size: 32),
            ),
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding:
                EdgeInsets.only(top: MediaQuery.of(context).padding.top + 12),
            child: Text(
              'meet people',
              style: Theming.of(context).text.large.copyWith(
                shadows: [
                  BoxShadow(
                    color: Theming.of(context).shadow,
                    spreadRadius: 0.0,
                    blurRadius: 32.0,
                  )
                ],
              ),
            ),
          ),
        ),
        const Positioned(
          right: 0,
          bottom: 255,
          width: 250,
          child: NotificationBanner(
            contents:
                'You will still have 48 hours to connect with this person in the Rekindle section if you decide not to now.',
          ),
        ),
        Positioned(
          bottom: 370,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(
                height: 100,
                child: MaleFemaleConnectionImage(
                  color: Color.fromARGB(0xFF, 0xAA, 0xDD, 0xED),
                ),
              ),
              Text(profile.name, style: Theming.of(context).text.headline),
              const SizedBox(height: 4),
              Text(
                dateFormat.format(DateTime.now()),
                style: Theming.of(context).text.subheading.copyWith(
                      fontWeight: FontWeight.w300,
                    ),
              ),
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'expires ',
                      style: Theming.of(context)
                          .text
                          .subheading
                          .copyWith(fontWeight: FontWeight.w300),
                    ),
                    TextSpan(
                      text: '2',
                      style: Theming.of(context).text.subheading.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    TextSpan(
                      text: ' days',
                      style: Theming.of(context)
                          .text
                          .subheading
                          .copyWith(fontWeight: FontWeight.w300),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
              const SizedBox(
                height: 16,
              ),
              Button(
                onPressed: () => _moveToNextScreen(context),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 2),
                  margin: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(30)),
                    boxShadow: [
                      BoxShadow(
                        color: Theming.of(context).shadow.withOpacity(0.2),
                        offset: const Offset(0.0, 4.0),
                        blurRadius: 4.0,
                      ),
                    ],
                    color: Theming.of(context).datingRed2,
                  ),
                  child: Text(
                    'skip',
                    style: Theming.of(context).text.body.copyWith(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
        Positioned(
          right: MediaQuery.of(context).padding.right + 16,
          bottom: MediaQuery.of(context).padding.bottom + 16,
          child: const HomeButton(
            color: Colors.white,
          ),
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
