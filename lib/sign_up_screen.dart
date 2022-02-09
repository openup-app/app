import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen>
    with SingleTickerProviderStateMixin {
  static final _phoneRegex = RegExp(r'^(?:[+0][1-9])?[0-9]{10,12}$');

  final _formKey = GlobalKey<FormState>();

  final _phoneController = TextEditingController();
  DateTime _birthday = DateTime.now();

  final _phoneFocusNode = FocusNode();
  bool _birthdayFocused = false;

  String? _phoneErrorText;
  String? _birthdayErrorText;
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
        setState(() => _birthdayFocused = false);
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: MediaQuery.of(context).padding.top,
              ),
              const Spacer(),
              const TitleAndTagline(),
              const SizedBox(height: 10),
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
                        onEditingComplete: () {
                          setState(() {
                            _phoneErrorText =
                                _validatePhone(_phoneController.text);
                          });
                          FocusScope.of(context).unfocus();
                        },
                        textAlign: TextAlign.center,
                        style: Theming.of(context).text.body.copyWith(
                            fontWeight: FontWeight.w400,
                            color: Colors.grey,
                            fontSize: 18),
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
                            style: Theming.of(context).text.body.copyWith(
                                fontWeight: FontWeight.w400,
                                color: Colors.grey,
                                fontSize: 18 - animation.value * 4),
                          ),
                        ),
                      );
                    },
                  )
                ],
              ),
              const SizedBox(height: 22),
              InputArea(
                errorText: _birthdayErrorText,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _phoneFocusNode.unfocus();
                      _birthdayFocused = true;
                    });
                  },
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Birthday',
                        style: Theming.of(context).text.body.copyWith(
                            color: Colors.grey, fontWeight: FontWeight.w400),
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
                                    _birthdayErrorText =
                                        _validateBirthday(date);

                                    if (_phoneFocusNode.hasFocus ||
                                        !_birthdayFocused) {
                                      _phoneFocusNode.unfocus();
                                      _birthdayFocused = true;
                                    }
                                  });
                                },
                                dateFormat: 'MMM-dd-yyyy',
                                locale: DateTimePickerLocale.en_us,
                                pickerTheme: DateTimePickerTheme(
                                  itemTextStyle: Theming.of(context)
                                      .text
                                      .body
                                      .copyWith(
                                          fontWeight: FontWeight.w400,
                                          color: Colors.grey),
                                  backgroundColor: Colors.transparent,
                                  dividerColor: _birthdayFocused
                                      ? const Color.fromARGB(
                                          0xFF, 0xFF, 0x71, 0x71)
                                      : const Color.fromARGB(
                                          0x88, 0xFF, 0x71, 0x71),
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
              const SizedBox(height: 22),
              SignificantButton.pink(
                child: _submitting
                    ? const CircularProgressIndicator()
                    : const Text('Send code'),
                onPressed: _submitting || !_valid ? null : _submit,
              ),
              const Spacer(),
              const MaleFemaleConnectionImageApart(),
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
    return null;
  }

  void _submit() async {
    final phoneText = _phoneController.text;

    // American numbers are default audience
    final phone = phoneText.startsWith('+') ? phoneText : '+1$phoneText';

    setState(() => _phoneErrorText = _validatePhone(phone));

    if (_phoneErrorText == null && _birthdayErrorText == null) {
      setState(() => _submitting = true);

      final usersApi = ref.read(usersApiProvider);

      final success = await usersApi.checkBirthday(
        phone: phone,
        birthday: _birthday,
      );
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid details for existing user'),
          ),
        );
        setState(() => _submitting = false);
        return;
      }

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        verificationCompleted: (credential) async {
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
            await usersApi.createUserWithUid(
              uid: uid,
              birthday: _birthday,
              notificationToken: await FirebaseMessaging.instance.getToken(),
            );
            usersApi.uid = uid;
          }
          setState(() => _submitting = false);
        },
        verificationFailed: (FirebaseAuthException e) {
          print(e);
          String message;
          if (e.code == 'network-request-failed') {
            message = 'Network error';
          } else {
            message = 'Failed to send verification code';
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
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
