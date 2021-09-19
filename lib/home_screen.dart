import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:openup/button.dart';
import 'package:openup/male_female_connection_image.dart';
import 'package:openup/profile_button.dart';
import 'package:openup/theming.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    return Stack(
      children: [
        Row(
          children: [
            Expanded(
              child: Button(
                onPressed: () {},
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color.fromARGB(0xFF, 0xFF, 0x83, 0x83),
                        Theming.of(context).datingRed1,
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.only(left: 40),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'blind\ndating',
                          textAlign: TextAlign.left,
                          style: Theming.of(context).text.large,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 120,
                        child: Image.asset(
                          'assets/images/heart.png',
                          fit: BoxFit.fitHeight,
                        ),
                      ),
                      const SizedBox(height: 100),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Button(
                onPressed: () => Navigator.of(context).pushNamed('friends'),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Theming.of(context).friendBlue1,
                        Theming.of(context).friendBlue2,
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      const Spacer(),
                      const SizedBox(height: 120),
                      const SizedBox(
                        height: 120,
                        child: MaleFemaleConnectionImage(),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.only(left: 40),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'make\nfriends',
                          textAlign: TextAlign.left,
                          style: Theming.of(context).text.large,
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          right: MediaQuery.of(context).padding.right + 16,
          child: const ProfileButton(
            color: Color.fromARGB(0xFF, 0xFF, 0xAF, 0xAF),
          ),
        ),
      ],
    );
  }
}
