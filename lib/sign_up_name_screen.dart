import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/widgets/common.dart';

class SignUpNameScreen extends ConsumerStatefulWidget {
  const SignUpNameScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SignUpNameScreen> createState() => _SignUpNameScreenState();
}

class _SignUpNameScreenState extends ConsumerState<SignUpNameScreen> {
  final _nameController = TextEditingController();
  bool _uploading = false;

  // Using valid flag rather than using Form validation due to there being no
  // way align error text properly, so we don't even display error text. See:
  // https://github.com/flutter/flutter/issues/11068
  bool _valid = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 80),
            Text(
              'What\'s your name?',
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 36,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            TextFormField(
              textAlign: TextAlign.center,
              controller: _nameController,
              textCapitalization: TextCapitalization.sentences,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium!
                  .copyWith(fontSize: 32),
              onChanged: (text) =>
                  setState(() => _valid = _nameValidator(text) == null),
              decoration: InputDecoration.collapsed(
                hintText: 'Your name',
                hintStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 32,
                      color: const Color.fromRGBO(0x98, 0x98, 0x98, 1.0),
                    ),
              ),
            ),
            const Spacer(),
            ValueListenableBuilder(
              valueListenable: _nameController,
              builder: (context, _, child) {
                return OvalButton(
                  onPressed: (!_valid || _uploading) ? null : _submit,
                  child: _uploading
                      ? const LoadingIndicator(color: Colors.black)
                      : const Text('continue'),
                );
              },
            ),
            const SizedBox(height: 59),
          ],
        ),
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
    final newName = _nameController.text;
    if (_nameValidator(newName) != null) {
      return;
    }

    setState(() => _uploading = true);

    final result = await updateName(
      context: context,
      ref: ref,
      name: newName,
    );

    if (!mounted) {
      return;
    }

    result.fold(
      (l) => displayError(context, l),
      (r) {
        GetIt.instance.get<Mixpanel>()
          ..track("sign_up_submit_name")
          ..getPeople().set('name', newName);
        context.pushNamed('onboarding-topic');
      },
    );

    setState(() => _uploading = false);
  }
}
