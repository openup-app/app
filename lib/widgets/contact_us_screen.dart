import 'package:flutter/material.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/contact_text_field.dart';
import 'package:openup/widgets/home_button.dart';
import 'package:openup/widgets/theming.dart';

class ContactUsScreen extends StatefulWidget {
  const ContactUsScreen({Key? key}) : super(key: key);

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> {
  final _textController = TextEditingController();
  bool _uploading = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: SizedBox.fromSize(
            size: constraints.biggest,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.fromRGBO(0xFF, 0x8E, 0x8E, 1.0),
                    Color.fromRGBO(0x20, 0x84, 0xBD, 0.74),
                  ],
                ),
              ),
              child: SizedBox.expand(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 362),
                  child: Stack(
                    children: [
                      Positioned(
                        left: 16,
                        right: 16,
                        top: MediaQuery.of(context).padding.top + 72,
                        bottom: MediaQuery.of(context).viewPadding.bottom + 72,
                        child: Column(
                          children: [
                            // const Spacer(),
                            Expanded(
                              child: _Sheet(
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
                                          child: BackButton(),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      'Contact us anytime,\nabout anything.',
                                      textAlign: TextAlign.center,
                                      style: Theming.of(context)
                                          .text
                                          .body
                                          .copyWith(
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
                            // const Spacer(flex: 2),
                          ],
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
              ),
            ),
          ),
        );
      },
    );
  }

  void _upload() {}
}

class _Sheet extends StatelessWidget {
  final Widget child;
  const _Sheet({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const Opacity(
          opacity: 0.6,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.fromRGBO(0xFF, 0xFF, 0xFF, 0.65),
                  Color.fromRGBO(0xFF, 0xFF, 0xFF, 0.54),
                ],
              ),
              borderRadius: BorderRadius.all(Radius.circular(29)),
              boxShadow: [
                BoxShadow(
                  color: Color.fromRGBO(0x00, 0x00, 0x00, 0.25),
                  offset: Offset(0.0, 4.0),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _TextField extends StatelessWidget {
  final String hintText;
  const _TextField({
    Key? key,
    required this.hintText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(left: 24.0),
        child: TextField(
          decoration: InputDecoration.collapsed(
            hintText: hintText,
            hintStyle: Theming.of(context).text.body.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
          ),
        ),
      ),
    );
  }
}
