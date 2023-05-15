import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/widgets/back_button.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';

class SignupAge extends ConsumerStatefulWidget {
  const SignupAge({Key? key}) : super(key: key);

  @override
  ConsumerState<SignupAge> createState() => _SignupAgeState();
}

class _SignupAgeState extends ConsumerState<SignupAge> {
  static const _minAge = 13;
  static const _maxAge = 99;
  int _age = _minAge;

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
                  'Age',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          const Text(
            'Select your age',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Color.fromRGBO(0x8D, 0x8D, 0x8D, 1.0),
            ),
          ),
          const SizedBox(height: 51),
          RoundedRectangleContainer(
            child: SizedBox(
              width: 100,
              height: 255,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const IgnorePointer(
                    child: SizedBox(
                      width: 71,
                      height: 38,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Color.fromRGBO(0xF2, 0xF2, 0xF6, 1.0),
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                      ),
                    ),
                  ),
                  CupertinoPicker(
                    itemExtent: 40,
                    diameterRatio: 40,
                    squeeze: 1.0,
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
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                              color: Colors.black,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          Button(
            onPressed: _age < 17 ? null : _submit,
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
    ref.read(mixpanelProvider)
      ..track("signup_submit_age")
      ..getPeople().set('age', _age);
    ref.read(accountCreationParamsProvider.notifier).age(_age);
    context.pushNamed('signup_permissions');
  }
}
