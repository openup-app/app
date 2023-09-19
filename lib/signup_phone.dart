import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openup/auth/auth_provider.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/phone_number_input.dart';
import 'package:openup/widgets/signup_background.dart';

class SignupPhone extends ConsumerStatefulWidget {
  const SignupPhone({
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<SignupPhone> createState() => _SignUpPhoneState();
}

class _SignUpPhoneState extends ConsumerState<SignupPhone> {
  String? _phoneErrorText;
  String? _phoneNumber;
  bool _valid = false;

  bool _submitting = false;

  final _phoneNumberNode = FocusNode();

  @override
  void dispose() {
    super.dispose();
    _phoneNumberNode.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SignupBackground(
        child: Stack(
          fit: StackFit.expand,
          children: [
            const Center(
              child: Text(
                'Welcome',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Covered By Your Grace',
                  fontSize: 48,
                  fontWeight: FontWeight.w400,
                  color: Color.fromRGBO(0x00, 0x00, 0x00, 0.6),
                ),
              ),
            ),
            DecoratedBox(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/signup_paper1.png'),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Center(
                    child: Text(
                      'What\'s your number?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Covered By Your Grace',
                        fontSize: 36,
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  PhoneInput(
                    focusNode: _phoneNumberNode,
                    style: const TextStyle(
                      fontFamily: 'Covered By Your Grace',
                      fontSize: 45,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                    hintTextColor: const Color.fromRGBO(0x00, 0x00, 0x00, 0.3),
                    onChanged: (value, valid) {
                      setState(() {
                        _phoneNumber = value;
                        _valid = valid;
                      });
                    },
                    onValidationError: (error) =>
                        setState(() => _phoneErrorText = error),
                  ),
                ],
              ),
            )
                .animate(
                  delay: const Duration(milliseconds: 700),
                  onComplete: (_) => _phoneNumberNode.requestFocus(),
                )
                .rotate(
                  duration: const Duration(milliseconds: 1500),
                  curve: Curves.easeOutQuart,
                  begin: -145 / 360,
                  end: 7 / 360,
                )
                .slideY(
                  duration: const Duration(milliseconds: 1500),
                  curve: Curves.easeOutQuart,
                  begin: -1,
                  end: 0,
                ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewPadding.bottom + 32.0),
                child: Button(
                  onPressed: _submitting || !_valid ? null : _submit,
                  child: RoundedRectangleContainer(
                    child: SizedBox(
                      width: 171,
                      height: 42,
                      child: Center(
                        child: _submitting
                            ? const LoadingIndicator(color: Colors.black)
                            : const Text(
                                'Send code',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.black,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() async {
    FocusScope.of(context).unfocus();
    final phoneNumber = _phoneNumber;
    if (!_valid || phoneNumber == null) {
      return;
    }

    setState(() => _submitting = true);
    final notifier = ref.read(authProvider.notifier);
    final result = await notifier.signInWithPhoneNumber(phoneNumber);
    if (!mounted) {
      return;
    }
    setState(() => _submitting = false);

    result.map(
      codeSent: (codeSent) {
        context.pushNamed(
          'signup_verify',
          queryParams: {
            'verificationId': codeSent.verificationId,
          },
        );
      },
      verified: (_) {
        context.goNamed(
          'signup',
          queryParams: {
            'verified': true,
          },
        );
      },
      error: (error) {
        final e = error.error;
        final String message;
        switch (e) {
          case SendCodeError.credentialFailure:
            message = 'Failed to validate';
            break;
          case SendCodeError.invalidPhoneNumber:
            message = 'Unsupported phone number';
            break;
          case SendCodeError.networkError:
            message = 'Network error';
            break;
          case SendCodeError.tooManyRequests:
            message = 'Too many attempts, please try again later';
            break;
          case SendCodeError.quotaExceeded:
            message = 'Unable to send code, we are working to solve this';
            break;
          case SendCodeError.failure:
            message = 'Something went wrong';
            break;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
          ),
        );
      },
    );
  }
}
