import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openup/analytics/analytics.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/widgets/back_button.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';

class SignupName extends ConsumerStatefulWidget {
  const SignupName({Key? key}) : super(key: key);

  @override
  ConsumerState<SignupName> createState() => _SignupNameState();
}

class _SignupNameState extends ConsumerState<SignupName> {
  final _nameController = TextEditingController();

  // Using valid flag rather than using Form validation due to there being no
  // way align error text properly, so we don't even display error text. See:
  // https://github.com/flutter/flutter/issues/11068
  bool _valid = false;

  @override
  void initState() {
    super.initState();
    final name = ref.read(accountCreationParamsProvider).name ?? '';
    _nameController.text = name;
    _valid = _nameValidator(name) == null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

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
                  'Name',
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
            'Enter your first name',
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
              width: 238,
              height: 42,
              child: Center(
                child: TextField(
                  textAlign: TextAlign.center,
                  controller: _nameController,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                  ),
                  onChanged: (text) =>
                      setState(() => _valid = _nameValidator(text) == null),
                  decoration: const InputDecoration.collapsed(
                    hintText: 'Name',
                    hintStyle: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'For safety purposes, kindly refrain\nfrom including your last name.',
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: const Color.fromRGBO(0x8D, 0x8D, 0x8D, 1.0),
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.8),
          ),
          const Spacer(),
          Button(
            onPressed: !_valid ? null : _submit,
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

  String? _nameValidator(String? text) {
    if (text == null || text.isEmpty) {
      return 'Enter a name';
    }

    if (text.length < 3) {
      return 'Must be at least three characters long';
    }
    return null;
  }

  void _submit() async {
    FocusScope.of(context).unfocus();

    final newName = _nameController.text;
    if (_nameValidator(newName) != null) {
      return;
    }

    ref.read(mixpanelProvider)
      ..track("signup_submit_name")
      ..getPeople().set('name', newName);
    ref.read(accountCreationParamsProvider.notifier).name(newName);
    context.pushNamed('signup_gender');
  }
}
