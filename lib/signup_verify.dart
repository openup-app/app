import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openup/analytics/analytics.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/auth/auth_provider.dart';
import 'package:openup/location/location_provider.dart';
import 'package:openup/widgets/back_button.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/input_area.dart';
import 'package:openup/widgets/restart_app.dart';
import 'package:openup/widgets/signup_background.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

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
      resizeToAvoidBottomInset: false,
      body: SignupBackground(
        child: Stack(
          children: [
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              child: const BackIconButton(
                color: Colors.black,
              ),
            ),
            Center(
              child: Transform.rotate(
                angle: radians(-5),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Image.asset('assets/images/signup_paper2.png'),
                    ),
                    ErrorText(
                      errorText: _errorText,
                      child: Center(
                        child: Transform.rotate(
                          angle: radians(-10),
                          child: TextField(
                            controller: _smsCodeController,
                            autofocus: true,
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.done,
                            style: const TextStyle(
                              fontFamily: 'Covered By Your Grace',
                              fontSize: 27,
                              fontWeight: FontWeight.w400,
                              color: Colors.black,
                            ),
                            onChanged: (_) {
                              setState(() => _errorText = null);
                              _maybeAutoSubmit();
                            },
                            decoration: const InputDecoration.collapsed(
                              hintText: 'Verification Code?',
                              hintStyle: TextStyle(
                                fontSize: 27,
                                fontWeight: FontWeight.w400,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_submitting)
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 128),
                  child: LoadingIndicator(
                    color: Colors.black,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _maybeAutoSubmit() async {
    if (_submitting || _smsCodeController.text.length != 6) {
      return;
    }

    final result = await _submit();
    if (!mounted) {
      return;
    }
    if (result == AuthResult.success) {
      _handleVerification();
    } else {
      FocusScope.of(context).requestFocus();
    }
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
        ref.read(userProvider.notifier).signedIn(account);
        ref.read(analyticsProvider).trackLogin();
        RestartApp.restartApp(context);
      },
      signUp: () {
        final latLong = ref.read(locationProvider).current;
        ref.read(accountCreationParamsProvider.notifier).latLong(latLong);
        ref.read(analyticsProvider).trackSignupVerified();
        context.goNamed('signup_permissions');
      },
      retry: (e) {
        debugPrint(e.toString());
        context.goNamed('signup_phone');
      },
    );
  }
}
