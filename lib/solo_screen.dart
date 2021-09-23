import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:openup/common.dart';
import 'package:openup/lobby_screen.dart';
import 'package:openup/home_button.dart';
import 'package:openup/male_female_connection_image.dart';
import 'package:openup/preferences.dart';
import 'package:openup/profile_button.dart';
import 'package:openup/theming.dart';
import 'package:openup/toggle_button.dart';

class SoloFriends extends StatelessWidget {
  const SoloFriends({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    final buttonStyle = Theming.of(context).text.bodySecondary.copyWith(
      shadows: [
        BoxShadow(
          color: Colors.black.withOpacity(0.4),
          blurRadius: 16.0,
          offset: const Offset(0.0, 2.0),
        ),
      ],
    );
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white,
            Color.fromARGB(0xFF, 0xDD, 0xFB, 0xFF),
          ],
        ),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(),
                Text(
                  'meet people',
                  style: Theming.of(context).text.headline.copyWith(
                    color: const Color.fromARGB(0xFF, 0x00, 0xD1, 0xFF),
                    shadows: [
                      const BoxShadow(
                        color: Color.fromARGB(0xAA, 0x00, 0xD1, 0xFF),
                        spreadRadius: 2.0,
                        blurRadius: 16.0,
                        offset: Offset(0.0, 2.0),
                      )
                    ],
                  ),
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
                          ToggleButton(
                            value: true,
                            onChanged: (_) {},
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'casual',
                            style: TextStyle(
                              color: Color.fromARGB(0xFF, 0x8B, 0xC0, 0xFF),
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ],
                ),
                PrimaryIconButton(
                  onPressed: () => Navigator.of(context).pushNamed(
                    'friends-lobby',
                    arguments: LobbyScreenArguments(video: false),
                  ),
                  icon: Image.asset('assets/images/voice_call.png'),
                  color: const Color.fromARGB(0xFF, 0x00, 0xB0, 0xD7),
                  child: Text(
                    'Talk to someone new',
                    style: buttonStyle,
                  ),
                ),
                const SizedBox(height: 20),
                PrimaryIconButton(
                  onPressed: () => Navigator.of(context).pushNamed(
                    'friends-lobby',
                    arguments: LobbyScreenArguments(video: true),
                  ),
                  icon: Image.asset('assets/images/video_call.png'),
                  color: const Color.fromARGB(0xFF, 0x5A, 0xC9, 0xEC),
                  child: Text(
                    'Video call someone new',
                    style: buttonStyle,
                  ),
                ),
                const SizedBox(height: 20),
                PrimaryIconButton(
                  onPressed: () async {
                    final _ = await Navigator.of(context)
                        .pushNamed<Preferences>('friends-preferences');
                  },
                  icon: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Image.asset('assets/images/preferences.png'),
                  ),
                  color: const Color.fromARGB(0xFF, 0x8C, 0xDD, 0xF6),
                  child: Text(
                    'Preferences',
                    style: buttonStyle,
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
      ),
    );
  }
}
