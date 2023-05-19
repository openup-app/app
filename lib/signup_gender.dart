import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openup/analytics/analytics.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/widgets/back_button.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';

class SignupGender extends ConsumerStatefulWidget {
  const SignupGender({
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<SignupGender> createState() => _SignupGenderState();
}

class _SignupGenderState extends ConsumerState<SignupGender> {
  Gender? _gender;

  @override
  Widget build(BuildContext context) {
    const activeColor = Color.fromRGBO(0x06, 0xD9, 0x1B, 0.8);
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
                  'Gender',
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
            'Select your gender',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Color.fromRGBO(0x8D, 0x8D, 0x8D, 1.0),
            ),
          ),
          const SizedBox(height: 51),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RoundedRectangleContainer(
                  color: _gender == Gender.male ? activeColor : null,
                  child: Button(
                    onPressed: () {
                      setState(() => _gender = Gender.male);
                      _submit();
                    },
                    child: SizedBox(
                      width: 238,
                      height: 42,
                      child: Center(
                        child: Text(
                          'Male',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                            color: _gender == Gender.male
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 27),
                RoundedRectangleContainer(
                  color: _gender == Gender.female ? activeColor : null,
                  child: Button(
                    onPressed: () {
                      setState(() => _gender = Gender.female);
                      _submit();
                    },
                    child: SizedBox(
                      width: 238,
                      height: 42,
                      child: Center(
                        child: Text(
                          'Female',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                            color: _gender == Gender.female
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 27),
                RoundedRectangleContainer(
                  color: _gender == Gender.nonBinary ? activeColor : null,
                  child: Button(
                    onPressed: () {
                      setState(() => _gender = Gender.nonBinary);
                      _submit();
                    },
                    child: SizedBox(
                      width: 238,
                      height: 42,
                      child: Center(
                        child: Text(
                          'Non-binary',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                            color: _gender == Gender.nonBinary
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          const SizedBox(height: 36),
          SizedBox(
            height: MediaQuery.of(context).padding.bottom,
          ),
        ],
      ),
    );
  }

  void _submit() async {
    final gender = _gender;
    if (gender == null) {
      return;
    }

    precacheImage(
      const AssetImage('assets/images/tutorial_photo_good.jpg'),
      context,
    );
    precacheImage(
      const AssetImage('assets/images/tutorial_photo_bad.jpg'),
      context,
    );

    ref.read(mixpanelProvider)
      ..track("signup_submit_gender")
      ..getPeople().set('gender', gender.name);
    ref.read(accountCreationParamsProvider.notifier).gender(gender);
    context.pushNamed('signup_tutorial1');
  }
}
