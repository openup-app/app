import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/widgets/back_button.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/contact_text_field.dart';
import 'package:openup/widgets/home_button.dart';
import 'package:openup/widgets/keyboard_screen.dart';
import 'package:openup/widgets/theming.dart';

class ContactUsScreen extends ConsumerStatefulWidget {
  const ContactUsScreen({Key? key}) : super(key: key);

  @override
  _ContactUsScreenState createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends ConsumerState<ContactUsScreen> {
  final _textController = TextEditingController();
  bool _uploading = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.fromRGBO(0x01, 0x39, 0x59, 1.0),
            Color.fromRGBO(0x00, 0x15, 0x20, 1.0),
          ],
        ),
      ),
      child: KeyboardScreen(
        child: Stack(
          fit: StackFit.loose,
          children: [
            Positioned(
              left: 16,
              right: 16,
              top: MediaQuery.of(context).padding.top + 72,
              bottom: MediaQuery.of(context).viewPadding.bottom + 72,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 362,
                ),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Transform.scale(
                        scale: 1.3,
                        child: const Padding(
                          padding: EdgeInsets.only(
                            left: 4.0,
                            top: 4.0,
                          ),
                          child: BackIconButton(),
                        ),
                      ),
                    ),
                    Text(
                      'Contact us anytime,\nabout anything.',
                      textAlign: TextAlign.center,
                      style: Theming.of(context).text.body.copyWith(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: ContactTextField(
                        textController: _textController,
                        hintText: 'Questions and concerns',
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: 162,
                      height: 43,
                      child: GradientButton(
                        onPressed: _uploading ? null : _upload,
                        white: true,
                        child: _uploading
                            ? const CircularProgressIndicator()
                            : const Text('send'),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            Positioned(
              right: MediaQuery.of(context).padding.right + 16,
              bottom: MediaQuery.of(context).padding.bottom + 16,
              child: const HomeButton(
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _upload() async {
    setState(() => _uploading = true);
    final message = _textController.text;
    final uid = ref.read(userProvider).uid;
    final api = GetIt.instance.get<Api>();
    final result = await api.contactUs(uid: uid, message: message);
    if (!mounted) {
      return;
    }
    setState(() => _uploading = false);
    result.fold(
      (l) => displayError(context, l),
      (r) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully sent message'),
          ),
        );
        Navigator.of(context).pop();
      },
    );
  }
}
