import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';
import 'package:openup/widgets/back_button.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/input_area.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class SignupVerify extends ConsumerStatefulWidget {
  final String verificationId;
  const SignupVerify({
    Key? key,
    required this.verificationId,
  }) : super(key: key);

  @override
  ConsumerState<SignupVerify> createState() => _SignupVerifyState();
}

class _SignupVerifyState extends ConsumerState<SignupVerify> {
  final _smsCodeController = TextEditingController();
  bool _submitting = false;
  String? _errorText;

  @override
  void dispose() {
    _smsCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(0xF2, 0xF2, 0xF6, 1.0),
      resizeToAvoidBottomInset: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: MediaQuery.of(context).padding.top,
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.topCenter,
            child: Stack(
              alignment: Alignment.center,
              children: const [
                Align(
                  alignment: Alignment.centerLeft,
                  child: BackIconButton(
                    color: Colors.black,
                  ),
                ),
                Text(
                  'Verify phone number',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          const Text(
            'Enter verification code',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Color.fromRGBO(0x8D, 0x8D, 0x8D, 1.0),
            ),
          ),
          const SizedBox(height: 51),
          Center(
            child: ErrorText(
              errorText: _errorText,
              child: RoundedRectangleContainer(
                child: SizedBox(
                  width: 238,
                  height: 42,
                  child: Center(
                    child: TextField(
                      controller: _smsCodeController,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                      ),
                      onChanged: (_) {
                        setState(() => _errorText = null);
                      },
                      decoration: InputDecoration.collapsed(
                        hintText: 'Code',
                        hintStyle: Theme.of(context)
                            .textTheme
                            .bodyMedium!
                            .copyWith(fontSize: 18),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Code sent to your phone via text message.',
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: const Color.fromRGBO(0x8D, 0x8D, 0x8D, 1.0),
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.8),
          ),
          const Spacer(),
          Button(
            onPressed: _submitting ? null : _submit,
            child: RoundedRectangleContainer(
              child: SizedBox(
                width: 171,
                height: 42,
                child: Center(
                  child: _submitting
                      ? const LoadingIndicator(size: 27)
                      : Text(
                          'Verify',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w400,
                                  ),
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
    );
  }

  void _submit() async {
    ref.read(mixpanelProvider).track("sign_up_submit_phone_verification");
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);
    final smsCode = _smsCodeController.text;
    final result = await _signIn(smsCode);
    if (!mounted) {
      return;
    }

    setState(() => _submitting = false);
    final user = FirebaseAuth.instance.currentUser;
    if (result) {
      if (user == null) {
        throw 'No user is logged in';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sucessfully verified code'),
        ),
      );
      context.goNamed(
        'signup_phone',
        queryParams: {
          'verifiedUid': user.uid,
        },
      );
    }
  }

  Future<bool> _signIn(String smsCode) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: smsCode,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      return true;
    } on FirebaseAuthException catch (e, s) {
      if (e.code == 'invalid-verification-code') {
        if (mounted) {
          setState(() => _errorText = 'Invalid code');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid code'),
            ),
          );
        }
        return false;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Something went wrong'),
          ),
        );
      }
      Sentry.captureException(e, stackTrace: s);
      return false;
    } catch (e, s) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Something went wrong'),
          ),
        );
      }
      Sentry.captureException(e, stackTrace: s);
      return false;
    }
  }
}
