import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:openup/widgets/back_button.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/invite_friends.dart';

class SignUpFriends extends StatefulWidget {
  const SignUpFriends({super.key});

  @override
  State<SignUpFriends> createState() => _SignUpFriendsState();
}

class _SignUpFriendsState extends State<SignUpFriends> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/signup_background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.only(
                    top: 72 + MediaQuery.of(context).padding.top),
                child: const InviteFriends(),
              ),
            ),
            Container(
              height: 72 + MediaQuery.of(context).padding.top,
              color: Colors.black.withOpacity(0.2),
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 13, sigmaY: 13),
                  child: Padding(
                    padding: EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top + 24),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: BackIconButton(),
                          ),
                          Text(
                            'Add friends',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                    fontSize: 16, fontWeight: FontWeight.w400),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Button(
                              onPressed: () {
                                context.goNamed(
                                  'discover',
                                  queryParams: {'welcome': 'true'},
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  'Next',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium!
                                      .copyWith(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w400),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
