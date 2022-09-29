import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/initial_loading_screen.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/flexible_single_child_scroll_view.dart';
import 'package:openup/widgets/input_area.dart';
import 'package:openup/widgets/male_female_connection_image.dart';
import 'package:openup/phone_verification_screen.dart';
import 'package:openup/widgets/policies.dart';
import 'package:openup/widgets/title_and_tagline.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen>
    with SingleTickerProviderStateMixin {
  static final _phoneRegex = RegExp(r'^(?:[+0][1-9])?[0-9]{10,12}$');

  final _formKey = GlobalKey<FormState>();

  final _phoneController = TextEditingController();

  final _phoneFocusNode = FocusNode();

  String? _phoneErrorText;
  late final AnimationController _phoneLabelAnimationController;

  bool _submitting = false;
  int? _forceResendingToken;

  @override
  void initState() {
    super.initState();
    _phoneLabelAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _phoneFocusNode.addListener(() {
      if (_phoneFocusNode.hasFocus) {
        _phoneLabelAnimationController.forward();
      } else if (_phoneController.text.isEmpty) {
        _phoneLabelAnimationController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    _phoneLabelAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
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
              Stack(
                alignment: Alignment.center,
                children: [
                  InputArea(
                    errorText: _phoneErrorText,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: TextFormField(
                        controller: _phoneController,
                        focusNode: _phoneFocusNode,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.done,
                        inputFormatters: [
                          FilteringTextInputFormatter.deny(RegExp(r'\s')),
                        ],
                        onChanged: (_) {
                          setState(() {
                            _phoneErrorText =
                                _validatePhone(_phoneController.text);
                          });
                        },
                        onEditingComplete: () {
                          FocusScope.of(context).unfocus();
                        },
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              fontWeight: FontWeight.w400,
                              color: Colors.grey,
                            ),
                        decoration:
                            const InputDecoration.collapsed(hintText: ''),
                      ),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _phoneLabelAnimationController,
                    builder: (context, child) {
                      final animation = CurvedAnimation(
                        parent: _phoneLabelAnimationController,
                        curve: Curves.easeOut,
                      );
                      return Positioned(
                        top: 22 - animation.value * 14,
                        child: IgnorePointer(
                          child: Text(
                            'Phone number',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                  fontWeight: FontWeight.w400,
                                  color: Colors.grey,
                                  fontSize: 18 - animation.value * 4,
                                ),
                          ),
                        ),
                      );
                    },
                  )
                ],
              ),
              const SizedBox(height: 22),
              Button(
                onPressed: _submitting || !_valid ? null : _submit,
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
                            : const Text('Send code')),
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

  bool get _valid => _validatePhone(_phoneController.text) == null;

  String? _validatePhone(String? value) {
    if (value == null) {
      return 'Enter a phone number';
    }

    if (_phoneRegex.stringMatch(value) == value) {
      return null;
    } else {
      return 'Invalid phone number';
    }
  }

  void _submit() async {
    FocusScope.of(context).unfocus();
    final phoneText = _phoneController.text;

    // American numbers are default audience
    final phone = phoneText.startsWith('+') ? phoneText : '+1$phoneText';

    setState(() => _phoneErrorText = _validatePhone(phone));

    if (_phoneErrorText == null) {
      setState(() => _submitting = true);

      final uid = await _verifyPhoneNumber(phone);
      if (uid != null && mounted) {
        final userCreated = await _createUser(uid);
        if (userCreated && mounted) {
          ref.read(userProvider.notifier).uid(uid);
        }

        if (mounted) {
          context.goNamed(
            'initialLoading',
            extra: InitialLoadingScreenArguments(needsOnboarding: userCreated),
          );
        }
      }

      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Future<bool> _createUser(String uid) async {
    final api = GetIt.instance.get<Api>();
    final result = await api.createUser(uid: uid);
    return result.fold(
      (l) {
        final message = l.map(
          network: (_) => 'Network error',
          client: (_) => 'Failed to create account',
          server: (_) => 'Something went wrong on our end, please try again',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
            ),
          );
        }
        return false;
      },
      (r) => r,
    );
  }

  Future<String?> _verifyPhoneNumber(String phone) async {
    final completer = Completer<String?>();
    FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (credential) async {
        try {
          final userCredential =
              await FirebaseAuth.instance.signInWithCredential(credential);
          completer.complete(userCredential.user?.uid);
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
          completer.complete(null);
        }
      },
      codeSent: (verificationId, forceResendingToken) async {
        if (!mounted) {
          return;
        }
        setState(() => _forceResendingToken = forceResendingToken);
        final uid = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) {
              return PhoneVerificationScreen(
                credentialVerification:
                    CredentialVerification(verificationId: verificationId),
              );
            },
          ),
        );
        if (!completer.isCompleted) {
          completer.complete(uid);
        }
      },
      forceResendingToken: _forceResendingToken,
      codeAutoRetrievalTimeout: (verificationId) {
        // Android SMS auto-fill failed, nothing to do
      },
    );
    return completer.future;
  }
}
