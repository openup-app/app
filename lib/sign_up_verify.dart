import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';
import 'package:openup/widgets/back_button.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/input_area.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class SignUpVerify extends StatefulWidget {
  final String verificationId;
  const SignUpVerify({
    Key? key,
    required this.verificationId,
  }) : super(key: key);

  @override
  State<SignUpVerify> createState() => _SignUpVerifyState();
}

class _SignUpVerifyState extends State<SignUpVerify> {
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
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/signup_background.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: MediaQuery.of(context).padding.top,
            ),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: BackIconButton(),
              ),
            ),
            const Spacer(),
            Text(
              'Enter verification code',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium!
                  .copyWith(fontSize: 20, fontWeight: FontWeight.w400),
            ),
            const Spacer(),
            InputArea(
              child: TextField(
                controller: _smsCodeController,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontSize: 40,
                    fontWeight: FontWeight.w500,
                    color: Colors.white),
                decoration: InputDecoration.collapsed(
                  hintText: 'Code',
                  hintStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 40,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.6)),
                ),
              ),
            ),
            const Spacer(),
            Button(
              onPressed: _submitting ? null : _submit,
              child: RoundedRectangleContainer(
                child: SizedBox(
                  width: 171,
                  child: Center(
                    child: _submitting
                        ? const LoadingIndicator(size: 24)
                        : Text(
                            'Next',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w300,
                                    color: Colors.white),
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
      ),
    );
  }

  void _submit() async {
    GetIt.instance.get<Mixpanel>().track("sign_up_submit_phone_verification");
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
