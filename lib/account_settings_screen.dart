import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/notifications/notifications.dart';
import 'package:openup/settings_phone_verification_screen.dart';
import 'package:openup/widgets/back_button.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/dialog.dart';
import 'package:openup/widgets/home_button.dart';
import 'package:openup/widgets/phone_number_input.dart';

class AccountSettingsScreen extends ConsumerStatefulWidget {
  const AccountSettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AccountSettingsScreen> createState() =>
      _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends ConsumerState<AccountSettingsScreen> {
  String? _newPhoneNumber;
  bool _newPhoneNumberValid = false;
  bool _submitting = false;
  int? _forceResendingToken;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: const BackIconButton(),
        title: Text(
          'Account Settings',
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        fit: StackFit.loose,
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 362),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        'Update login information',
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              fontSize: 24,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _InputArea(
                      child: PhoneInput(
                        color: Colors.white,
                        hintTextColor: Colors.grey.shade300,
                        onChanged: (value, valid) {
                          setState(() {
                            _newPhoneNumber = value;
                            _newPhoneNumberValid = valid;
                          });
                        },
                        onValidationError: (_) {},
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: 237,
                      child: Button(
                        onPressed: (_submitting | !_newPhoneNumberValid ||
                                _newPhoneNumber?.isEmpty == true)
                            ? null
                            : _updateInformation,
                        child: _InputArea(
                          childNeedsOpacity: false,
                          gradientColors: const [
                            Color.fromRGBO(0xFF, 0x3B, 0x3B, 0.65),
                            Color.fromRGBO(0xFF, 0x33, 0x33, 0.54),
                          ],
                          child: Center(
                            child: _submitting
                                ? const LoadingIndicator()
                                : Text(
                                    'Update Information',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium!
                                        .copyWith(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Button(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) {
                              return const _BlockedList();
                            },
                          ),
                        );
                      },
                      child: _InputArea(
                        childNeedsOpacity: false,
                        child: Center(
                          child: Text(
                            'Blocked users',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Button(
                      onPressed: () => context.pushNamed('contact-us'),
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
                                  color: Color.fromRGBO(0xC4, 0xC4, 0xC4, 1.0),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Text(
                                    '?',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium!
                                        .copyWith(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Contact us',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Button(
                      onPressed: _signOut,
                      child: _InputArea(
                        childNeedsOpacity: false,
                        child: Center(
                          child: Text(
                            'Sign Out',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    Button(
                      onPressed: _showDeleteAccountDialog,
                      child: _InputArea(
                        gradientColors: const [
                          Color.fromRGBO(0xFF, 0x00, 0x00, 1.0),
                          Color.fromRGBO(0xFF, 0x00, 0x00, 1.0),
                        ],
                        childNeedsOpacity: false,
                        child: Center(
                          child: Text(
                            'Delete Account',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(flex: 2),
                    if (kDebugMode)
                      Container(
                        color: Colors.white,
                        margin: const EdgeInsets.symmetric(horizontal: 40.0),
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${FirebaseAuth.instance.currentUser?.uid}'),
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
          Positioned(
            right: MediaQuery.of(context).padding.right + 16,
            bottom: MediaQuery.of(context).padding.bottom + 16,
            child: const HomeButton(
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _updateInformation() async {
    GetIt.instance.get<Mixpanel>().track("change_phone_number");
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);
    final newPhoneNumber = _newPhoneNumber;
    if (newPhoneNumber == null || !_newPhoneNumberValid) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw 'No user is logged in';
    }

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: newPhoneNumber,
      verificationCompleted: (credential) async {
        try {
          await user.updatePhoneNumber(credential);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Successfully updated phone number'),
              ),
            );
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

        setState(() => _submitting = false);
      },
      verificationFailed: (FirebaseAuthException e) {
        debugPrint(e.toString());
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
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) {
              return SettingsPhoneVerificationScreen(
                verificationId: verificationId,
              );
            },
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

  void _signOut() async {
    GetIt.instance.get<Mixpanel>().track("sign_out");
    final uid = ref.read(userProvider).uid;
    await GetIt.instance.get<Api>().signOut(uid);
    await dismissAllNotifications();
    if (Platform.isAndroid) {
      await FirebaseMessaging.instance.deleteToken();
    }
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      context.goNamed('initialLoading');
    }
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return OpenupDialog(
          title: Text(
            'Are you sure you want to delete your account?',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                GetIt.instance.get<Mixpanel>().track("delete_account");
                final uid = ref.read(userProvider).uid;
                await dismissAllNotifications();
                GetIt.instance.get<Api>().deleteUser(uid);
                await FirebaseAuth.instance.signOut();
                if (mounted) {
                  context.goNamed('initialLoading');
                }
              },
              child: Text(
                'Delete',
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
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
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
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

class _BlockedList extends ConsumerStatefulWidget {
  const _BlockedList({Key? key}) : super(key: key);

  @override
  _BlockedListState createState() => _BlockedListState();
}

class _BlockedListState extends ConsumerState<_BlockedList> {
  List<SimpleProfile> _blockedUsers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _getBlockedUsers();
  }

  void _getBlockedUsers() {
    final uid = ref.read(userProvider).uid;
    final api = GetIt.instance.get<Api>();
    api.getBlockedUsers(uid).then((value) {
      if (mounted) {
        value.fold(
          (l) => displayError(context, l),
          (r) {
            setState(() {
              _blockedUsers = r..sort((a, b) => a.name.compareTo(b.name));
              _loading = false;
            });
          },
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.black,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: const BackIconButton(),
          title: Text(
            'Blocking',
            style:
                Theme.of(context).textTheme.bodyMedium!.copyWith(fontSize: 24),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0.0,
          centerTitle: true,
        ),
        body: StatefulBuilder(builder: (context, setState) {
          if (_loading) {
            return const Center(
              child: LoadingIndicator(),
            );
          }
          if (_blockedUsers.isEmpty) {
            return Center(
              child: Text(
                'You are not blocking anyone',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium!
                    .copyWith(fontSize: 20),
              ),
            );
          }
          return ListView.builder(
            itemCount: _blockedUsers.length,
            itemBuilder: (context, index) {
              final user = _blockedUsers[index];
              return Container(
                height: 57,
                margin: const EdgeInsets.symmetric(horizontal: 27, vertical: 7),
                padding: const EdgeInsets.only(left: 37, right: 29),
                clipBehavior: Clip.hardEdge,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color.fromRGBO(0xFF, 0xFF, 0xFF, 0.65),
                      Color.fromRGBO(0xFF, 0xFF, 0xFF, 0.54),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.all(
                    Radius.circular(29),
                  ),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 10,
                      offset: Offset(0.0, 4.0),
                      color: Color.fromRGBO(0x00, 0x00, 0x00, 0.25),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: AutoSizeText(
                        user.name,
                        maxLines: 1,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              fontSize: 24,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                    TextButton(
                      child: Text(
                        'Unblock',
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              fontSize: 24,
                              fontWeight: FontWeight.w500,
                              color:
                                  const Color.fromRGBO(0xB6, 0x0B, 0x0B, 1.0),
                            ),
                      ),
                      onPressed: () async {
                        final result = await showDialog(
                          context: context,
                          builder: (context) {
                            return CupertinoTheme(
                              data: const CupertinoThemeData(
                                  brightness: Brightness.dark),
                              child: CupertinoAlertDialog(
                                title: Text('Unblock ${user.name}?'),
                                actions: [
                                  CupertinoDialogAction(
                                    onPressed: Navigator.of(context).pop,
                                    child: const Text('Cancel'),
                                  ),
                                  CupertinoDialogAction(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: const Text('Unblock'),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                        if (result == true) {
                          final myUid = ref.read(userProvider).uid;
                          final api = GetIt.instance.get<Api>();
                          setState(() => _loading = true);
                          await api.unblockUser(myUid, user.uid);
                          if (mounted) {
                            _getBlockedUsers();
                          }
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

class _InputArea extends StatelessWidget {
  final Widget child;
  final List<Color> gradientColors;
  final bool childNeedsOpacity;
  const _InputArea({
    Key? key,
    required this.child,
    this.gradientColors = const [
      Color.fromRGBO(0xFF, 0xFF, 0xFF, 0.65),
      Color.fromRGBO(0xFF, 0xFF, 0xFF, 0.54),
    ],
    this.childNeedsOpacity = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 57,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
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
          if (!childNeedsOpacity) child,
        ],
      ),
    );
  }
}
