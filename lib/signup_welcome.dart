import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openup/widgets/back_button.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/policies.dart';
import 'package:openup/widgets/signup_background.dart';

class SignupWelcome extends ConsumerStatefulWidget {
  const SignupWelcome({Key? key}) : super(key: key);

  @override
  ConsumerState<SignupWelcome> createState() => _SignUpWelcomeScreenState();
}

class _SignUpWelcomeScreenState extends ConsumerState<SignupWelcome> {
  @override
  Widget build(BuildContext context) {
    return SignupBackground(
      child: Stack(
        children: [
          SizedBox(
            height: MediaQuery.of(context).padding.top,
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: context.canPop()
                    ? const BackIconButton(color: Colors.white)
                    : const SizedBox.shrink(),
              ),
            ),
          ),
          const Spacer(),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Welcome',
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 40,
                      fontWeight: FontWeight.w400,
                      color: Colors.white),
                ),
                Button(
                  onPressed: () => context.goNamed('discover'),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    alignment: Alignment.center,
                    child: Text(
                      'Continue as guest',
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Button(
                  onPressed: () {
                    context.pushNamed('signup_phone');
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Log in or sign up',
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Policies(),
                const SizedBox(height: 36),
                SizedBox(
                  height: MediaQuery.of(context).padding.bottom,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
