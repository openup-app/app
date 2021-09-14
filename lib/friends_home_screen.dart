import 'package:flutter/material.dart';
import 'package:openup/button.dart';
import 'package:openup/home_button.dart';
import 'package:openup/male_female_connection_image.dart';
import 'package:openup/profile_button.dart';
import 'package:openup/theming.dart';

class FriendsHomeScreen extends StatelessWidget {
  const FriendsHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Button(
                onPressed: () =>
                    Navigator.of(context).pushNamed('friends-solo'),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        Theming.of(context).friendBlue1,
                        Theming.of(context).friendBlue2,
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        height: 115,
                        child: MaleFemaleConnectionImage(),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'meet\npeople',
                        textAlign: TextAlign.center,
                        style: Theming.of(context).text.headline,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Button(
                onPressed: () {},
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        Theming.of(context).friendBlue1,
                        Theming.of(context).friendBlue3,
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 100,
                        child: Image.asset(
                          'assets/images/friends_with_friends.png',
                          fit: BoxFit.fitHeight,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'meet people\nwith friends',
                        textAlign: TextAlign.center,
                        style: Theming.of(context).text.headline,
                      ),
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
            color: Theming.of(context).friendBlue4,
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
