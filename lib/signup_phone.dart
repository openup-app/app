import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openup/auth/auth_provider.dart';
import 'package:openup/widgets/back_button.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/input_area.dart';
import 'package:openup/widgets/phone_number_input.dart';

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
              children: [
                if (ModalRoute.of(context)?.canPop == true)
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: BackIconButton(
                      color: Colors.black,
                    ),
                  ),
                const Text(
                  'Log in or sign up',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          const Text(
            'Enter your phone number',
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
              errorText: _phoneErrorText,
              child: RoundedRectangleContainer(
                child: SizedBox(
                  width: 238,
                  height: 42,
                  child: PhoneInput(
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                    onChanged: (value, valid) {
                      setState(() {
                        _phoneNumber = value;
                        _valid = valid;
                      });
                    },
                    onValidationError: (error) =>
                        setState(() => _phoneErrorText = error),
                  ),
                ),
              ),
            ),
          ),
          const Text(
            'Please do not sign up with\n another person\'s number.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color.fromRGBO(0x8D, 0x8D, 0x8D, 1.0),
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.6,
            ),
          ),
          const Spacer(),
          Button(
            onPressed: _submitting || !_valid ? null : _submit,
            child: RoundedRectangleContainer(
              child: SizedBox(
                width: 171,
                height: 42,
                child: Center(
                  child: _submitting
                      ? const LoadingIndicator(
                          color: Colors.black,
                        )
                      : Text(
                          'Send code',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium!
                              .copyWith(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.black),
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
