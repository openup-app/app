import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openup/analytics/analytics.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/auth/auth_provider.dart';
import 'package:openup/location/location_provider.dart';
import 'package:openup/widgets/back_button.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/input_area.dart';
import 'package:openup/widgets/restart_app.dart';

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
          const Align(
            alignment: Alignment.topCenter,
            child: Stack(
              alignment: Alignment.center,
              children: [
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
                    color: Colors.black,
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
            onPressed: _submitting
                ? null
                : () async {
                    final result = await _submit();
                    if (result == AuthResult.success && mounted) {
                      _handleVerification();
                    }
                  },
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
                          'Verify',
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

  Future<AuthResult?> _submit() async {
    final smsCode = _smsCodeController.text;
    FocusScope.of(context).unfocus();

    setState(() => _submitting = true);
    final notifier = ref.read(authProvider.notifier);
    final result = await notifier.authenticate(
      verificationId: widget.verificationId,
      smsCode: smsCode,
    );
    if (!mounted) {
      return null;
    }
    setState(() => _submitting = false);

    final String message;
    switch (result) {
      case AuthResult.success:
        message = 'Sucessfully verified code';
      case AuthResult.invalidCode:
        message = 'Invalid code';
      case AuthResult.invalidId:
        message = 'Unable to attempt verification, please try again';
      case AuthResult.quotaExceeded:
        message = 'We are experiencing high demand, please try again later';
      case AuthResult.failure:
        message = 'Something went wrong';
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );

    return result;
  }

  void _handleVerification() async {
    setState(() => _submitting = true);
    final result = await getAccount(ref.read(apiProvider));
    if (!mounted) {
      return;
    }
    setState(() => _submitting = false);

    result.when(
      logIn: (account) {
        final notifier = ref.read(userProvider.notifier);
        notifier.uid(account.profile.uid);
        notifier.profile(account.profile);
        ref.read(userProvider2.notifier).signedIn(account);
        ref.read(analyticsProvider).trackLogin();
        RestartApp.restartApp(context);
      },
      signUp: () {
        final locationValue = ref.read(locationProvider);
        final latLong = locationValue.current;
        ref.read(accountCreationParamsProvider.notifier).latLong(latLong);
        ref.read(analyticsProvider).trackSignupVerified();
        context.goNamed('signup_age');
      },
      retry: (e) {
        debugPrint(e.toString());
        context.goNamed('signup_phone');
      },
    );
  }
}
