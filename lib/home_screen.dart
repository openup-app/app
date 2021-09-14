import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:openup/button.dart';
import 'package:openup/male_female_connection_image.dart';
import 'package:openup/profile_button.dart';
import 'package:openup/theming.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                        Theming.of(context).datingRed2,
                        Theming.of(context).datingRed1,
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      const Spacer(),
                      SizedBox(
                        child: Text(
                          'blind\ndating',
                          textAlign: TextAlign.center,
                          style: Theming.of(context).text.headline,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 100,
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
                        height: 100,
                        child: MaleFemaleConnectionImage(),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 100,
                        child: Text(
                          'make\nfriends',
                          textAlign: TextAlign.center,
                          style: Theming.of(context).text.headline,
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
          child: ProfileButton(
            color: Theming.of(context).datingRed1,
          ),
        ),
      ],
    );
  }
}
