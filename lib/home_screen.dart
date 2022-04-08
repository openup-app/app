import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:lottie/lottie.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/notifications/connectycube_call_kit_integration.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/profile_button.dart';
import 'package:openup/widgets/theming.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.wait([
      FirebaseMessaging.instance.getToken(),
      getVoipPushNotificationToken(),
    ]).then((tokens) {
      if (!mounted) {
        return;
      }
      final api = GetIt.instance.get<Api>();
      api.addNotificationTokens(
        ref.read(userProvider).uid,
        messagingToken: tokens[0],
        voipToken: tokens[1],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Row(
          children: [
            Expanded(
              child: Button(
                onPressed: () => Navigator.of(context).pushNamed('dating-solo'),
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color.fromRGBO(0xFF, 0x83, 0x83, 1.0),
                        Color.fromRGBO(0xFF, 0xC8, 0xC8, 1.0),
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
                        height: 140,
                        child: Lottie.asset(
                          'assets/images/heart.json',
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
                onPressed: () =>
                    Navigator.of(context).pushNamed('friends-solo'),
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color.fromRGBO(0xB7, 0xF2, 0xFF, 1.0),
                        Color.fromRGBO(0x00, 0xB9, 0xE2, 1.0),
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      const Spacer(),
                      const SizedBox(height: 100),
                      Lottie.asset(
                        'assets/images/friends.json',
                        height: 140,
                      ),
                      const SizedBox(height: 16),
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
