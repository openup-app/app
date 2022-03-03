import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
        // No user verified, null UID
        Navigator.of(context).pop(null);
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: MediaQuery.of(context).padding.top,
              ),
              const Spacer(),
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
    final uid = await _validateCredential(credential);
    if (mounted) {
      setState(() => _submitting = false);
    }
    if (uid != null) {
      Navigator.of(context).pop(uid);
    }
  }

  Future<String?> _validateCredential(PhoneAuthCredential credential) async {
    try {
      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      return userCredential.user?.uid;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-verification-code' && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid code'),
          ),
        );
      }
    }
    return null;
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
