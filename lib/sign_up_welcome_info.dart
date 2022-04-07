import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/theming.dart';

class SignUpWelcomeInfoScreen extends ConsumerWidget {
  const SignUpWelcomeInfoScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProvider).profile!;
    final name = profile.name;
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
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
                Navigator.of(context).pushReplacementNamed('lobby-list');
              },
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
                      'Hey $name, moved somewhere new and want to make some friends? Then Openup is the perfect place for you! Openup is all about meeting new people for those who are having a hard time making new friends or connections in new areas.',
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
}
