import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openup/analytics/analytics.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/widgets/back_button.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/input_area.dart';
import 'package:openup/widgets/phone_number_input.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class SignupPhone extends ConsumerStatefulWidget {
  final String? verifiedUid;
  const SignupPhone({
    Key? key,
    this.verifiedUid,
  }) : super(key: key);

  @override
  ConsumerState<SignupPhone> createState() => _SignUpPhoneState();
}

class _SignUpPhoneState extends ConsumerState<SignupPhone> {
  String? _phoneErrorText;
  String? _phoneNumber;
  bool _valid = false;

  bool _submitting = false;
  int? _forceResendingToken;

  @override
  void initState() {
    super.initState();
    _handleVerification();
  }

  @override
  void didUpdateWidget(covariant SignupPhone oldWidget) {
    super.didUpdateWidget(oldWidget);
    _handleVerification();
  }

  void _handleVerification() async {
    final verifiedUid = widget.verifiedUid;
    if (verifiedUid != null && !_submitting) {
      setState(() => _submitting = true);
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token == null) {
        // TODO: Retry getting id token
        return null;
      }
      final api = ref.read(apiProvider);
      api.authToken = token;

      final result = await getAccount(api);
      if (!mounted) {
        return;
      }
      setState(() => _submitting = false);

      result.when(
        logIn: (account) {
          final notifier = ref.read(userProvider.notifier);
          notifier.uid(verifiedUid);
          notifier.profile(account.profile);
          ref.read(userProvider2.notifier).signedIn(account);
          ref.read(mixpanelProvider).track("login");
          context.goNamed('initialLoading');
        },
        signUp: () {
          final notifier = ref.read(userProvider.notifier);
          notifier.uid(verifiedUid);
          // TODO: Hook up location more robustly
          final locationValue = ref.read(locationProvider);
          const tempAustinLocation = LatLong(
            latitude: 30.3119,
            longitude: -97.732,
          );
          final latLong = locationValue?.latLong ?? tempAustinLocation;
          ref.read(accountCreationParamsProvider.notifier).latLong(latLong);
          ref.read(mixpanelProvider).track("signup_verified");
          context.pushReplacementNamed('signup_age');
        },
        retry: () {
          context.pushReplacementNamed('signup_phone');
        },
      );
    }
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
                  'Log in or sign up',
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
                          size: 27,
                          color: Colors.black,
                        )
                      : Text(
                          'Send code',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium!
                              .copyWith(
                                  fontSize: 20, fontWeight: FontWeight.w400),
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
    if (_valid && phoneNumber != null) {
      ref.read(mixpanelProvider).track("sign_up_submit_phone");
      setState(() => _submitting = true);
      await _sendVerificationCode(phoneNumber);
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Future<bool> _sendVerificationCode(String phoneNumber) async {
    final completer = Completer<bool>();
    FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (credential) async {
        try {
          final userCredential =
              await FirebaseAuth.instance.signInWithCredential(credential);
          completer.complete(true);

          final verifiedUid = userCredential.user?.uid ??
              FirebaseAuth.instance.currentUser?.uid;
          if (verifiedUid != null) {
            if (mounted) {
              context.goNamed(
                'signup_phone',
                queryParams: {
                  'verifiedUid': verifiedUid,
                },
              );
            }
          } else {
            throw 'User credential is null';
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Something went wrong'),
              ),
            );
          }
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        Sentry.captureException(e);

        final String message;
        if (e.code == 'invalid-phone-number') {
          message = 'Unsupported phone number';
        } else if (e.code == 'network-request-failed') {
          message = 'Network error';
        } else {
          debugPrint(e.code);
          message = 'Failed to send verification code';
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        }
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      },
      codeSent: (verificationId, forceResendingToken) async {
        if (!mounted) {
          return;
        }
        setState(() => _forceResendingToken = forceResendingToken);
        ref.read(mixpanelProvider).track("signup_submit_phone");
        context.pushNamed('signup_verify', queryParams: {
          'verificationId': verificationId,
        });
        completer.complete(true);
      },
      forceResendingToken: _forceResendingToken,
      codeAutoRetrievalTimeout: (verificationId) {
        // Android SMS auto-fill failed, nothing to do
      },
    );
    return completer.future;
  }
}
