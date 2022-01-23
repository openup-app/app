import 'package:firebase_auth/firebase_auth.dart' hide UserMetadata;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openup/api/users/users_api.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/theming.dart';

import 'api/users/user_metadata.dart';

class SignUpWelcomeInfoScreen extends ConsumerWidget {
  const SignUpWelcomeInfoScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.fromRGBO(0xFF, 0x8E, 0x8E, 0.9),
            Color.fromRGBO(0xBD, 0x20, 0x20, 0.66),
          ],
        ),
        boxShadow: [
          const BoxShadow(
            offset: Offset(0, 2),
            blurRadius: 11,
            blurStyle: BlurStyle.inner,
          ),
          Theming.of(context).boxShadow,
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: MediaQuery.of(context).padding.top + 32,
            right: 34,
            width: 57,
            height: 57,
            child: Button(
              onPressed: () => _setOnBoardedTrueAndNavigateHome(context, ref),
              child: Image.asset('assets/images/close_circle.png'),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Welcome to Openup!',
                  style: Theming.of(context)
                      .text
                      .body
                      .copyWith(fontSize: 36, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 54),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 357),
                    child: Text(
                      'Hey “user” on openup there are two things we focused on, creating online blind dating and making friends online!  You can do either a phone call or video call, give it a try! Thank you for joining our app :)',
                      style: Theming.of(context).text.body.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          height: 1.7),
                    ),
                  ),
                ),
                const SizedBox(height: 54),
                Text(
                  '- openup',
                  style: Theming.of(context)
                      .text
                      .body
                      .copyWith(fontSize: 36, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _setOnBoardedTrueAndNavigateHome(
      BuildContext context, WidgetRef ref) async {
    await Firebase.initializeApp();
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;
    final uid = user?.uid;

    if (uid == null) {
      throw 'No user is logged in';
    }

    final usersApi = ref.read(usersApiProvider);

    final userMetadata = usersApi.userMetadata?.copyWith(onboarded: true) ??
        const UserMetadata(onboarded: true);

    usersApi.updateUserMetadata(
      uid,
      userMetadata,
    );

    Navigator.of(context).popUntil((route) => route.isFirst);
    Navigator.of(context).pushReplacementNamed('home');
  }
}
