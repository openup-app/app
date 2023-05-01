import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/widgets/back_button.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/contact_text_field.dart';

class ContactUsScreen extends ConsumerStatefulWidget {
  const ContactUsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ContactUsScreen> createState() => _ContactUsScreenState();
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
    return Padding(
      padding: const EdgeInsets.only(top: 24.0),
      child: Scaffold(
        backgroundColor: const Color.fromRGBO(0xF2, 0xF2, 0xF6, 1.0),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: const BackIconButton(),
          centerTitle: true,
          title: Text(
            'Contact us',
            style:
                Theme.of(context).textTheme.bodyMedium!.copyWith(fontSize: 24),
          ),
        ),
        body: Stack(
          fit: StackFit.loose,
          children: [
            Positioned(
              left: 16,
              right: 16,
              top: MediaQuery.of(context).padding.top + 16,
              bottom: MediaQuery.of(context).viewPadding.bottom + 16,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 362,
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: ContactTextField(
                        textController: _textController,
                        hintText: 'Questions and concerns',
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 162,
                      height: 43,
                      child: GradientButton(
                        onPressed: _uploading ? null : _upload,
                        white: true,
                        child: _uploading
                            ? const LoadingIndicator()
                            : const Text('send'),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
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
