import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/theming.dart';

class SignUpNameScreen extends ConsumerStatefulWidget {
  const SignUpNameScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SignUpNameScreen> createState() => _SignUpNameScreenState();
}

class _SignUpNameScreenState extends ConsumerState<SignUpNameScreen> {
  final _nameController = TextEditingController();
  bool _uploading = false;

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
              style: Theming.of(context)
                  .text
                  .body
                  .copyWith(fontWeight: FontWeight.w700, fontSize: 36),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            TextFormField(
              textAlign: TextAlign.center,
              controller: _nameController,
              textCapitalization: TextCapitalization.sentences,
              style: Theming.of(context).text.body.copyWith(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: Colors.white),
              decoration: InputDecoration.collapsed(
                hintText: 'Your name',
                hintStyle: Theming.of(context).text.body.copyWith(
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    color: const Color.fromRGBO(0x98, 0x98, 0x98, 1.0)),
              ),
            ),
            const Spacer(),
            ValueListenableBuilder(
              valueListenable: _nameController,
              builder: (context, _, child) {
                return OvalButton(
                  onPressed: (_nameController.text.isEmpty || _uploading)
                      ? null
                      : _submit,
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

  void _submit() async {
    final newName = _nameController.text;
    if (newName.isEmpty) {
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
      (r) => Navigator.of(context).pushNamed('sign-up-topic'),
    );

    setState(() => _uploading = false);
  }
}
