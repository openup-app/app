import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:openup/analytics/analytics.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/auth/auth_provider.dart';
import 'package:openup/platform/just_audio_audio_player.dart';
import 'package:openup/shell_page.dart';
import 'package:openup/widgets/audio_playback_symbol.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/collection_photo_stack.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/gallery.dart';
import 'package:openup/widgets/image_builder.dart';
import 'package:openup/widgets/phone_number_input.dart';
import 'package:openup/widgets/profile_display.dart';
import 'package:openup/widgets/record.dart';
import 'package:openup/widgets/restart_app.dart';
import 'package:permission_handler/permission_handler.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _scrollController = ScrollController();
  final _profileBuilderKey = GlobalKey<ProfileBuilderState>();

  @override
  void dispose() {
    _scrollController.dispose();
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
        return ActivePage(
          onActivate: () {},
          onDeactivate: () {
            _profileBuilderKey.currentState?.pause();
          },
          child: Container(
            color: const Color.fromRGBO(0xF5, 0xF5, 0xF5, 1.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  controller: _scrollController,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Builder(
                    builder: (context) {
                      return Column(
                        children: [
                          SizedBox(height: MediaQuery.of(context).padding.top),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: Text(
                                'Profile & Settings',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Color.fromRGBO(0x79, 0x79, 0x79, 1.0),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: constraints.maxHeight -
                                (MediaQuery.of(context).padding.bottom + 150),
                            child: _ProfilePanel(
                              profile: profile,
                              profileBuilderKey: _profileBuilderKey,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Button(
                            onPressed: () {
                              _profileBuilderKey.currentState?.pause();
                              showProfileBottomSheet(
                                context: context,
                                profile: profile,
                              );
                            },
                            child: Container(
                              height: 52,
                              clipBehavior: Clip.hardEdge,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              decoration: const BoxDecoration(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(16)),
                                color: Colors.white,
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'Preview',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          DefaultTextStyle(
                            style: const TextStyle(color: Colors.white),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
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
                                    child: _CupertinoRow(
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
                                  if (kDebugMode)
                                    Builder(
                                      builder: (context) {
                                        final authState =
                                            ref.watch(authProvider);
                                        final signedIn = authState.map(
                                          guest: (_) => null,
                                          signedIn: (signedIn) => signedIn,
                                        );
                                        if (signedIn == null) {
                                          return const SizedBox.shrink();
                                        }
                                        return Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const SizedBox(height: 16),
                                            Center(
                                              child: Text(
                                                signedIn.uid,
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Center(
                                              child: Text(
                                                signedIn.phoneNumber ?? '',
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    height: MediaQuery.of(context)
                                        .viewInsets
                                        .bottom,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
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
        RestartApp.restartApp(context);
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
    await ref.read(authProvider.notifier).signOut();
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
        RestartApp.restartApp(context);
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
    await ref.read(authProvider.notifier).signOut();
  }
}

class _ProfilePanel extends ConsumerStatefulWidget {
  final Profile profile;
  final GlobalKey<ProfileBuilderState> profileBuilderKey;

  const _ProfilePanel({
    super.key,
    required this.profile,
    required this.profileBuilderKey,
  });

  @override
  ConsumerState<_ProfilePanel> createState() => _ProfilePanelState();
}

class _ProfilePanelState extends ConsumerState<_ProfilePanel> {
  Timer? _animationTimer;

  @override
  void dispose() {
    _animationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.hardEdge,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        color: Colors.white,
      ),
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  flex: 6,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 8,
                    ),
                    child: ProfileBuilder(
                      key: widget.profileBuilderKey,
                      profile: widget.profile,
                      play: false,
                      builder: (context, playbackState, playbackInfoStream) {
                        return Column(
                          children: [
                            Expanded(
                              child: Container(
                                clipBehavior: Clip.hardEdge,
                                decoration: const BoxDecoration(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(22),
                                  ),
                                ),
                                child: NonCinematicGallery(
                                  slideshow: true,
                                  gallery: widget.profile.gallery,
                                ),
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16.0),
                                      child: AudioPlaybackSymbol(
                                        play: playbackState ==
                                            PlaybackState.playing,
                                        size: 16,
                                      ),
                                    ),
                                    Expanded(
                                      child: StreamBuilder<double>(
                                        stream: playbackInfoStream.map((e) {
                                          return e.duration.inMilliseconds == 0
                                              ? 0
                                              : e.position.inMilliseconds /
                                                  e.duration.inMilliseconds;
                                        }),
                                        initialData: 0.0,
                                        builder: (context, snapshot) {
                                          return DecoratedBox(
                                            decoration: const BoxDecoration(
                                              color: Color.fromRGBO(
                                                  0xE1, 0xE1, 0xE1, 1.0),
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(2)),
                                            ),
                                            child: FractionallySizedBox(
                                              widthFactor: snapshot.requireData,
                                              alignment: Alignment.centerLeft,
                                              child: Container(
                                                height: 4,
                                                decoration: const BoxDecoration(
                                                  color: Color.fromRGBO(
                                                      0x3E, 0x97, 0xFF, 1.0),
                                                  borderRadius:
                                                      BorderRadius.all(
                                                          Radius.circular(2)),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Expanded(
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
                                                    0x28, 0x98, 0xFF, 1.0),
                                                Color.fromRGBO(
                                                    0x02, 0x7D, 0xED, 1.0),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(25)),
                                          ),
                                          child: Text(
                                            'Update Voice Bio',
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
                                    const SizedBox(width: 16),
                                    Button(
                                      onPressed: () =>
                                          _onPlayPause(playbackState),
                                      child: Container(
                                        width: 46,
                                        height: 46,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Color.fromRGBO(
                                              0x05, 0x7F, 0xEF, 1.0),
                                        ),
                                        child: Builder(
                                          builder: (context) {
                                            switch (playbackState) {
                                              case PlaybackState.playing:
                                                return const Icon(
                                                  Icons.pause_rounded,
                                                  size: 34,
                                                  color: Colors.white,
                                                );
                                              case PlaybackState.loading:
                                                return const LoadingIndicator(
                                                  size: 24,
                                                  color: Colors.white,
                                                );
                                              default:
                                                return const Icon(
                                                  Icons.play_arrow_rounded,
                                                  size: 34,
                                                  color: Colors.white,
                                                );
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                Flexible(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7.0),
                    child: Column(
                      children: [
                        for (int i = 0; i < 3; i++)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 7,
                                horizontal: 8,
                              ),
                              child: Button(
                                onPressed: () => _updatePhoto(i),
                                onLongPressStart:
                                    (widget.profile.gallery.length <= 1 ||
                                            i >= widget.profile.gallery.length)
                                        ? null
                                        : () => _showDeletePhotoDialog(i),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Container(
                                      clipBehavior: Clip.hardEdge,
                                      decoration: const BoxDecoration(
                                        color: Color.fromRGBO(
                                            0xE7, 0xE7, 0xE7, 1.0),
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(16),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            offset: Offset(0, 2),
                                            blurRadius: 4,
                                            color: Color.fromRGBO(
                                                0x00, 0x00, 0x00, 0.25),
                                          ),
                                        ],
                                      ),
                                      child: Builder(
                                        builder: (context) {
                                          if (i >=
                                              widget.profile.gallery.length) {
                                            return const Center(
                                              child: Icon(
                                                Icons.add_a_photo,
                                                size: 28,
                                                color: Color.fromRGBO(
                                                    0x28, 0x98, 0xFF, 1.0),
                                              ),
                                            );
                                          } else {
                                            return Image.network(
                                              widget.profile.gallery[i],
                                              fit: BoxFit.cover,
                                              loadingBuilder: loadingBuilder,
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                    Positioned(
                                      right: 8,
                                      bottom: 8,
                                      child: Container(
                                        width: 23,
                                        height: 23,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white,
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          '${i + 1}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onPlayPause(PlaybackState playbackState) {
    switch (playbackState) {
      case PlaybackState.idle:
      case PlaybackState.paused:
        widget.profileBuilderKey.currentState?.play();
        break;
      default:
        widget.profileBuilderKey.currentState?.pause();
    }
  }

  void _updatePhoto(int index) async {
    final photo = await _selectPhoto(context);
    if (photo != null && mounted) {
      final notifier = ref.read(userProvider2.notifier);
      final uploadFuture = notifier.updateGalleryPhoto(
        index: index,
        photo: photo,
      );
      await withBlockingModal(
        context: context,
        label: 'Updating photo',
        future: uploadFuture,
      );
    }
  }

  void _showDeletePhotoDialog(int index) async {
    final result = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text('Delete photo?'),
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
      await ref.read(userProvider2.notifier).deleteGalleryPhoto(index);
    }
  }

  Future<void> _showRecordPanel(BuildContext context) async {
    widget.profileBuilderKey.currentState?.pause();
    final result = await showRecordPanel(
      context: context,
      title: const Text('Recording Voice Bio'),
      submitLabel: const Text('Finish & Update'),
    );
    if (!mounted || result == null) {
      return;
    }

    final notifier = ref.read(userProvider2.notifier);
    return withBlockingModal(
      context: context,
      label: 'Updating voice bio...',
      future: notifier.updateAudioBio(result.audio),
    );
  }
}

class _PhoneNumberField extends ConsumerStatefulWidget {
  const _PhoneNumberField({super.key});

  @override
  ConsumerState<_PhoneNumberField> createState() => _PhoneNumberFieldState();
}

class _PhoneNumberFieldState extends ConsumerState<_PhoneNumberField> {
  String? _validationError;
  String? _newPhoneNumber;
  bool _newPhoneNumberValid = false;

  final _phoneController = TextEditingController();
  final _phoneFocusNode = FocusNode();
  final _verificationCodeController = TextEditingController();

  _ChangePhoneState _state = _ChangePhoneState.closed;
  String? _verificationId;

  @override
  void initState() {
    super.initState();
    ref.listenManual<AuthSignedIn?>(
      authProvider.select((p) {
        return p.map(
          guest: (_) => null,
          signedIn: (signedIn) => signedIn,
        );
      }),
      (previous, next) {
        if (previous == null && next != null) {
          _phoneController.text = next.phoneNumber ?? '';
        }
      },
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    _verificationCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = ref.watch(authProvider.select((p) {
      return p.map(
        guest: (_) => null,
        signedIn: (signedIn) => signedIn,
      );
    }));

    final phoneNumber = signedIn?.phoneNumber;
    if (phoneNumber == null) {
      return _CupertinoRow();
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: Builder(
        builder: (context) {
          if (_state == _ChangePhoneState.closed) {
            return _CupertinoRow(
              leading: Text(phoneNumber),
              trailing: Button(
                onPressed: () {
                  setState(() => _state = _ChangePhoneState.enteringPhone);
                  _phoneFocusNode.requestFocus();
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
            );
          }
          return DecoratedBox(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _CupertinoRow(
                  leading: PhoneInput(
                    textController: _phoneController,
                    focusNode: _phoneFocusNode,
                    textAlign: TextAlign.start,
                    onChanged: (value, valid) {
                      setState(() {
                        _newPhoneNumber = value;
                        _newPhoneNumberValid = valid;
                      });
                    },
                    onValidationError: (validationError) {
                      setState(() => _validationError = validationError);
                    },
                  ),
                  trailing: Button(
                    onPressed: (!_newPhoneNumberValid ||
                            _state == _ChangePhoneState.awaitingCode ||
                            _state == _ChangePhoneState.submitting)
                        ? null
                        : () {
                            final newPhoneNumber = _newPhoneNumber;
                            if (newPhoneNumber != null &&
                                newPhoneNumber.isNotEmpty) {
                              _submitNewPhoneNumber(newPhoneNumber);
                            }
                          },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: _state != _ChangePhoneState.awaitingCode
                          ? const Text(
                              'Send code',
                              style: TextStyle(
                                color: Color.fromRGBO(0x51, 0xA1, 0xFF, 1.0),
                              ),
                            )
                          : const SizedBox(
                              width: 24,
                              height: 24,
                              child: LoadingIndicator(
                                color: Colors.black,
                              ),
                            ),
                    ),
                  ),
                  decoration: const BoxDecoration(),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutQuart,
                  alignment: Alignment.topCenter,
                  child: Builder(
                    builder: (context) {
                      if (_state == _ChangePhoneState.closed) {
                        return const SizedBox.shrink();
                      }
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Divider(
                            height: 1,
                            indent: 20,
                          ),
                          _CupertinoRow(
                            leading: TextFormField(
                              controller: _verificationCodeController,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.done,
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
                                    : () => _verifyCode(value.text),
                                child: _CupertinoRow(
                                  center: _state != _ChangePhoneState.submitting
                                      ? const Text(
                                          'Done',
                                          style: TextStyle(
                                            color: Color.fromRGBO(
                                                0x34, 0x78, 0xF6, 1.0),
                                          ),
                                        )
                                      : const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: LoadingIndicator(
                                            color: Colors.black,
                                          ),
                                        ),
                                  decoration: const BoxDecoration(),
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _submitNewPhoneNumber(String newPhoneNumber) async {
    setState(() => _state = _ChangePhoneState.awaitingCode);
    final result =
        await ref.read(authProvider.notifier).updatePhoneNumber(newPhoneNumber);
    if (!mounted) {
      return;
    }
    result.map(
      codeSent: (codeSent) {
        FocusScope.of(context).nextFocus();
        setState(() {
          _state = _ChangePhoneState.codeSent;
          _verificationId = codeSent.verificationId;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Code has been sent'),
          ),
        );
      },
      verified: (_) {
        setState(() => _state = _ChangePhoneState.closed);
        FocusScope.of(context).unfocus();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Phone number updated'),
          ),
        );
      },
      error: (error) {
        setState(() => _state = _ChangePhoneState.enteringPhone);
        final e = error.error;
        final String message;
        switch (e) {
          case SendCodeError.credentialFailure:
            message = 'Failed to validate';
            break;
          case SendCodeError.invalidPhoneNumber:
            message = 'Unsupported phone number';
            break;
          case SendCodeError.networkError:
            message = 'Network error';
            break;
          case SendCodeError.tooManyRequests:
            message = 'Too many attempts, please try again later';
            break;
          case SendCodeError.failure:
            message = 'Something went wrong';
            break;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
          ),
        );
      },
    );
  }

  void _verifyCode(String code) async {
    final verificationId = _verificationId;
    if (verificationId == null) {
      return;
    }

    setState(() => _state = _ChangePhoneState.submitting);
    final notifier = ref.read(authProvider.notifier);
    final result = await notifier.authenticatePhoneChange(
      verificationId: verificationId,
      smsCode: code,
    );
    if (!mounted) {
      return;
    }

    if (result == AuthResult.success) {
      setState(() => _state = _ChangePhoneState.closed);
      _verificationCodeController.clear();
    } else {
      setState(() => _state = _ChangePhoneState.codeSent);
    }

    final String message;
    switch (result) {
      case AuthResult.success:
        message = 'Sucessfully verified code';
        return;
      case AuthResult.invalidCode:
        message = 'Invalid code';
        break;
      case AuthResult.invalidId:
        message = 'Unable to attempt verification, please try again';
        break;
      case AuthResult.quotaExceeded:
        message = 'We are experiencing high demand, please try again later';
        break;
      case AuthResult.failure:
        message = 'Something went wrong';
        break;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }
}

enum _ChangePhoneState {
  closed,
  enteringPhone,
  awaitingCode,
  codeSent,
  submitting
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
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: Colors.black,
          ),
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
              _nameController.selection = TextSelection(
                baseOffset: 0,
                extentOffset: _nameController.text.length,
              );
              _nameFocusNode.requestFocus();
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
                  child: LoadingIndicator(
                    color: Colors.black,
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
                          final photo = await _selectPhoto(context);
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
            bottom: 8 + MediaQuery.of(context).viewPadding.bottom,
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

Future<File?> _selectPhoto(BuildContext context) async {
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
  if (source == null) {
    return null;
  }

  await Permission.camera.request();
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
  if (result == null) {
    return null;
  }

  return File(result.path);
}
