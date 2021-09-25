import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_holo_date_picker/flutter_holo_date_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openup/api/users.dart';
import 'package:openup/button.dart';
import 'package:openup/common.dart';
import 'package:openup/input_area.dart';
import 'package:openup/male_female_connection_image.dart';
import 'package:openup/phone_verification_screen.dart';
import 'package:openup/sign_up/title_and_tagline.dart';
import 'package:openup/theming.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  static final _phoneRegex = RegExp(r'^(?:[+0][1-9])?[0-9]{10,12}$');

// From https://stackoverflow.com/a/16888554
  static final _emailRegex = RegExp(
      r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$");

  final _formKey = GlobalKey<FormState>();

  final _phoneEmailController = TextEditingController();
  final _passwordController = TextEditingController();
  DateTime _birthday = DateTime.now();

  final _phoneEmailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  String? _phoneEmailErrorText;
  String? _passwordErrorText;
  String? _birthdayErrorText;

  bool _submitting = false;
  int? _forceResendingToken;

  @override
  void dispose() {
    _phoneEmailController.dispose();
    _passwordController.dispose();
    _phoneEmailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theming.of(context).friendBlue1,
            Theming.of(context).friendBlue2,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: SizedBox(
                height: MediaQuery.of(context).padding.top,
              ),
            ),
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
              child: InputArea(
                errorText: _phoneEmailErrorText,
                child: TextFormField(
                  controller: _phoneEmailController,
                  focusNode: _phoneEmailFocusNode,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [
                    FilteringTextInputFormatter.deny(RegExp(r'\s')),
                  ],
                  onEditingComplete: () {
                    setState(() => _phoneEmailErrorText =
                        _validateEmailPhone(_phoneEmailController.text));
                    FocusScope.of(context).nextFocus();
                  },
                  textAlign: TextAlign.center,
                  decoration: InputDecoration.collapsed(
                    hintText: 'Phone number or email',
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
              child: InputArea(
                errorText: _passwordErrorText,
                child: TextFormField(
                  controller: _passwordController,
                  focusNode: _passwordFocusNode,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [
                    FilteringTextInputFormatter.deny(RegExp(r'\s')),
                  ],
                  onEditingComplete: () {
                    setState(() => _passwordErrorText =
                        _validatePassword(_passwordController.text));
                    FocusScope.of(context).unfocus();
                  },
                  textAlign: TextAlign.center,
                  obscureText: true,
                  decoration: InputDecoration.collapsed(
                    hintText: 'Password',
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
              child: InputArea(
                errorText: _birthdayErrorText,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Birthday',
                      style: Theming.of(context).text.body.copyWith(
                          color: Colors.grey, fontWeight: FontWeight.w500),
                    ),
                    Expanded(
                      child: SizedBox(
                        height: 64,
                        child: ClipRect(
                          child: OverflowBox(
                            maxHeight: 200,
                            child: DatePickerWidget(
                              looping: true,
                              onChange: (date, _) {
                                setState(() {
                                  _birthday = date;
                                  _birthdayErrorText = _validateBirthday(date);
                                });
                              },
                              dateFormat: 'MMM-dd-yyyy',
                              locale: DateTimePickerLocale.en_us,
                              pickerTheme: DateTimePickerTheme(
                                itemTextStyle: Theming.of(context)
                                    .text
                                    .body
                                    .copyWith(color: Colors.grey),
                                backgroundColor: Colors.transparent,
                                dividerColor: const Color.fromARGB(
                                    0xFF, 0xFF, 0xAC, 0xAC),
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
            const SliverToBoxAdapter(
              child: SizedBox(height: 22),
            ),
            SliverToBoxAdapter(
              child: PrimaryButton.large(
                child: _submitting
                    ? const CircularProgressIndicator()
                    : const Text('Send code'),
                onPressed: _submitting ? null : _submit,
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 15),
            ),
            SliverToBoxAdapter(
              child: Center(
                child: Button(
                  child: const Text('forgot info?'),
                  onPressed: _submitting
                      ? null
                      : () =>
                          Navigator.of(context).pushNamed('forgot-password'),
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 15),
            ),
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Hero(
                tag: 'male_female_connection',
                child: SizedBox(
                  height: 100,
                  child: MaleFemaleConnectionImageApart(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _validateEmailPhone(String? value) {
    if (value == null) {
      return 'Enter a phone or email address';
    }

    if (_phoneRegex.stringMatch(value) == value ||
        _emailRegex.stringMatch(value) == value) {
      return null;
    } else {
      return 'Invalid phone or email address';
    }
  }

  String? _validatePassword(String? value) {
    if (value == null) {
      return 'Enter a password';
    }

    if (value.length < 8) {
      return '8 or more characters required';
    }

    if (!value.contains(RegExp(r'\d')) || !value.contains(RegExp('[a-zA-Z]'))) {
      return 'Numbers and letters required';
    }

    if (!value.contains(RegExp('[a-z]')) || !value.contains(RegExp('[A-Z]'))) {
      return 'Uppercase and lowercase letters required';
    }
  }

  String? _validateBirthday(DateTime value) {
    const ageLimit = Duration(days: 365 * 18);
    final age = DateTime.now().difference(value);
    if (age < ageLimit) {
      return 'You must be 18 years old or older';
    }
  }

  void _submit() async {
    final phoneEmail = _phoneEmailController.text;
    final password = _passwordController.text;
    setState(() => _phoneEmailErrorText = _validateEmailPhone(phoneEmail));
    setState(() => _passwordErrorText = _validatePassword(password));

    if (_phoneEmailErrorText == null &&
        _passwordErrorText == null &&
        _birthdayErrorText == null) {
      setState(() => _submitting = true);
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneEmail,
        verificationCompleted: (credential) async {
          final container = ProviderContainer();
          final usersApi = container.read(usersApiProvider);

          String? uid;
          try {
            final userCredential =
                await FirebaseAuth.instance.signInWithCredential(credential);
            uid = userCredential.user?.uid;
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Something went wrong'),
              ),
            );
          }

          if (uid != null) {
            await usersApi.createUserWithUid(uid: uid, birthday: _birthday);
          }
          setState(() => _submitting = false);
        },
        verificationFailed: (FirebaseAuthException e) {
          print(e);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to send verification code'),
            ),
          );
          setState(() => _submitting = false);
        },
        codeSent: (verificationId, forceResendingToken) async {
          setState(() => _forceResendingToken = forceResendingToken);
          await Navigator.of(context).pushNamed<bool>(
            'phone-verification',
            arguments: CredentialVerification(
              verificationId: verificationId,
              birthday: _birthday,
            ),
          );
          setState(() => _submitting = false);
        },
        forceResendingToken: _forceResendingToken,
        codeAutoRetrievalTimeout: (verificationId) {
          // Android SMS auto-fill failed, nothing to do
        },
      );
    }
  }
}
