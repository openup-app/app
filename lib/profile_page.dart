import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:openup/analytics/analytics.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/view_profile_page.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/collection_photo_stack.dart';
import 'package:openup/widgets/collections_preview_list.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/gallery.dart';
import 'package:openup/widgets/phone_number_input.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePage2State();
}

class _ProfilePage2State extends ConsumerState<ProfilePage> {
  bool _showCollectionCreation = false;
  final _scrollController = ScrollController();
  Timer? _animationTimer;

  @override
  void dispose() {
    _scrollController.dispose();
    _animationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ref.watch(userProvider2).map(
      guest: (_) {
        return Container(
          color: const Color.fromRGBO(0xF5, 0xF5, 0xF5, 1.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Log in to create a profile'),
                ElevatedButton(
                  onPressed: () => context.pushNamed('signup'),
                  child: const Text('Log in'),
                ),
              ],
            ),
          ),
        );
      },
      signedIn: (signedIn) {
        final profile = signedIn.account.profile;
        return ColoredBox(
          color: const Color.fromRGBO(0xF5, 0xF5, 0xF5, 1.0),
          child: Container(
            margin: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 20,
              bottom: 16 + MediaQuery.of(context).padding.bottom,
            ),
            clipBehavior: Clip.hardEdge,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(48)),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  controller: _scrollController,
                  child: Builder(
                    builder: (context) {
                      if (!_showCollectionCreation) {
                        return Column(
                          children: [
                            Container(
                              height: constraints.maxHeight,
                              clipBehavior: Clip.hardEdge,
                              decoration: const BoxDecoration(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(48)),
                              ),
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: CinematicGallery(
                                      slideshow: true,
                                      gallery: profile.collection.photos,
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.bottomCenter,
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 30),
                                      child: Button(
                                        onPressed: () =>
                                            _showRecordPanel(context),
                                        child: Container(
                                          width: 146,
                                          height: 51,
                                          alignment: Alignment.center,
                                          decoration: const BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Color.fromRGBO(
                                                    0xF3, 0x49, 0x50, 1.0),
                                                Color.fromRGBO(
                                                    0xDF, 0x39, 0x3F, 1.0),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(25)),
                                            boxShadow: [
                                              BoxShadow(
                                                offset: Offset(0, 4),
                                                blurRadius: 4,
                                                color: Color.fromRGBO(
                                                    0x00, 0x00, 0x00, 0.25),
                                              ),
                                            ],
                                          ),
                                          child: Text(
                                            'update bio',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium!
                                                .copyWith(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w400,
                                                    color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    right: 14,
                                    bottom: 30,
                                    width: 48,
                                    height: 48,
                                    child: Button(
                                      onPressed: () {
                                        _scrollController.animateTo(
                                          _scrollController
                                              .position.maxScrollExtent,
                                          duration:
                                              const Duration(milliseconds: 200),
                                          curve: Curves.easeOut,
                                        );
                                      },
                                      child: Center(
                                        child: Container(
                                          width: 29,
                                          height: 29,
                                          alignment: Alignment.center,
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                offset: Offset(0, 2),
                                                blurRadius: 4,
                                                color: Color.fromRGBO(
                                                    0x00, 0x00, 0x00, 0.25),
                                              ),
                                            ],
                                          ),
                                          child: const RotatedBox(
                                            quarterTurns: 1,
                                            child: Icon(
                                              Icons.chevron_right,
                                              color: Color.fromRGBO(
                                                  0x71, 0x71, 0x71, 1.0),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 189,
                              child: Builder(
                                builder: (context) {
                                  final collections =
                                      signedIn.collections ?? [];
                                  return CollectionsPreviewList(
                                    collections: collections,
                                    play: _showCollectionCreation == false,
                                    leadingChildren: [
                                      _BottomButton(
                                        label: 'Create Collection',
                                        icon: const Icon(Icons.collections),
                                        onPressed: () => setState(() =>
                                            _showCollectionCreation = true),
                                      ),
                                    ],
                                    onView: (index) {
                                      context.pushNamed(
                                        'view_profile',
                                        extra: ViewProfilePageArguments.profile(
                                          profile: profile,
                                        ),
                                      );
                                    },
                                    onLongPress: (index) => _showDeleteDialog(
                                        collections[index].collectionId),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            DefaultTextStyle(
                              style: const TextStyle(color: Colors.white),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const _SectionTitle(label: 'Name'),
                                  const _CupertinoRow(
                                    leading: _NameField(),
                                  ),
                                  const SizedBox(height: 12),
                                  const _SectionTitle(
                                    label: 'Phone Number',
                                  ),
                                  const SizedBox(height: 8),
                                  const _PhoneNumberField(),
                                  const SizedBox(height: 16),
                                  Button(
                                    onPressed: () =>
                                        context.pushNamed('contacts'),
                                    child: const _CupertinoRow(
                                      leading: Row(
                                        children: [
                                          Icon(
                                            CupertinoIcons.book,
                                            color: Color.fromRGBO(
                                                0xBA, 0xBA, 0xBA, 1.0),
                                          ),
                                          SizedBox(width: 12),
                                          Expanded(child: Text(' My Contacts')),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Button(
                                    onPressed: () =>
                                        context.pushNamed('blocked'),
                                    child: const _CupertinoRow(
                                      leading: Text('Blocked users'),
                                      trailing: Icon(
                                        Icons.chevron_right,
                                        color: Color.fromRGBO(
                                            0xBA, 0xBA, 0xBA, 1.0),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Button(
                                    onPressed: () =>
                                        context.pushNamed('contact_us'),
                                    child: const _CupertinoRow(
                                      leading: Text('Contact us'),
                                      trailing: Icon(
                                        Icons.chevron_right,
                                        color: Color.fromRGBO(
                                            0xBA, 0xBA, 0xBA, 1.0),
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
                                    onPressed:
                                        _showDeleteAccountConfirmationModal,
                                    child: const _CupertinoRow(
                                      center: Text(
                                        'Delete Account',
                                        style: TextStyle(
                                          color: Color.fromRGBO(
                                              0xFF, 0x00, 0x00, 1.0),
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (kDebugMode) ...[
                                    const SizedBox(height: 16),
                                    Center(
                                      child: Text(
                                        '${FirebaseAuth.instance.currentUser?.uid}',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            color: Colors.black),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Center(
                                      child: Text(
                                        '${FirebaseAuth.instance.currentUser?.phoneNumber}',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            color: Colors.black),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    height: MediaQuery.of(context)
                                        .viewInsets
                                        .bottom,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      } else {
                        return SizedBox(
                          height: constraints.maxHeight,
                          child: _CollectionCreation(
                            onDone: () =>
                                setState(() => _showCollectionCreation = false),
                          ),
                        );
                      }
                    },
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _showRecordPanel(BuildContext context) {
    return showModalBottomSheet<Uint8List>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return RecordPanelSurface(
          child: RecordPanel(
            title: const Text('Updating Audio Bio'),
            submitLabel: const Text('Update'),
            onCancel: Navigator.of(context).pop,
            onSubmit: (audio, _) async {
              final userStateNotifier = ref.read(userProvider2.notifier);
              final success = await userStateNotifier.updateAudioBio(audio);
              if (success) {
                _animationTimer?.cancel();
                _animationTimer = Timer(const Duration(milliseconds: 1500), () {
                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                });
              }
              return success;
            },
          ),
        );
      },
    );
  }

  void _showDeleteDialog(String collectionId) async {
    final result = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text('Delete collection?'),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(true),
              isDestructiveAction: true,
              child: const Text('Delete'),
            ),
            CupertinoDialogAction(
              onPressed: Navigator.of(context).pop,
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
    if (result == true && mounted) {
      final deleteResult =
          await ref.read(userProvider2.notifier).deleteCollection(collectionId);
      if (mounted) {
        deleteResult.fold(
          (l) => displayError(context, l),
          (r) {},
        );
      }
    }
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
    ref.read(mixpanelProvider).track("sign_out");
    ref.read(userProvider.notifier)
      ..uid('')
      ..profile(null)
      ..collections([]);
    ref.read(userProvider2.notifier).guest();
    ref.read(apiProvider).signOut();
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
              'This will permanently delete your UT Meets conversations, contacts and profile'),
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
    ref.read(mixpanelProvider).track("delete_account");
    ref.read(userProvider.notifier)
      ..uid('')
      ..profile(null)
      ..collections([]);
    ref.read(userProvider2.notifier).guest();
    ref.read(apiProvider).deleteAccount();
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
                    style: TextStyle(
                      color: Color.fromRGBO(0xFF, 0x74, 0x74, 1.0),
                    ),
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
    ref.read(mixpanelProvider).track("change_phone_number");
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
              // Removed settings phone verification screen
              return const SizedBox.shrink();
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
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Colors.black,
        ),
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

class _BottomButton extends StatelessWidget {
  final String label;
  final Icon icon;
  final VoidCallback? onPressed;
  const _BottomButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Button(
      onPressed: onPressed,
      child: Container(
        alignment: Alignment.bottomLeft,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromRGBO(0xFF, 0x7F, 0x7A, 1.0),
              Color.fromRGBO(0xFC, 0x35, 0x35, 1.0),
            ],
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: icon,
            ),
            Positioned(
              left: 8,
              bottom: 8,
              right: 8,
              child: Text(
                label,
                textAlign: TextAlign.start,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                    color: Colors.white),
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String label;

  const _SectionTitle({
    super.key,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodyMedium!
              .copyWith(fontSize: 13, fontWeight: FontWeight.w400),
        ),
      ),
    );
  }
}

class _NameField extends ConsumerStatefulWidget {
  const _NameField({super.key});

  @override
  ConsumerState<_NameField> createState() => _NameFieldState();
}

class _NameFieldState extends ConsumerState<_NameField> {
  bool _editingName = false;
  final _nameFocusNode = FocusNode();
  final _nameController = TextEditingController();
  bool _initial = true;
  bool _submittingName = false;

  @override
  void initState() {
    super.initState();
    ref.listenManual<UserState2?>(
      userProvider2,
      (previous, next) {
        if (_initial && next != null) {
          next.map(
            guest: (_) {},
            signedIn: (signedIn) {
              _initial = false;
              _nameController.text = signedIn.account.profile.name;
            },
          );
        }
      },
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _nameFocusNode.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _nameController,
              autofocus: true,
              focusNode: _nameFocusNode,
              enabled: _editingName,
              textCapitalization: TextCapitalization.sentences,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: DefaultTextStyle.of(context).style.color,
              ),
              decoration: const InputDecoration.collapsed(
                hintText: '',
              ),
            ),
          ),
        ),
        Button(
          onPressed: () async {
            if (!_editingName) {
              setState(() => _editingName = true);
              FocusScope.of(context).requestFocus(_nameFocusNode);
            } else {
              setState(() => _submittingName = true);
              final result = await ref
                  .read(userProvider2.notifier)
                  .updateName(_nameController.text);
              if (mounted) {
                setState(() => _submittingName = false);
                result.fold(
                  (l) => displayError(context, l),
                  (r) {
                    setState(() => _editingName = false);
                    _nameFocusNode.unfocus();
                  },
                );
              }
            }
          },
          child: Builder(
            builder: (context) {
              if (_submittingName) {
                return const Padding(
                  padding: EdgeInsets.only(right: 12.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),
                );
              }
              if (!_editingName) {
                return const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Edit',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Color.fromRGBO(0xFF, 0x74, 0x74, 1.0),
                    ),
                  ),
                );
              } else {
                return const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Done',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Color.fromRGBO(0x03, 0x58, 0xFF, 1.0)),
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }
}

class _CollectionCreation extends ConsumerStatefulWidget {
  final VoidCallback onDone;

  const _CollectionCreation({
    super.key,
    required this.onDone,
  });

  @override
  ConsumerState<_CollectionCreation> createState() =>
      __CollectionCreationState();
}

class __CollectionCreationState extends ConsumerState<_CollectionCreation> {
  final _photos = <File?>[null, null, null];
  File? _audio;
  _CreationStep _step = _CreationStep.photos;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        widget.onDone();
        return Future.value(false);
      },
      child: Column(
        children: [
          SizedBox(
            height: 40,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Button(
                      onPressed: () {
                        switch (_step) {
                          case _CreationStep.photos:
                            widget.onDone();
                            break;
                          case _CreationStep.upload:
                            setState(() => _step = _CreationStep.photos);
                            break;
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_step != _CreationStep.photos) ...[
                              const Icon(
                                Icons.chevron_left,
                                color: Colors.black,
                              ),
                              const SizedBox(width: 8),
                            ],
                            Text(
                              _step == _CreationStep.photos ? 'Cancel' : 'Back',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_step == _CreationStep.photos)
                    Center(
                      child: Text(
                        '${_photos.length}/3',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            fontSize: 16, fontWeight: FontWeight.w400),
                      ),
                    ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Visibility(
                      visible: _step != _CreationStep.upload,
                      child: Button(
                        onPressed: _photos.whereType<File>().length < 3
                            ? null
                            : () {
                                switch (_step) {
                                  case _CreationStep.photos:
                                    setState(
                                        () => _step = _CreationStep.upload);
                                    break;
                                  case _CreationStep.upload:
                                    // Ignore
                                    break;
                                }
                              },
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Next',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium!
                                    .copyWith(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.chevron_right,
                                color: Colors.black,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Builder(
              builder: (context) {
                switch (_step) {
                  case _CreationStep.photos:
                    return _SimpleCollectionPhotoPicker(
                      photos: _photos,
                      onPhotosUpdated: (photos) {
                        setState(() => _photos
                          ..clear()
                          ..addAll(photos));
                      },
                    );
                  case _CreationStep.upload:
                    return _UploadStep(
                      photos: _photos.whereType<File>().toList(),
                      onUpload: _uploadCollection,
                      onDelete: widget.onDone,
                    );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  void _uploadCollection() async {
    final photos = _photos.whereType<File>().toList();
    if (photos.length < 3) {
      return;
    }

    final notifier = ref.read(userProvider2.notifier);
    final createCollectionFuture = notifier.createCollection(
      photos: photos,
      audio: _audio,
    );

    final result = await withBlockingModal(
      context: context,
      label: 'Uploading',
      future: createCollectionFuture,
    );
    if (!mounted) {
      return;
    }

    result.fold(
      (l) => displayError(context, l),
      (r) async {
        await showCupertinoDialog(
          context: context,
          builder: (context) {
            return CupertinoAlertDialog(
              title: const Text('Collection uploaded'),
              content: const Text(
                  'You will be notified when it has finished processing'),
              actions: [
                CupertinoDialogAction(
                  onPressed: Navigator.of(context).pop,
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
        widget.onDone();
      },
    );
  }
}

class _SimpleCollectionPhotoPicker extends StatefulWidget {
  final List<File?> photos;
  final ValueChanged<List<File?>> onPhotosUpdated;
  const _SimpleCollectionPhotoPicker({
    super.key,
    required this.photos,
    required this.onPhotosUpdated,
  });

  @override
  State<_SimpleCollectionPhotoPicker> createState() =>
      _SimpleCollectionPhotoPickerState();
}

class _SimpleCollectionPhotoPickerState
    extends State<_SimpleCollectionPhotoPicker> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Upload 3 photos to your collection',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Color.fromRGBO(0x8D, 0x8D, 0x8D, 1.0),
          ),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (var i = 0; i < 3; i++)
              Builder(
                builder: (context) {
                  final photo =
                      i < widget.photos.length ? widget.photos[i] : null;
                  final hasPhoto = photo != null;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Button(
                        onPressed: () async {
                          final photo = await _selectPhoto();
                          if (mounted && photo != null) {
                            widget.onPhotosUpdated(List.of(widget.photos)
                              ..replaceRange(i, i + 1, [photo]));
                          }
                        },
                        child: RoundedRectangleContainer(
                          child: SizedBox(
                            width: 76,
                            height: 148,
                            child: photo == null
                                ? const SizedBox.shrink()
                                : Image.file(
                                    photo,
                                    fit: BoxFit.cover,
                                    cacheHeight: 148,
                                    filterQuality: FilterQuality.medium,
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: !hasPhoto
                              ? Border.all(width: 2, color: Colors.white)
                              : const Border(),
                          color: !hasPhoto
                              ? Colors.transparent
                              : const Color.fromRGBO(0x2D, 0xDA, 0x01, 1.0),
                        ),
                        child: !hasPhoto
                            ? const SizedBox.shrink()
                            : const Icon(Icons.done, size: 16),
                      )
                    ],
                  );
                },
              ),
          ],
        ),
      ],
    );
  }

  Future<File?> _selectPhoto() async {
    final source = await showCupertinoDialog<ImageSource>(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text('Pick a photo'),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(ImageSource.camera),
              child: const Text('Take photo'),
            ),
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(ImageSource.gallery),
              child: const Text('Gallery'),
            ),
          ],
        );
      },
    );
    if (!mounted || source == null) {
      return null;
    }

    final picker = ImagePicker();
    XFile? result;
    try {
      result = await picker.pickImage(source: source);
    } on PlatformException catch (e) {
      if (e.code == 'camera_access_denied') {
        result = null;
      } else {
        rethrow;
      }
    }
    if (!mounted || result == null) {
      return null;
    }

    return File(result.path);
  }
}

class _UploadStep extends StatelessWidget {
  final List<File> photos;
  final VoidCallback onUpload;
  final VoidCallback onDelete;

  const _UploadStep({
    super.key,
    required this.photos,
    required this.onUpload,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        SizedBox(
          width: 249,
          child: Text(
            'Upload as a new\ncollection?',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                fontSize: 20, fontWeight: FontWeight.w500, height: 1.5),
          ),
        ),
        Expanded(
          child: CollectionPhotoStack(
            photos: photos,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Button(
                onPressed: onDelete,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 4.0, horizontal: 8.0),
                  child: Text(
                    'Delete',
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: const Color.fromRGBO(0xFF, 0x00, 0x00, 1.0),
                        fontSize: 16,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              const SizedBox(width: 100),
              Button(
                onPressed: onUpload,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color.fromRGBO(0xFF, 0xFF, 0xFF, 0.5),
                    borderRadius: BorderRadius.all(Radius.circular(6)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 4.0, horizontal: 8.0),
                    child: Text(
                      'Upload',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium!
                          .copyWith(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.only(
            left: 8,
            right: 8,
            top: 8,
            bottom: 8 + MediaQuery.of(context).padding.bottom,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 346),
            child: Text(
              'A professional photographer will check your images and make sure they are edited to the highest quality. We will have this collection up as soon as possible.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontSize: 13, fontWeight: FontWeight.w500, height: 1.7),
            ),
          ),
        )
      ],
    );
  }
}

enum _CreationStep { photos, upload }
