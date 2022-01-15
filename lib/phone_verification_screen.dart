import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openup/api/users/users_api.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/flexible_single_child_scroll_view.dart';
import 'package:openup/widgets/input_area.dart';
import 'package:openup/widgets/male_female_connection_image.dart';
import 'package:openup/widgets/title_and_tagline.dart';
import 'package:openup/widgets/theming.dart';

class PhoneVerificationScreen extends ConsumerStatefulWidget {
  final CredentialVerification credentialVerification;
  const PhoneVerificationScreen({
    Key? key,
    required this.credentialVerification,
  }) : super(key: key);

  @override
  _PhoneVerificationScreenState createState() =>
      _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState
    extends ConsumerState<PhoneVerificationScreen> {
  final _smsCodeController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _smsCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        // True means we are canceling the verification
        Navigator.of(context).pop(true);
        return Future.value(false);
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theming.of(context).friendBlue1,
              Theming.of(context).friendBlue2,
            ],
          ),
        ),
        child: FlexibleSingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                height: MediaQuery.of(context).padding.top,
              ),
              const SizedBox(height: 86),
              const TitleAndTagline(),
              const SizedBox(height: 10),
              Text(
                'Verification code successfully\nsent to your phone!',
                textAlign: TextAlign.center,
                style: Theming.of(context).text.subheading.copyWith(
                  shadows: [
                    Shadow(
                      color: Theming.of(context).shadow,
                      blurRadius: 6,
                      offset: const Offset(0.0, 3.0),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              InputArea(
                child: TextField(
                  controller: _smsCodeController,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'\d')),
                  ],
                  onSubmitted: (_) => FocusScope.of(context).unfocus(),
                  decoration: InputDecoration.collapsed(
                    hintText: 'Enter verification code',
                    hintStyle: Theming.of(context)
                        .text
                        .body
                        .copyWith(color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              SignificantButton.pink(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const CircularProgressIndicator()
                    : const Text('Verify account'),
              ),
              const SizedBox(height: 15),
              const Spacer(),
              const MaleFemaleConnectionImageApart(),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() async {
    final smsCode = _smsCodeController.text;
    final credential = PhoneAuthProvider.credential(
      verificationId: widget.credentialVerification.verificationId,
      smsCode: smsCode,
    );

    setState(() => _submitting = true);

    final usersApi = ref.read(usersApiProvider);

    String? uid;
    try {
      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      uid = userCredential.user?.uid;
      if (uid != null) {
        usersApi.uid = uid;
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-verification-code') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid code'),
          ),
        );
        setState(() => _submitting = false);
        return;
      }
    }

    try {
      if (uid != null) {
        await usersApi.createUserWithUid(
          uid: uid,
          birthday: widget.credentialVerification.birthday,
          notificationToken: await FirebaseMessaging.instance.getToken(),
        );
      }

      Navigator.of(context).popUntil((route) => route.isFirst);
      Navigator.of(context).pushReplacementNamed('/');
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong'),
        ),
      );
    } finally {
      setState(() => _submitting = false);
    }
  }
}

class CredentialVerification {
  /// Firebase verification ID pending verification
  final String verificationId;

  /// User's birthday, needed to created an account
  final DateTime birthday;

  CredentialVerification({
    required this.verificationId,
    required this.birthday,
  });
}
