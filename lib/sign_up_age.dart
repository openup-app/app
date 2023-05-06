import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';
import 'package:openup/widgets/back_button.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/policies.dart';
import 'package:openup/widgets/signup_background.dart';

class SignUpAge extends ConsumerStatefulWidget {
  const SignUpAge({Key? key}) : super(key: key);

  @override
  ConsumerState<SignUpAge> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpAge> {
  static const _minAge = 13;
  static const _maxAge = 99;
  int _age = _minAge;

  @override
  Widget build(BuildContext context) {
    return SignupBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
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
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
            const Spacer(),
            Text(
              'Enter your age',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium!
                  .copyWith(fontSize: 20, fontWeight: FontWeight.w300),
            ),
            const Spacer(),
            SizedBox(
              width: 100,
              height: 200,
              child: Stack(
                children: [
                  // Underlay for CupertinoPicker
                  const Center(
                    child: SizedBox(
                      width: 71,
                      height: 40,
                      child: RoundedRectangleContainer(
                        child: SizedBox.shrink(),
                      ),
                    ),
                  ),
                  CupertinoPicker(
                    itemExtent: 40,
                    onSelectedItemChanged: (index) {
                      setState(() => _age = _minAge + index);
                    },
                    selectionOverlay: const SizedBox.shrink(),
                    children: [
                      for (var age = _minAge; age <= _maxAge; age++)
                        Center(
                          child: Text(
                            age.toString(),
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w300,
                                    color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),
            Button(
              onPressed: _age < 18
                  ? null
                  : () {
                      GetIt.instance.get<Mixpanel>().track(
                        "sign_up_submit_age",
                        properties: {'age': _age},
                      );
                      context.pushNamed('signup_permissions');
                    },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Log in or sign up',
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 27),
            const Policies(),
            const SizedBox(height: 36),
            SizedBox(
              height: MediaQuery.of(context).padding.bottom,
            ),
          ],
        ),
      ),
    );
  }
}
