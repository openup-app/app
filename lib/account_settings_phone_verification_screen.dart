import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openup/widgets/back_button.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/home_button.dart';

class AccountSettingsPhoneVerificationScreen extends ConsumerStatefulWidget {
  final String verificationId;
  const AccountSettingsPhoneVerificationScreen({
    Key? key,
    required this.verificationId,
  }) : super(key: key);

  @override
  ConsumerState<AccountSettingsPhoneVerificationScreen> createState() =>
      _AccountSettingsPhoneVerificationScreenState();
}

class _AccountSettingsPhoneVerificationScreenState
    extends ConsumerState<AccountSettingsPhoneVerificationScreen> {
  final _smsCodeController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _smsCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: Colors.black),
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
        child: Stack(
          fit: StackFit.loose,
          children: [
            Positioned(
              top: MediaQuery.of(context).padding.top + 24,
              left: 8,
              child: Transform.scale(
                scale: 1.3,
                child: const BackIconButton(),
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 362),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        Center(
                          child: Text(
                            'Verify new number',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(fontSize: 30),
                          ),
                        ),
                        const Spacer(),
                        Center(
                          child: Text(
                            'Enter verification code',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _InputArea(
                          child: _TextField(
                            controller: _smsCodeController,
                            keyboardType: TextInputType.number,
                            hintText: 'verification code',
                          ),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: 237,
                          child: Button(
                            onPressed: _submitting ? null : _updateAndPop,
                            child: _InputArea(
                              childNeedsOpacity: false,
                              opacity: 0.8,
                              gradientColors: const [
                                Color.fromRGBO(0xFF, 0x3B, 0x3B, 0.65),
                                Color.fromRGBO(0xFF, 0x33, 0x33, 0.54),
                              ],
                              child: Center(
                                child: _submitting
                                    ? const LoadingIndicator()
                                    : Text(
                                        'Update',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium!
                                            .copyWith(
                                              fontSize: 24,
                                              fontWeight: FontWeight.w500,
                                            ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                        const Spacer(flex: 2),
                      ],
                    ),
                  ),
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

  void _updateAndPop() async {
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);

    final smsCode = _smsCodeController.text;
    final credential = PhoneAuthProvider.credential(
      verificationId: widget.verificationId,
      smsCode: smsCode,
    );

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw 'No user is logged in';
    }

    try {
      await user.updatePhoneNumber(credential);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully updated phone number'),
          ),
        );
        Navigator.of(context).pop();
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-verification-code') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid code'),
            ),
          );
          setState(() => _submitting = false);
        }
        return;
      }
    }
  }
}

class _InputArea extends StatelessWidget {
  final Widget child;
  final List<Color> gradientColors;
  final double opacity;
  final bool childNeedsOpacity;
  const _InputArea({
    Key? key,
    required this.child,
    this.gradientColors = const [
      Color.fromRGBO(0xFF, 0xFF, 0xFF, 0.65),
      Color.fromRGBO(0xFF, 0xFF, 0xFF, 0.54),
    ],
    this.opacity = 0.6,
    this.childNeedsOpacity = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 57,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Opacity(
            opacity: opacity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: gradientColors,
                ),
                borderRadius: const BorderRadius.all(Radius.circular(29)),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(0x00, 0x00, 0x00, 0.25),
                    offset: Offset(0.0, 4.0),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: childNeedsOpacity ? child : null,
            ),
          ),
          if (!childNeedsOpacity) child,
        ],
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String hintText;

  const _TextField({
    Key? key,
    required this.controller,
    this.keyboardType,
    required this.hintText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(left: 24.0),
        child: TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration.collapsed(
            hintText: hintText,
            hintStyle: Theme.of(context)
                .textTheme
                .bodyMedium!
                .copyWith(fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }
}
