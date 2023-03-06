import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';

class SignUpName extends ConsumerStatefulWidget {
  const SignUpName({
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<SignUpName> createState() => _SignUpNameState();
}

class _SignUpNameState extends ConsumerState<SignUpName> {
  final _nameController = TextEditingController();
  bool _uploading = false;

  // Using valid flag rather than using Form validation due to there being no
  // way align error text properly, so we don't even display error text. See:
  // https://github.com/flutter/flutter/issues/11068
  bool _valid = false;

  static const _nameFromContacts = false;

  @override
  void initState() {
    super.initState();
    final name = ref.read(userProvider).profile?.name ?? '';
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
      body: DecoratedBox(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/signup_background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: MediaQuery.of(context).padding.top,
            ),
            const SizedBox(height: 16),
            const Spacer(),
            Text(
              'What is your first name?',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium!
                  .copyWith(fontSize: 20, fontWeight: FontWeight.w400),
            ),
            const SizedBox(height: 40),
            TextField(
              textAlign: TextAlign.center,
              controller: _nameController,
              textCapitalization: TextCapitalization.sentences,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium!
                  .copyWith(fontSize: 32, fontWeight: FontWeight.w400),
              onChanged: (text) =>
                  setState(() => _valid = _nameValidator(text) == null),
              decoration: InputDecoration.collapsed(
                hintText: 'Your name',
                hintStyle: Theme.of(context)
                    .textTheme
                    .bodyMedium!
                    .copyWith(fontSize: 32, color: Colors.white),
              ),
            ),
            const SizedBox(height: 8),
            if (_nameFromContacts)
              Text(
                'Imported from contacts',
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w400),
              ),
            const Spacer(),
            Button(
              onPressed: _uploading || !_valid ? null : _submit,
              child: RoundedRectangleContainer(
                child: SizedBox(
                  width: 171,
                  child: Center(
                    child: _uploading
                        ? const LoadingIndicator(size: 27)
                        : Text(
                            'Next',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w300,
                                    color: Colors.white),
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
        context.pushNamed('signup_gender');
      },
    );

    setState(() => _uploading = false);
  }
}
