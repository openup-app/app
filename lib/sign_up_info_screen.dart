import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/input_area.dart';
import 'package:openup/widgets/keyboard_screen.dart';
import 'package:openup/widgets/theming.dart';

class SignUpInfoScreen extends ConsumerStatefulWidget {
  const SignUpInfoScreen({Key? key}) : super(key: key);

  @override
  _SignUpInfoScreenState createState() => _SignUpInfoScreenState();
}

class _SignUpInfoScreenState extends ConsumerState<SignUpInfoScreen> {
  final _nameController = TextEditingController();
  bool _uploading = false;
  CrossFadeState _crossFadeState = CrossFadeState.showFirst;

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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromRGBO(0x02, 0x2D, 0x45, 1.0),
              Color.fromRGBO(0x00, 0x02, 0x03, 1.0),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: AnimatedCrossFade(
          duration: const Duration(seconds: 1),
          crossFadeState: _crossFadeState,
          alignment: Alignment.center,
          firstChild: GestureDetector(
            onTap: () =>
                setState(() => _crossFadeState = CrossFadeState.showSecond),
            child: SizedBox.expand(
              child: Center(
                child: Text(
                  'Welcome to openup\na new place to make\nnew friends',
                  style: Theming.of(context)
                      .text
                      .body
                      .copyWith(fontWeight: FontWeight.w300, fontSize: 32),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          secondChild: KeyboardScreen(
            child: Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Stack(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'What would you like\nyour name to be here?',
                        style: Theming.of(context).text.body.copyWith(
                            fontWeight: FontWeight.w300, fontSize: 32),
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
                                  color: const Color.fromRGBO(
                                      0x10, 0x10, 0x10, 1.0),
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    right: 24,
                    bottom: 24,
                    child: Button(
                      onPressed: _submit,
                      child: _uploading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Icon(Icons.chevron_right, size: 48),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _submit() async {
    final newName = _nameController.text;
    if (newName.isEmpty) {
      Navigator.of(context).pushNamed('sign-up-photos');
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
      (r) => Navigator.of(context).pushNamed('sign-up-photos'),
    );

    setState(() => _uploading = false);
  }
}
