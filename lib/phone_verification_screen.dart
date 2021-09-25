import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openup/api/users.dart';
import 'package:openup/common.dart';
import 'package:openup/input_area.dart';
import 'package:openup/male_female_connection_image.dart';
import 'package:openup/sign_up/title_and_tagline.dart';
import 'package:openup/theming.dart';

class PhoneVerificationScreen extends StatefulWidget {
  final CredentialVerification credentialVerification;
  const PhoneVerificationScreen({
    Key? key,
    required this.credentialVerification,
  }) : super(key: key);

  @override
  State<PhoneVerificationScreen> createState() =>
      _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
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
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(
              child: SizedBox(height: 86),
            ),
            const SliverToBoxAdapter(
              child: TitleAndTagline(),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 10),
            ),
            SliverToBoxAdapter(
              child: Text(
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
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 22),
            ),
            SliverToBoxAdapter(
              child: InputArea(
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
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 22),
            ),
            SliverToBoxAdapter(
              child: PrimaryButton.large(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const CircularProgressIndicator()
                    : const Text('Verify account'),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 15),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Hero(
                tag: 'male_female_connection',
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 70),
                  child: const MaleFemaleConnectionImageApart(),
                ),
              ),
            ),
          ],
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

    final container = ProviderContainer();
    final usersApi = container.read(usersApiProvider);

    String? uid;
    try {
      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      uid = userCredential.user?.uid;
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
