import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/input_area.dart';
import 'package:openup/widgets/keyboard_screen.dart';
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
    return WillPopScope(
      onWillPop: () => Future.value(false),
      child: DecoratedBox(
        decoration: const BoxDecoration(color: Colors.black),
        child: KeyboardScreen(
          child: Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'What\'s your name?',
                  style: Theming.of(context)
                      .text
                      .body
                      .copyWith(fontWeight: FontWeight.w300, fontSize: 32),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                InputArea(
                  color: const Color.fromRGBO(0xED, 0xED, 0xED, 1.0),
                  child: TextFormField(
                    textAlign: TextAlign.center,
                    controller: _nameController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration.collapsed(
                      hintText: 'Username',
                      hintStyle: Theming.of(context).text.body.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: const Color.fromRGBO(0x10, 0x10, 0x10, 1.0),
                          ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(35.0),
                  child: ValueListenableBuilder(
                    valueListenable: _nameController,
                    builder: (context, _, child) {
                      return Button(
                        onPressed: (_nameController.text.isEmpty || _uploading)
                            ? null
                            : _submit,
                        child: child!,
                      );
                    },
                    child: OutlinedArea(
                      child: Center(
                        child: _uploading
                            ? const CircularProgressIndicator()
                            : const Text('continue'),
                      ),
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
      (r) => Navigator.of(context).pushReplacementNamed('sign-up-topic'),
    );

    setState(() => _uploading = false);
  }
}
