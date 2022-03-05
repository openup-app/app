import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/notifications/notifications.dart';
import 'package:openup/widgets/back_button.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/dialog.dart';
import 'package:openup/widgets/home_button.dart';
import 'package:openup/widgets/theming.dart';

class AccountSettingsScreen extends ConsumerStatefulWidget {
  const AccountSettingsScreen({Key? key}) : super(key: key);

  @override
  _AccountSettingsScreenState createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends ConsumerState<AccountSettingsScreen> {
  static final _phoneRegex = RegExp(r'^(?:[+0][1-9])?[0-9]{10,12}$');
  final _phoneNumberController = TextEditingController();
  bool _submitting = false;
  int? _forceResendingToken;

  @override
  void dispose() {
    _phoneNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: Colors.black),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromRGBO(0xFF, 0x8E, 0x8E, 1.0),
              Color.fromRGBO(0x20, 0x84, 0xBD, 0.74),
            ],
          ),
        ),
        child: Stack(
          fit: StackFit.loose,
          children: [
            Positioned(
              top: MediaQuery.of(context).padding.top + 24,
              left: 8,
              child: Transform.scale(
                scale: 1.3,
                child: const BackIconButton(),
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 362),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        Center(
                          child: Text(
                            'Account Settings',
                            style: Theming.of(context).text.body.copyWith(
                                fontSize: 30, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const Spacer(),
                        Center(
                          child: Text(
                            'Update login information',
                            style: Theming.of(context).text.body.copyWith(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _InputArea(
                          child: _TextField(
                            controller: _phoneNumberController,
                            keyboardType: TextInputType.phone,
                            hintText: 'phone number',
                          ),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: 237,
                          child: Button(
                            onPressed: _submitting ? null : _updateInformation,
                            child: _InputArea(
                              childNeedsOpacity: false,
                              opacity: 0.8,
                              gradientColors: const [
                                Color.fromRGBO(0xFF, 0x3B, 0x3B, 0.65),
                                Color.fromRGBO(0xFF, 0x33, 0x33, 0.54),
                              ],
                              child: Center(
                                child: _submitting
                                    ? const CircularProgressIndicator()
                                    : Text(
                                        'Update Information',
                                        style: Theming.of(context)
                                            .text
                                            .body
                                            .copyWith(
                                                fontSize: 24,
                                                fontWeight: FontWeight.w500),
                                      ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Button(
                          onPressed: () =>
                              Navigator.of(context).pushNamed('contact-us'),
                          child: _InputArea(
                            childNeedsOpacity: false,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    margin: const EdgeInsets.only(left: 16),
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color:
                                          Color.fromRGBO(0xC4, 0xC4, 0xC4, 1.0),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(10.0),
                                      child: Text(
                                        '?',
                                        textAlign: TextAlign.center,
                                        style: Theming.of(context)
                                            .text
                                            .body
                                            .copyWith(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Contact us',
                                  style: Theming.of(context).text.body.copyWith(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        Button(
                          onPressed: _signOut,
                          child: _InputArea(
                            childNeedsOpacity: false,
                            child: Center(
                              child: Text(
                                'Sign Out',
                                style: Theming.of(context).text.body.copyWith(
                                    fontSize: 24, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        Button(
                          onPressed: _showDeleteAccountDialog,
                          child: _InputArea(
                            opacity: 0.5,
                            gradientColors: const [
                              Color.fromRGBO(0xFF, 0x00, 0x00, 1.0),
                              Color.fromRGBO(0xFF, 0x00, 0x00, 1.0),
                            ],
                            childNeedsOpacity: false,
                            child: Center(
                              child: Text(
                                'Delete Account',
                                style: Theming.of(context).text.body.copyWith(
                                    fontSize: 24, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ),
                        ),
                        const Spacer(flex: 2),
                        if (kDebugMode)
                          Container(
                            color: Colors.white,
                            margin:
                                const EdgeInsets.symmetric(horizontal: 40.0),
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    '${FirebaseAuth.instance.currentUser?.uid}'),
                                const Divider(),
                                Text(
                                    '${FirebaseAuth.instance.currentUser?.phoneNumber}'),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: MediaQuery.of(context).padding.right + 16,
              bottom: MediaQuery.of(context).padding.bottom + 16,
              child: const HomeButton(
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateInformation() async {
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);
    final value = _phoneNumberController.text;
    if (value.isEmpty) {
      return;
    }

    final validation = _validatePhone(value);
    if (validation != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validation),
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw 'No user is logged in';
    }

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: value,
      verificationCompleted: (credential) async {
        try {
          await user.updatePhoneNumber(credential);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Successfully updated phone number'),
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Something went wrong'),
            ),
          );
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
        await Navigator.of(context).pushNamed(
          'account-settings-phone-verification',
          arguments: verificationId,
        );
        setState(() => _submitting = false);
      },
      forceResendingToken: _forceResendingToken,
      codeAutoRetrievalTimeout: (verificationId) {
        // Android SMS auto-fill failed, nothing to do
      },
    );
  }

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

  void _signOut() async {
    await dismissAllNotifications();
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacementNamed('/');
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return OpenupDialog(
          title: Text(
            'Are you sure you want to delete your account?',
            textAlign: TextAlign.center,
            style: Theming.of(context).text.body.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final uid = ref.read(userProvider).uid;
                await dismissAllNotifications();
                GetIt.instance.get<Api>().deleteUser(uid);
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).popUntil((route) => route.isFirst);
                Navigator.of(context).pushReplacementNamed('/');
              },
              child: Text(
                'Delete',
                style: Theming.of(context).text.body.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.w500,
                      color: Colors.red,
                    ),
              ),
            ),
            TextButton(
              onPressed: Navigator.of(context).pop,
              child: Text(
                'Cancel',
                style: Theming.of(context).text.body.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _InputArea extends StatelessWidget {
  final Widget child;
  final List<Color> gradientColors;
  final double opacity;
  final bool childNeedsOpacity;
  const _InputArea({
    Key? key,
    required this.child,
    this.gradientColors = const [
      Color.fromRGBO(0xFF, 0xFF, 0xFF, 0.65),
      Color.fromRGBO(0xFF, 0xFF, 0xFF, 0.54),
    ],
    this.opacity = 0.6,
    this.childNeedsOpacity = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 57,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Opacity(
            opacity: opacity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: gradientColors,
                ),
                borderRadius: const BorderRadius.all(Radius.circular(29)),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(0x00, 0x00, 0x00, 0.25),
                    offset: Offset(0.0, 4.0),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: childNeedsOpacity ? child : null,
            ),
          ),
          if (!childNeedsOpacity) child,
        ],
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String hintText;

  const _TextField({
    Key? key,
    required this.controller,
    this.keyboardType,
    required this.hintText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(left: 24.0),
        child: TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration.collapsed(
            hintText: hintText,
            hintStyle: Theming.of(context).text.body.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
          ),
        ),
      ),
    );
  }
}
