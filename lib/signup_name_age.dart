import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openup/analytics/analytics.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/widgets/back_button.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/scaffold.dart';
import 'package:openup/widgets/signup_background.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

class SignupNameAge extends ConsumerStatefulWidget {
  const SignupNameAge({super.key});

  @override
  ConsumerState<SignupNameAge> createState() => _SignupNameAgeState();
}

class _SignupNameAgeState extends ConsumerState<SignupNameAge> {
  late final TextEditingController _nameController;
  late final TextEditingController _ageController;

  final _denyLowerCaseInputFormatter =
      FilteringTextInputFormatter.deny(RegExp('[a-zá-ú]'));

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: ref.read(accountCreationParamsProvider).name,
    );
    _ageController = TextEditingController(
      text: ref.read(accountCreationParamsProvider).age?.toString(),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      appBar: const OpenupAppBar(
        blurBackground: false,
        body: OpenupAppBarBody(
          leading: BackIconButton(
            color: Colors.black,
          ),
        ),
      ),
      body: SignupBackground(
        child: SafeArea(
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: const Alignment(-0.7, -0.9),
                  child: Transform.rotate(
                    angle: radians(-45.5),
                    alignment: Alignment.center,
                    child: const Text(
                      'I <3 you',
                      style: TextStyle(
                        fontFamily: 'Covered By Your Grace',
                        fontSize: 22,
                        fontWeight: FontWeight.w400,
                        color: Color.fromRGBO(0x00, 0x00, 0x00, 0.45),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: const Alignment(0, -0.3),
                  child: Image.asset(
                    'assets/images/name_age_sticker.png',
                    fit: BoxFit.cover,
                  ),
                ),
                Align(
                  alignment: const Alignment(0, -0.19),
                  child: Transform.rotate(
                    angle: radians(4),
                    child: ClipRect(
                      child: Padding(
                        padding:
                            const EdgeInsets.only(left: 20, top: 9, right: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              fit: FlexFit.loose,
                              child: TextFormField(
                                controller: _nameController,
                                autofocus: true,
                                textCapitalization:
                                    TextCapitalization.characters,
                                textInputAction: TextInputAction.next,
                                textAlign: TextAlign.end,
                                inputFormatters: [_denyLowerCaseInputFormatter],
                                onChanged: ref
                                    .read(
                                        accountCreationParamsProvider.notifier)
                                    .name,
                                style: const TextStyle(
                                  fontFamily: 'Gotham Black Regular',
                                  fontSize: 24,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'NAME',
                                  hintStyle: TextStyle(
                                    fontFamily: 'Gotham Black Regular',
                                    fontSize: 24,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),
                            const Text(
                              ', ',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                            ),
                            Flexible(
                              fit: FlexFit.loose,
                              child: TextFormField(
                                controller: _ageController,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.done,
                                onChanged: (value) {
                                  final age = int.tryParse(value);
                                  if (age != null) {
                                    ref
                                        .read(accountCreationParamsProvider
                                            .notifier)
                                        .age(age);
                                  }
                                },
                                style: const TextStyle(
                                  fontFamily: 'Gotham Black Regular',
                                  fontSize: 24,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'AGE',
                                  hintStyle: TextStyle(
                                    fontFamily: 'Gotham Black Regular',
                                    fontSize: 24,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
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
                Align(
                  alignment: const Alignment(1.0, -0.94),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 24),
                    child: SignupNextButton(
                      onPressed: ref.watch(accountCreationParamsProvider
                              .select((s) => !(s.nameValid && s.ageValid)))
                          ? null
                          : _submit,
                      child: const Text('Next'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    final analytics = ref.read(analyticsProvider);
    analytics.trackSignupSubmitName();
    analytics.trackSignupSubmitAge();
    context.pushNamed('signup_audio');
  }
}
