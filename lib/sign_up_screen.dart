import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_holo_date_picker/flutter_holo_date_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openup/api/users/users_api.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/flexible_single_child_scroll_view.dart';
import 'package:openup/widgets/input_area.dart';
import 'package:openup/widgets/male_female_connection_image.dart';
import 'package:openup/phone_verification_screen.dart';
import 'package:openup/widgets/title_and_tagline.dart';
import 'package:openup/widgets/theming.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  static final _phoneRegex = RegExp(r'^(?:[+0][1-9])?[0-9]{10,12}$');

  final _formKey = GlobalKey<FormState>();

  final _phoneController = TextEditingController();
  DateTime _birthday = DateTime.now();

  final _phoneFocusNode = FocusNode();

  String? _phoneErrorText;
  String? _birthdayErrorText;

  bool _submitting = false;
  int? _forceResendingToken;

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocusNode.dispose();
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
        child: FlexibleSingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                height: MediaQuery.of(context).padding.top,
              ),
              const SizedBox(height: 86),
              const TitleAndTagline(),
              const SizedBox(height: 10),
              InputArea(
                errorText: _phoneErrorText,
                child: TextFormField(
                  controller: _phoneController,
                  focusNode: _phoneFocusNode,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [
                    FilteringTextInputFormatter.deny(RegExp(r'\s')),
                  ],
                  onEditingComplete: () {
                    setState(() {
                      _phoneErrorText = _validatePhone(_phoneController.text);
                    });
                    FocusScope.of(context).unfocus();
                  },
                  textAlign: TextAlign.center,
                  decoration: InputDecoration.collapsed(
                    hintText: 'Phone number',
                    hintStyle: Theming.of(context)
                        .text
                        .body
                        .copyWith(color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              InputArea(
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
              const SizedBox(height: 22),
              PrimaryButton.large(
                child: _submitting
                    ? const CircularProgressIndicator()
                    : const Text('Send code'),
                onPressed: _submitting || !_valid ? null : _submit,
              ),
              const SizedBox(height: 15),
              const Spacer(),
              const Hero(
                tag: 'male_female_connection',
                child: SizedBox(
                  height: 100,
                  child: MaleFemaleConnectionImageApart(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool get _valid =>
      _validatePhone(_phoneController.text) == null &&
      _validateBirthday(_birthday) == null;

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

  String? _validateBirthday(DateTime value) {
    const ageLimit = Duration(days: 365 * 18);
    final age = DateTime.now().difference(value);
    if (age < ageLimit) {
      return 'You must be 18 years old or older';
    }
  }

  void _submit() async {
    final phone = _phoneController.text;
    setState(() => _phoneErrorText = _validatePhone(phone));

    if (_phoneErrorText == null && _birthdayErrorText == null) {
      setState(() => _submitting = true);
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        verificationCompleted: (credential) async {
          final container = ProviderScope.containerOf(context);
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
