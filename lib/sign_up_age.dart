import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/policies.dart';

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
    return DecoratedBox(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/signup_background.png'),
          fit: BoxFit.cover,
        ),
      ),
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
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 24.0),
                child: Button(
                  onPressed: () {},
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Log in',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium!
                          .copyWith(fontSize: 16, fontWeight: FontWeight.w300),
                    ),
                  ),
                ),
              ),
            ),
            const Spacer(),
            Text(
              'openup',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium!
                  .copyWith(fontSize: 40, fontWeight: FontWeight.w700),
            ),
            Image.asset(
              'assets/images/app_logo.png',
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
                  : () => context.pushNamed('signup_permissions'),
              child: RoundedRectangleContainer(
                child: Text(
                  'Get started',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w300,
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
