import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openup/api/users/users_api.dart';
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
  void didChangeDependencies() {
    super.didChangeDependencies();

    final api = ref.read(usersApiProvider);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw 'No user is logged in';
    }

    FirebaseMessaging.instance.getToken().then((token) {
      if (token != null) api.updateNotificationToken(uid, token);
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
                onPressed: () =>
                    Navigator.of(context).pushNamed('dating-solo-double'),
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
                        child: Image.asset(
                          'assets/images/heart.gif',
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
                    Navigator.of(context).pushNamed('friends-solo-double'),
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
                      const SizedBox(height: 120),
                      Image.asset(
                        'assets/images/friends.gif',
                        height: 120,
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
