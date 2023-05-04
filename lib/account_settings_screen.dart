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
    return Container(
      margin: EdgeInsets.only(
        top: 24 + MediaQuery.of(context).padding.top,
        left: 16,
        right: 16,
        bottom: 16 + MediaQuery.of(context).padding.bottom,
      ),
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(
        color: Color.fromRGBO(0xF2, 0xF2, 0xF6, 1.0),
        borderRadius: BorderRadius.all(
          Radius.circular(20),
        ),
      ),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Button(
            onPressed: () {},
            child: Container(
              height: 343,
              clipBehavior: Clip.hardEdge,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/subscribe_background.png'),
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
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '27 days remaining, then \$6.99/month',
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
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
    return Theme(
      data: ThemeData.dark(),
      child: CupertinoTheme(
        data: const CupertinoThemeData(brightness: Brightness.dark),
        child: Scaffold(
          appBar: AppBar(
            leading: const BackIconButton(),
            title: const Text('Blocked users'),
            backgroundColor: Colors.transparent,
            elevation: 0.0,
            centerTitle: true,
          ),
          body: StatefulBuilder(
            builder: (context, setState) {
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
              return Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'Here is the list of users you have blocked on bff',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Color.fromRGBO(0x9D, 0x9D, 0x9D, 1.0),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _blockedUsers.length,
                      itemBuilder: (context, index) {
                        final user = _blockedUsers[index];
                        return ListTile(
                          leading: Container(
                            width: 45,
                            height: 45,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                            ),
                            clipBehavior: Clip.hardEdge,
                            child: Image.network(
                              user.photo,
                              fit: BoxFit.cover,
                            ),
                          ),
                          title: AutoSizeText(
                            user.name,
                            maxLines: 1,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                    fontSize: 16, fontWeight: FontWeight.w400),
                          ),
                          trailing: Button(
                            onPressed: () async {
                              final result = await showCupertinoModalPopup(
                                context: context,
                                builder: (context) {
                                  return CupertinoActionSheet(
                                    title: Text('Unblock ${user.name}?'),
                                    message: Text(
                                        '${user.name} will be able to send you a friend request again. They won\'t be notified that you unblocked them.'),
                                    cancelButton: CupertinoActionSheetAction(
                                      onPressed: Navigator.of(context).pop,
                                      child: const Text('Cancel'),
                                    ),
                                    actions: [
                                      CupertinoActionSheetAction(
                                        onPressed: () =>
                                            Navigator.of(context).pop(true),
                                        isDestructiveAction: true,
                                        child: const Text('Unblock'),
                                      ),
                                    ],
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
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 16),
                              decoration: const BoxDecoration(
                                color: Color.fromRGBO(0xFF, 0x00, 0x00, 1.0),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(8)),
                              ),
                              child: Text(
                                'Unblock',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium!
                                    .copyWith(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
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
