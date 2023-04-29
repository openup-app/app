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
import 'package:openup/menu_page.dart';
import 'package:openup/notifications/notifications.dart';
import 'package:openup/settings_phone_verification_screen.dart';
import 'package:openup/widgets/back_button.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/dialog.dart';
import 'package:openup/widgets/phone_number_input.dart';
import 'package:openup/widgets/section.dart';

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
    return LayoutBuilder(builder: (context, constraints) {
      return Container(
        height: constraints.maxHeight,
        margin: EdgeInsets.only(
          top: 40,
          bottom: MediaQuery.of(context).padding.bottom,
          left: 16,
          right: 16,
        ),
        clipBehavior: Clip.hardEdge,
        decoration: const BoxDecoration(
          color: Color.fromRGBO(0xF2, 0xF2, 0xF6, 1.0),
          borderRadius: BorderRadius.all(
            Radius.circular(20),
          ),
        ),
        child: SingleChildScrollView(
          controller: PrimaryScrollControllerTemp.of(context),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 362),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Button(
                  onPressed: () {},
                  child: Container(
                    height: 343,
                    clipBehavior: Clip.hardEdge,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(
                            'assets/images/subscribe_background.png'),
                        fit: BoxFit.cover,
                      ),
                      borderRadius: BorderRadius.all(
                        Radius.circular(20),
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Subscribe',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '27 days remaining, then \$6.99/month',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SectionTitle(
                  title: Text('Phone Number'),
                ),
                const SizedBox(height: 8),
                _CupertinoButton(
                  leading: PhoneInput(
                    onChanged: (value, valid) {
                      setState(() {
                        _newPhoneNumber = value;
                        _newPhoneNumberValid = valid;
                      });
                    },
                    onValidationError: (_) {},
                  ),
                  trailing: Button(
                    onPressed: () {},
                    child: const Text(
                      'Edit',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ),
                // const SizedBox(height: 16),
                // SizedBox(
                //   width: 237,
                //   child: Button(
                //     onPressed: (_submitting | !_newPhoneNumberValid ||
                //             _newPhoneNumber?.isEmpty == true)
                //         ? null
                //         : _updateInformation,
                //     child: _InputArea(
                //       childNeedsOpacity: false,
                //       gradientColors: const [
                //         Color.fromRGBO(0xFF, 0x3B, 0x3B, 0.65),
                //         Color.fromRGBO(0xFF, 0x33, 0x33, 0.54),
                //       ],
                //       child: Center(
                //         child: _submitting
                //             ? const LoadingIndicator()
                //             : Text(
                //                 'Update Information',
                //                 style: Theme.of(context)
                //                     .textTheme
                //                     .bodyMedium!
                //                     .copyWith(
                //                       fontSize: 24,
                //                       fontWeight: FontWeight.w500,
                //                     ),
                //               ),
                //       ),
                //     ),
                //   ),
                // ),
                const SizedBox(height: 16),
                _CupertinoButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) {
                          return const _BlockedList();
                        },
                      ),
                    );
                  },
                  leading: const Text('Blocked users'),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: Color.fromRGBO(0xBA, 0xBA, 0xBA, 1.0),
                  ),
                ),
                const SizedBox(height: 16),
                _CupertinoButton(
                  onPressed: () => context.pushNamed('contact-us'),
                  leading: const Text('Contact us'),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: Color.fromRGBO(0xBA, 0xBA, 0xBA, 1.0),
                  ),
                ),
                const SizedBox(height: 16),
                _CupertinoButton(
                  onPressed: _signOut,
                  center: const Text(
                    'Sign out',
                  ),
                ),
                const SizedBox(height: 16),
                _CupertinoButton(
                  onPressed: _showDeleteAccountDialog,
                  center: const Text(
                    'Delete Account',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                if (kDebugMode) ...[
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      '${FirebaseAuth.instance.currentUser?.uid}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      '${FirebaseAuth.instance.currentUser?.phoneNumber}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
        ),
      );
    });
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
    await withBlockingModal(
      context: context,
      label: 'Signing out',
      future: Future(() async {
        GetIt.instance.get<Mixpanel>().track("sign_out");
        final uid = ref.read(userProvider).uid;
        await GetIt.instance.get<Api>().signOut(uid);
        await dismissAllNotifications();
        if (Platform.isAndroid) {
          await FirebaseMessaging.instance.deleteToken();
        }
        await FirebaseAuth.instance.signOut();
      }),
    );

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
        color: Color.fromRGBO(0xF2, 0xF2, 0xF6, 1.0),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: const BackIconButton(),
          title: Text(
            'Blocking',
            style: Theme.of(context)
                .textTheme
                .bodyMedium!
                .copyWith(color: Colors.black),
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

class _CupertinoButton extends StatelessWidget {
  final Widget? leading;
  final Widget? center;
  final Widget? trailing;
  final VoidCallback? onPressed;

  const _CupertinoButton({
    super.key,
    this.leading,
    this.center,
    this.trailing,
    this.onPressed,
  })  : assert(leading != null || center != null),
        assert((center == null && trailing == null) ||
            (center != null && trailing == null) ||
            (center == null && trailing != null));

  @override
  Widget build(BuildContext context) {
    return Button(
      onPressed: onPressed,
      useFadeWheNoPressedCallback: false,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        clipBehavior: Clip.hardEdge,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(
            Radius.circular(8),
          ),
        ),
        child: DefaultTextStyle(
          style: Theme.of(context)
              .textTheme
              .bodyMedium!
              .copyWith(fontSize: 15, fontWeight: FontWeight.w400),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (leading != null)
                Expanded(
                  child: leading!,
                ),
              if (center != null)
                Center(
                  child: center,
                ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}
