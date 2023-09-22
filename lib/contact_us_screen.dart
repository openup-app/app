import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';

class ContactUsScreen extends ConsumerStatefulWidget {
  const ContactUsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends ConsumerState<ContactUsScreen> {
  final _messageFocusNode = FocusNode();
  final _textController = TextEditingController();
  bool _uploading = false;

  @override
  void initState() {
    _messageFocusNode.requestFocus();
    super.initState();
  }

  @override
  void dispose() {
    _messageFocusNode.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark(),
      child: CupertinoTheme(
        data: const CupertinoThemeData(brightness: Brightness.dark),
        child: Scaffold(
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 44,
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16.0),
                          child: Button(
                            onPressed: Navigator.of(context).pop,
                            child: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  color: Color.fromRGBO(0xFF, 0x00, 0x00, 1.0),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const Center(
                        child: Text(
                          'Contact us',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 24,
                  ),
                  child: Text(
                    'We will respond to you via text',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                Expanded(
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      color: Color.fromRGBO(0x61, 0x61, 0x61, 0.5),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 24,
                      ),
                      child: TextField(
                        controller: _textController,
                        autofocus: true,
                        focusNode: _messageFocusNode,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.done,
                        maxLines: 10,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                        decoration: const InputDecoration.collapsed(
                          hintText: 'Tell us how we can help you.',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Button(
                  onPressed: _uploading ? null : _upload,
                  child: SizedBox(
                    height: 92,
                    child: Center(
                      child: Builder(
                        builder: (context) {
                          if (_uploading) {
                            return const LoadingIndicator();
                          } else {
                            return const Text(
                              'Send message',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: Color.fromRGBO(0x3F, 0x80, 0xFF, 1.0),
                              ),
                            );
                          }
                        },
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

  void _upload() async {
    final userState = ref.read(userProvider2);
    final uid = userState.map(
      guest: (_) => null,
      signedIn: (signedIn) => signedIn.account.profile.uid,
    );
    if (uid == null) {
      return Future.value();
    }
    setState(() => _uploading = true);
    final message = _textController.text;

    final api = ref.read(apiProvider);
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
