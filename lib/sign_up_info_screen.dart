import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/input_area.dart';
import 'package:openup/widgets/keyboard_screen.dart';
import 'package:openup/widgets/male_female_connection_image.dart';
import 'package:openup/widgets/theming.dart';

class SignUpInfoScreen extends ConsumerStatefulWidget {
  const SignUpInfoScreen({Key? key}) : super(key: key);

  @override
  _SignUpInfoScreenState createState() => _SignUpInfoScreenState();
}

class _SignUpInfoScreenState extends ConsumerState<SignUpInfoScreen> {
  final _nameController = TextEditingController();
  bool _uploading = false;

  @override
  void initState() {
    super.initState();

    // Guaranteed to be non-null before onboarding
    final profile = ref.read(userProvider).profile!;
    _nameController.text = profile.name;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardScreen(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Who are you?',
                style: Theming.of(context).text.body.copyWith(
                      color: const Color.fromRGBO(0x62, 0xCD, 0xE3, 1.0),
                      fontWeight: FontWeight.w400,
                      fontSize: 48,
                    ),
              ),
              const SizedBox(height: 28),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 350),
                child: Text(
                  'Openup is about building real connections in a real way. Please respond to the following information to help those wanting to find someone like you, find you!',
                  textAlign: TextAlign.center,
                  style: Theming.of(context).text.body.copyWith(
                        color: const Color.fromRGBO(0x99, 0x99, 0x99, 1.0),
                        fontWeight: FontWeight.w400,
                        fontSize: 18,
                      ),
                ),
              ),
              const SizedBox(height: 24),
              InputArea(
                color: const Color.fromRGBO(0xED, 0xED, 0xED, 1.0),
                child: TextFormField(
                  textAlign: TextAlign.center,
                  controller: _nameController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration.collapsed(
                    hintText: 'Name',
                    hintStyle: Theming.of(context).text.body.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: const Color.fromRGBO(0x10, 0x10, 0x10, 1.0),
                        ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SignificantButton.blue(
                onPressed: _submit,
                child: _uploading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Continue'),
              ),
            ],
          ),
          const Align(
            alignment: Alignment.bottomCenter,
            child: MaleFemaleConnectionImageApart(),
          ),
        ],
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
      (r) => Navigator.of(context).pushNamed('sign-up-attributes'),
    );

    setState(() => _uploading = false);
  }
}
