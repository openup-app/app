import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/util/location_service.dart';
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
      final api = GetIt.instance.get<Api>();
      api.authToken = token;

      final result = await getAccount();
      if (!mounted) {
        return;
      }
      setState(() => _submitting = false);

      result.when(
        logIn: (profile) {
          final notifier = ref.read(userProvider.notifier);
          notifier.uid(verifiedUid);
          notifier.profile(profile);
          ref.read(userProvider2.notifier).signedIn(profile);
          context.goNamed('initialLoading');
        },
        signUp: () {
          final notifier = ref.read(userProvider.notifier);
          notifier.uid(verifiedUid);
          // TODO: Use real age, hook up location more robustly
          ref.read(accountCreationParamsProvider.notifier).age(30);
          final locationValue = ref.read(locationProvider);
          AccountCreationLocation location;
          if (locationValue != null) {
            location = AccountCreationLocation(
              latitude: locationValue.latitude,
              longitude: locationValue.longitude,
            );
          } else {
            const tempAustinLocation = AccountCreationLocation(
              latitude: 30.3119,
              longitude: -97.732,
            );
            location = tempAustinLocation;
          }
          ref.read(accountCreationParamsProvider.notifier).location(location);
          context.pushReplacementNamed('signup_permissions');
        },
        retry: () {
          context.pushReplacementNamed('signup_phone');
        },
      );
    }
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
              'Enter your phone number',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium!
                  .copyWith(fontSize: 20, fontWeight: FontWeight.w400),
            ),
            const SizedBox(height: 61),
            InputArea(
              errorText: _phoneErrorText,
              child: PhoneInput(
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
            const SizedBox(height: 52),
            Text(
              'Please do not sign up with\n another person\'s number.',
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w300,
                  height: 1.8),
            ),
            const Spacer(),
            Button(
              onPressed: _submitting || !_valid ? null : _submit,
              child: RoundedRectangleContainer(
                child: SizedBox(
                  width: 171,
                  child: Center(
                    child: _submitting
                        ? const LoadingIndicator(size: 27)
                        : Text(
                            'Send code',
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
    FocusScope.of(context).unfocus();

    final phoneNumber = _phoneNumber;
    if (_valid && phoneNumber != null) {
      GetIt.instance.get<Mixpanel>().track("sign_up_submit_phone");
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
        if (e.code == 'network-request-failed') {
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
