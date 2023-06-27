import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openup/analytics/analytics.dart';
import 'package:openup/widgets/back_button.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';

class SignupTutorial1 extends ConsumerStatefulWidget {
  const SignupTutorial1({
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<SignupTutorial1> createState() => _SignupTutorial1();
}

class _SignupTutorial1 extends ConsumerState<SignupTutorial1> {
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
                  'A Good Photo to help\nmake great connections',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
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
                    'assets/images/tutorial_photo_good.jpg',
                    fit: BoxFit.cover,
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
                                  IconCircle(tick: true),
                                  SizedBox(width: 16),
                                  Text(
                                    'You are center\nframed and smiling',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: const [
                                  IconCircle(tick: true),
                                  SizedBox(width: 16),
                                  Text(
                                    'Alone in portrait and\nfocused in depth',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: const [
                                  IconCircle(tick: true),
                                  SizedBox(width: 16),
                                  Text(
                                    'Photos are well lit,\nsharp and in color',
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
    ref.read(mixpanelProvider).track("signup_submit_tutorial1");
    context.pushNamed('signup_tutorial2');
  }
}

class IconCircle extends StatelessWidget {
  final bool tick;

  const IconCircle({
    super.key,
    required this.tick,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(width: 2, color: Colors.white),
        shape: BoxShape.circle,
        color: tick
            ? const Color.fromRGBO(0x2D, 0xDA, 0x01, 1.0)
            : const Color.fromRGBO(0xFF, 0x00, 0x00, 1.0),
        boxShadow: const [
          BoxShadow(
            offset: Offset(0, 2),
            blurRadius: 4,
            color: Color.fromRGBO(0x00, 0x00, 0x00, 0.15),
          ),
        ],
      ),
      child: tick
          ? const Icon(
              Icons.done,
              size: 20,
            )
          : const Icon(
              Icons.close,
              size: 18,
            ),
    );
  }
}
