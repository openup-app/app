import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/flexible_single_child_scroll_view.dart';
import 'package:openup/widgets/input_area.dart';
import 'package:openup/widgets/male_female_connection_image.dart';
import 'package:openup/widgets/policies.dart';
import 'package:openup/widgets/title_and_tagline.dart';
import 'package:openup/widgets/theming.dart';

class PhoneVerificationScreen extends ConsumerStatefulWidget {
  final CredentialVerification credentialVerification;
  const PhoneVerificationScreen({
    Key? key,
    required this.credentialVerification,
  }) : super(key: key);

  @override
  ConsumerState<PhoneVerificationScreen> createState() =>
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: WillPopScope(
        onWillPop: () {
          // No user verified, null UID
          Navigator.of(context).pop(null);
          return Future.value(false);
        },
        child: FlexibleSingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: MediaQuery.of(context).padding.top,
              ),
              const Spacer(),
              const TitleAndTagline(),
              const Spacer(),
              Text(
                'Verification code successfully\nsent to your phone!',
                textAlign: TextAlign.center,
                style: Theming.of(context).text.body.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w300,
                    ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: 310,
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
                      hintStyle: Theming.of(context).text.body.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: const Color.fromRGBO(0x6D, 0x6D, 0x6D, 1.0),
                          ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Button(
                onPressed: _submitting ? null : _submit,
                child: Container(
                  height: 69,
                  constraints: const BoxConstraints(maxWidth: 300),
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(94)),
                    color: Color.fromRGBO(0xE4, 0x00, 0x00, 1.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Center(
                        child: _submitting
                            ? const LoadingIndicator()
                            : const Text('Verify Account & Accept')),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Policies(),
              const Spacer(),
              const MaleFemaleConnectionImageApart(),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() async {
    FocusScope.of(context).unfocus();
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
    if (uid != null && mounted) {
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

  CredentialVerification({
    required this.verificationId,
  });
}
