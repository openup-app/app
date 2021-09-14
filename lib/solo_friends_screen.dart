import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:openup/common.dart';
import 'package:openup/home_button.dart';
import 'package:openup/male_female_connection_image.dart';
import 'package:openup/profile_button.dart';
import 'package:openup/theming.dart';

class SoloFriends extends StatelessWidget {
  const SoloFriends({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              Text(
                'meet people',
                style: Theming.of(context)
                    .text
                    .headline
                    .copyWith(color: Theming.of(context).friendBlue2),
              ),
              const SizedBox(height: 40),
              Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  const SizedBox(
                    height: 115,
                    child: MaleFemaleConnectionImage(),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Column(
                      children: [
                        Switch(
                          value: true,
                          onChanged: (_) {},
                        ),
                        Text(
                          'casual',
                          style: TextStyle(
                            color: Theming.of(context).friendBlue3,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ],
              ),
              PrimaryIconButton(
                onPressed: () =>
                    Navigator.of(context).pushNamed('friends-lobby'),
                icon: Image.asset('assets/images/voice_call.png'),
                color: const Color.fromARGB(0xFF, 0x00, 0xB0, 0xD7),
                child: Text(
                  'Talk to someone new',
                  style: Theming.of(context).text.bodySecondary,
                ),
              ),
              const SizedBox(height: 20),
              PrimaryIconButton(
                onPressed: () =>
                    Navigator.of(context).pushNamed('friends-lobby'),
                icon: Image.asset('assets/images/video_call.png'),
                color: const Color.fromARGB(0xFF, 0x5A, 0xC9, 0xEC),
                child: Text(
                  'Video call someone new',
                  style: Theming.of(context).text.bodySecondary,
                ),
              ),
              const SizedBox(height: 20),
              PrimaryIconButton(
                onPressed: () {},
                icon: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Image.asset('assets/images/preferences.png'),
                ),
                color: const Color.fromARGB(0xFF, 0x8C, 0xDD, 0xF6),
                child: Text(
                  'Preferences',
                  style: Theming.of(context).text.bodySecondary,
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          right: MediaQuery.of(context).padding.right + 16,
          child: ProfileButton(
            color: Theming.of(context).friendBlue2,
          ),
        ),
        Positioned(
          right: MediaQuery.of(context).padding.right + 16,
          bottom: MediaQuery.of(context).padding.bottom + 16,
          child: const HomeButton(),
        ),
      ],
    );
  }
}
