import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openup/analytics/analytics.dart';
import 'package:openup/signup_tutorial1.dart';
import 'package:openup/widgets/back_button.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';

class SignupTutorial2 extends ConsumerStatefulWidget {
  const SignupTutorial2({
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<SignupTutorial2> createState() => _SignupTutorial2();
}

class _SignupTutorial2 extends ConsumerState<SignupTutorial2> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(0xF2, 0xF2, 0xF6, 1.0),
      resizeToAvoidBottomInset: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: MediaQuery.of(context).padding.top,
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.topCenter,
            child: Stack(
              alignment: Alignment.center,
              children: const [
                Align(
                  alignment: Alignment.centerLeft,
                  child: BackIconButton(
                    color: Colors.black,
                  ),
                ),
                Text(
                  'A Bad Photo Example',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                AspectRatio(
                  aspectRatio: 9 / 16,
                  child: Container(
                    clipBehavior: Clip.hardEdge,
                    margin: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.all(
                        Radius.circular(32),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color.fromRGBO(0x00, 0x00, 0x00, 0.1),
                          offset: Offset(0, 11),
                          blurRadius: 26,
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/tutorial_photo_bad.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: 210,
                    clipBehavior: Clip.hardEdge,
                    margin: const EdgeInsets.only(bottom: 48),
                    decoration: const BoxDecoration(
                      color: Color.fromRGBO(0x00, 0x00, 0x00, 0.25),
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                      boxShadow: [
                        BoxShadow(
                          offset: Offset(0, 3),
                          blurRadius: 11,
                          color: Color.fromRGBO(0x00, 0x00, 0x00, 0.1),
                        )
                      ],
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 27),
                        child: DefaultTextStyle(
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Row(
                                children: const [
                                  IconCircle(tick: false),
                                  SizedBox(width: 16),
                                  Text(
                                    'Off centered with no\ndepth',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: const [
                                  IconCircle(tick: false),
                                  SizedBox(width: 16),
                                  Text(
                                    'Can\'t tell who you\nare, too many people',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: const [
                                  IconCircle(tick: false),
                                  SizedBox(width: 16),
                                  Text(
                                    'Photo is poorly lit\nand blurry',
                                  ),
                                ],
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
          Button(
            onPressed: _submit,
            child: RoundedRectangleContainer(
              child: SizedBox(
                width: 171,
                height: 42,
                child: Center(
                  child: Text(
                    'Next',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium!
                        .copyWith(fontSize: 20, fontWeight: FontWeight.w400),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 36),
          SizedBox(
            height: MediaQuery.of(context).padding.bottom,
          ),
        ],
      ),
    );
  }

  void _submit() async {
    ref.read(mixpanelProvider).track("signup_submit_tutorial2");
    context.pushNamed('signup_photos');
  }
}
