import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openup/api/users/users_api.dart';
import 'package:openup/notifications/notifications.dart';
import 'package:openup/widgets/back_button.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/home_button.dart';
import 'package:openup/widgets/theming.dart';

class AccountSettingsScreen extends ConsumerWidget {
  const AccountSettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: Colors.black),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromRGBO(0xFF, 0x8E, 0x8E, 1.0),
              Color.fromRGBO(0x20, 0x84, 0xBD, 0.74),
            ],
          ),
        ),
        child: Stack(
          fit: StackFit.loose,
          children: [
            Positioned(
              top: MediaQuery.of(context).padding.top + 24,
              left: 8,
              child: Transform.scale(
                scale: 1.3,
                child: const BackIconButton(),
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 362),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        Center(
                          child: Text(
                            'Account Settings',
                            style: Theming.of(context).text.body.copyWith(
                                fontSize: 30, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const Spacer(),
                        Center(
                          child: Text(
                            'Enter old information',
                            style: Theming.of(context).text.body.copyWith(
                                fontSize: 18, fontWeight: FontWeight.w500),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const _InputArea(
                          child: _TextField(
                            hintText: 'enter old phone number',
                          ),
                        ),
                        const SizedBox(height: 24),
                        Center(
                          child: Text(
                            'Update login information',
                            style: Theming.of(context).text.body.copyWith(
                                fontSize: 18, fontWeight: FontWeight.w500),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const _InputArea(
                          child: _TextField(
                            hintText: 'phone number',
                          ),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: 237,
                          child: Button(
                            onPressed: () {},
                            child: _InputArea(
                              childNeedsOpacity: false,
                              opacity: 0.8,
                              gradientColors: const [
                                Color.fromRGBO(0xFF, 0x3B, 0x3B, 0.65),
                                Color.fromRGBO(0xFF, 0x33, 0x33, 0.54),
                              ],
                              child: Center(
                                child: Text(
                                  'Update Information',
                                  style: Theming.of(context).text.body.copyWith(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Button(
                          onPressed: () =>
                              Navigator.of(context).pushNamed('contact-us'),
                          child: _InputArea(
                            childNeedsOpacity: false,
                            child: Row(
                              children: [
                                const SizedBox(width: 16),
                                DecoratedBox(
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color:
                                        Color.fromRGBO(0xC4, 0xC4, 0xC4, 1.0),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: Text(
                                      '?',
                                      textAlign: TextAlign.center,
                                      style: Theming.of(context)
                                          .text
                                          .body
                                          .copyWith(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Contact us',
                                  style: Theming.of(context).text.body.copyWith(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(flex: 2),
                        Container(
                          color: Colors.white,
                          margin: const EdgeInsets.symmetric(horizontal: 40.0),
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  OutlinedButton(
                                    onPressed: () async {
                                      final usersApi =
                                          ref.read(usersApiProvider);
                                      final uid = FirebaseAuth
                                          .instance.currentUser?.uid;
                                      if (uid != null) {
                                        await dismissAllNotifications();
                                        await usersApi.deleteUser(uid);
                                        await FirebaseAuth.instance.signOut();
                                        Navigator.of(context)
                                            .pushReplacementNamed('/');
                                      }
                                    },
                                    child: const Text('Delete account'),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton(
                                    onPressed: () async {
                                      await dismissAllNotifications();
                                      await FirebaseAuth.instance.signOut();
                                      Navigator.of(context)
                                          .pushReplacementNamed('/');
                                    },
                                    child: const Text('Sign-out'),
                                  ),
                                ],
                              ),
                              Text('${FirebaseAuth.instance.currentUser?.uid}'),
                              Text(
                                  '${FirebaseAuth.instance.currentUser?.phoneNumber}'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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
        ),
      ),
    );
  }
}

class _InputArea extends StatelessWidget {
  final Widget child;
  final List<Color> gradientColors;
  final double opacity;
  final bool childNeedsOpacity;
  const _InputArea({
    Key? key,
    required this.child,
    this.gradientColors = const [
      Color.fromRGBO(0xFF, 0xFF, 0xFF, 0.65),
      Color.fromRGBO(0xFF, 0xFF, 0xFF, 0.54),
    ],
    this.opacity = 0.6,
    this.childNeedsOpacity = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 57,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Opacity(
            opacity: opacity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: gradientColors,
                ),
                borderRadius: const BorderRadius.all(Radius.circular(29)),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(0x00, 0x00, 0x00, 0.25),
                    offset: Offset(0.0, 4.0),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: childNeedsOpacity ? child : null,
            ),
          ),
          if (!childNeedsOpacity) child,
        ],
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  final String hintText;
  const _TextField({
    Key? key,
    required this.hintText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(left: 24.0),
        child: TextField(
          decoration: InputDecoration.collapsed(
            hintText: hintText,
            hintStyle: Theming.of(context).text.body.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
          ),
        ),
      ),
    );
  }
}
