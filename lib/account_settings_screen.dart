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
import 'package:openup/contact_us_screen.dart';
import 'package:openup/notifications/notifications.dart';
import 'package:openup/settings_phone_verification_screen.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/phone_number_input.dart';
import 'package:openup/widgets/section.dart';

class AccountSettingsScreen extends ConsumerStatefulWidget {
  const AccountSettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AccountSettingsScreen> createState() =>
      _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends ConsumerState<AccountSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return ref.watch(userProvider2).map(
      guest: (_) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Log in to change settings'),
              ElevatedButton(
                onPressed: () => context.pushNamed('signup'),
                child: const Text('Log in'),
              ),
            ],
          ),
        );
      },
      signedIn: (signedIn) {
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
                      image:
                          AssetImage('assets/images/subscribe_background.png'),
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
              const _PhoneNumberField(),
              const SizedBox(height: 16),
              Button(
                onPressed: () {
                  showBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    builder: (context) {
                      return Container(
                        margin: EdgeInsets.only(
                            top: MediaQuery.of(context).padding.top + 48.0),
                        clipBehavior: Clip.hardEdge,
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(32),
                            topRight: Radius.circular(32),
                          ),
                        ),
                        child: const ContactUsScreen(),
                      );
                    },
                  );
                },
                child: const _CupertinoRow(
                  leading: Text('Contact us'),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: Color.fromRGBO(0xBA, 0xBA, 0xBA, 1.0),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Button(
                onPressed: () {
                  showBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    builder: (context) {
                      return Container(
                        margin: EdgeInsets.only(
                            top: MediaQuery.of(context).padding.top + 48.0),
                        clipBehavior: Clip.hardEdge,
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(32),
                            topRight: Radius.circular(32),
                          ),
                        ),
                        child: const _BlockedList(),
                      );
                    },
                  );
                },
                child: const _CupertinoRow(
                  leading: Text('Blocked users'),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: Color.fromRGBO(0xBA, 0xBA, 0xBA, 1.0),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Button(
                onPressed: _showSignOutConfirmationModal,
                child: const _CupertinoRow(
                  center: Text(
                    'Sign out',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Button(
                onPressed: _showDeleteAccountConfirmationModal,
                child: const _CupertinoRow(
                  center: Text(
                    'Delete Account',
                    style: TextStyle(color: Colors.red),
                  ),
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
      },
    );
  }

  void _showSignOutConfirmationModal() async {
    final result = await showCupertinoModalPopup<bool>(
      context: context,
      builder: (context) {
        return CupertinoActionSheet(
          title:
              const Text('Are you sure you want to sign out of your account?'),
          cancelButton: CupertinoActionSheetAction(
            onPressed: Navigator.of(context).pop,
            child: const Text('Cancel'),
          ),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () => Navigator.of(context).pop(true),
              isDestructiveAction: true,
              child: const Text('Sign out'),
            ),
          ],
        );
      },
    );
    if (mounted && result == true) {
      await withBlockingModal(
        context: context,
        label: 'Signing out',
        future: _signOut(),
      );

      if (mounted) {
        context.goNamed('initialLoading');
      }
    }
  }

  Future<void> _signOut() async {
    GetIt.instance.get<Mixpanel>().track("sign_out");
    ref.read(userProvider.notifier)
      ..uid('')
      ..profile(null)
      ..collections([]);
    ref.read(userProvider2.notifier).guest();
    await GetIt.instance.get<Api>().signOut();
    await dismissAllNotifications();
    if (Platform.isAndroid) {
      await FirebaseMessaging.instance.deleteToken();
    }
    await FirebaseAuth.instance.signOut();
  }

  void _showDeleteAccountConfirmationModal() async {
    final result = await showCupertinoModalPopup<bool>(
      context: context,
      builder: (context) {
        return CupertinoActionSheet(
          title: const Text(
              'This will permanently delete your bff conversations, contacts and profile'),
          cancelButton: CupertinoActionSheetAction(
            onPressed: Navigator.of(context).pop,
            child: const Text('Cancel'),
          ),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () => Navigator.of(context).pop(true),
              isDestructiveAction: true,
              child: const Text('Delete account'),
            ),
          ],
        );
      },
    );
    if (mounted && result == true) {
      await withBlockingModal(
        context: context,
        label: 'Deleting account',
        future: _deleteAccount(),
      );
      if (mounted) {
        context.goNamed('initialLoading');
      }
    }
  }

  Future<void> _deleteAccount() async {
    GetIt.instance.get<Mixpanel>().track("delete_account");
    ref.read(userProvider.notifier)
      ..uid('')
      ..profile(null)
      ..collections([]);
    ref.read(userProvider2.notifier).guest();
    await dismissAllNotifications();
    GetIt.instance.get<Api>().deleteAccount();
    await FirebaseAuth.instance.signOut();
  }
}

class _PhoneNumberField extends ConsumerStatefulWidget {
  const _PhoneNumberField({super.key});

  @override
  ConsumerState<_PhoneNumberField> createState() => _PhoneNumberFieldState();
}

class _PhoneNumberFieldState extends ConsumerState<_PhoneNumberField> {
  bool _editing = false;
  String? _newPhoneNumber;
  bool _newPhoneNumberValid = false;
  bool _submitting = false;
  int? _forceResendingToken;
  final _verificationCodeController = TextEditingController();

  @override
  void dispose() {
    _verificationCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: !_editing
          ? _CupertinoRow(
              leading:
                  Text(FirebaseAuth.instance.currentUser?.phoneNumber ?? ''),
              trailing: Button(
                onPressed: () {
                  setState(() => _editing = !_editing);
                },
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Edit',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
            )
          : DecoratedBox(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _CupertinoRow(
                    leading: PhoneInput(
                      onChanged: (value, valid) {
                        setState(() {
                          _newPhoneNumber = value;
                          _newPhoneNumberValid = valid;
                        });
                      },
                      onValidationError: (_) {},
                    ),
                    trailing: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'Send code',
                        style: TextStyle(
                          color: Color.fromRGBO(0x51, 0xA1, 0xFF, 1.0),
                        ),
                      ),
                    ),
                    decoration: const BoxDecoration(),
                  ),
                  const Divider(
                    height: 1,
                    indent: 20,
                  ),
                  _CupertinoRow(
                    leading: TextFormField(
                      controller: _verificationCodeController,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Verification code',
                        hintStyle: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: Color.fromRGBO(0x9B, 0x9B, 0x9B, 1.0),
                        ),
                      ),
                    ),
                    decoration: const BoxDecoration(),
                  ),
                  const Divider(
                    height: 1,
                    indent: 20,
                  ),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _verificationCodeController,
                    builder: (context, value, __) {
                      return Button(
                        onPressed: value.text.isEmpty
                            ? null
                            : () async {
                                setState(() => _submitting = true);
                                await Future.delayed(
                                    const Duration(seconds: 1));
                                if (mounted) {
                                  setState(() {
                                    _submitting = false;
                                    _editing = false;
                                  });
                                }
                              },
                        child: _CupertinoRow(
                          center: !_submitting
                              ? const Text(
                                  'Done',
                                  style: TextStyle(
                                    color:
                                        Color.fromRGBO(0x34, 0x78, 0xF6, 1.0),
                                  ),
                                )
                              : const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                          decoration: const BoxDecoration(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
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
    final api = GetIt.instance.get<Api>();
    api.getBlockedUsers().then((value) {
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
          body: LayoutBuilder(
            builder: (context, constraints) {
              return SizedBox(
                height: constraints.maxHeight,
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 44,
                      child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 16.0),
                              child: Button(
                                onPressed: Navigator.of(context).pop,
                                child: const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(
                                      color:
                                          Color.fromRGBO(0xFF, 0x00, 0x00, 1.0),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const Center(
                            child: Text(
                              'Blocked users',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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
                    Builder(
                      builder: (context) {
                        if (_loading) {
                          return const Center(
                            child: LoadingIndicator(
                              color: Colors.white,
                            ),
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
                        return Expanded(
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
                                          fontSize: 16,
                                          fontWeight: FontWeight.w400),
                                ),
                                trailing: Button(
                                  onPressed: () async {
                                    final result =
                                        await showCupertinoModalPopup(
                                      context: context,
                                      builder: (context) {
                                        return CupertinoActionSheet(
                                          title: Text('Unblock ${user.name}?'),
                                          message: Text(
                                              '${user.name} will be able to send you a friend request again. They won\'t be notified that you unblocked them.'),
                                          cancelButton:
                                              CupertinoActionSheetAction(
                                            onPressed:
                                                Navigator.of(context).pop,
                                            child: const Text('Cancel'),
                                          ),
                                          actions: [
                                            CupertinoActionSheetAction(
                                              onPressed: () =>
                                                  Navigator.of(context)
                                                      .pop(true),
                                              isDestructiveAction: true,
                                              child: const Text('Unblock'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                    if (result == true) {
                                      final api = GetIt.instance.get<Api>();
                                      final result =
                                          await api.unblockUser(user.uid);
                                      if (mounted) {
                                        result.fold(
                                          (l) => displayError(context, l),
                                          (r) =>
                                              setState(() => _blockedUsers = r),
                                        );
                                      }
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8, horizontal: 16),
                                    decoration: const BoxDecoration(
                                      color:
                                          Color.fromRGBO(0xFF, 0x00, 0x00, 1.0),
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
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CupertinoRow extends StatelessWidget {
  final Widget? leading;
  final Widget? center;
  final Widget? trailing;
  final BoxDecoration? decoration;

  const _CupertinoRow({
    super.key,
    this.leading,
    this.center,
    this.trailing,
    this.decoration,
  })  : assert(leading != null || center != null),
        assert((center == null && trailing == null) ||
            (center != null && trailing == null) ||
            (center == null && trailing != null));

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      clipBehavior: Clip.hardEdge,
      decoration: decoration ??
          const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(8)),
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
    );
  }
}
