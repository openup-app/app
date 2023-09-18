import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openup/analytics/analytics.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/auth/auth_provider.dart';
import 'package:openup/platform/just_audio_audio_player.dart';
import 'package:openup/util/photo_picker.dart';
import 'package:openup/widgets/audio_playback_symbol.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/gallery.dart';
import 'package:openup/widgets/image_builder.dart';
import 'package:openup/widgets/phone_number_input.dart';
import 'package:openup/widgets/profile_display.dart';
import 'package:openup/widgets/record.dart';
import 'package:openup/widgets/restart_app.dart';
import 'package:openup/widgets/scaffold.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<SettingsPage> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: OpenupAppBar(
        body: OpenupAppBarBody(
          leading: Button(
            onPressed: Navigator.of(context).pop,
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Cancel'),
            ),
          ),
          center: const Text('Settings'),
        ),
      ),
      body: ref.watch(userProvider2).map(
        guest: (_) {
          return Center(
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
          );
        },
        signedIn: (signedIn) {
          return LayoutBuilder(
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
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const _SectionTitle(label: 'Name'),
                              const _CupertinoRow(
                                leading: _NameField(),
                              ),
                              const SizedBox(height: 12),
                              const SizedBox(height: 8),
                              const _PhoneNumberField(),
                              const SizedBox(height: 16),
                              Button(
                                onPressed: () => context.pushNamed('contacts'),
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
                                onPressed: () => context.pushNamed('blocked'),
                                child: const _CupertinoRow(
                                  leading: Text('Blocked users'),
                                  trailing: Icon(Icons.chevron_right),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Button(
                                onPressed: () =>
                                    context.pushNamed('contact_us'),
                                child: const _CupertinoRow(
                                  leading: Text('Contact us'),
                                  trailing: Icon(Icons.chevron_right),
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
                                    style: TextStyle(
                                      color:
                                          Color.fromRGBO(0xFF, 0x00, 0x00, 1.0),
                                    ),
                                  ),
                                ),
                              ),
                              if (kDebugMode)
                                Builder(
                                  builder: (context) {
                                    final authState = ref.watch(authProvider);
                                    final signedIn = authState.map(
                                      guest: (_) => null,
                                      signedIn: (signedIn) => signedIn,
                                    );
                                    if (signedIn == null) {
                                      return const SizedBox.shrink();
                                    }
                                    return DefaultTextStyle(
                                      style: const TextStyle(
                                        color: Color.fromRGBO(
                                            0x4B, 0x4B, 0x4B, 1.0),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8.0),
                                        child: Text(
                                          signedIn.uid,
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              const _AppVersion(),
                              const SizedBox(height: 32),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).viewInsets.bottom,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: MediaQuery.of(context).padding.bottom),
                      ],
                    );
                  },
                ),
              );
            },
          );
        },
      ),
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
    ref.read(analyticsProvider).trackSignOut();
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
              'This will permanently delete your Plus One conversations, contacts and profile'),
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
    ref.read(analyticsProvider).trackDeleteAccount();
    ref.read(userProvider.notifier)
      ..uid('')
      ..profile(null)
      ..collections([]);
    ref.read(userProvider2.notifier).guest();
    ref.read(apiProvider).deleteAccount();
    await ref.read(authProvider.notifier).signOut();
  }
}

class _AppVersion extends StatefulWidget {
  const _AppVersion({super.key});

  @override
  State<_AppVersion> createState() => _AppVersionState();
}

class _AppVersionState extends State<_AppVersion> {
  String? _version;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((packageInfo) {
      if (mounted) {
        setState(() => _version = packageInfo.version);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final version = _version;
    if (version == null) {
      return const SizedBox.shrink();
    }
    return Text(
      'version $version',
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: Color.fromRGBO(0x4B, 0x4B, 0x4B, 1.0),
      ),
    );
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
                                        padding: const EdgeInsets.only(
                                            left: 4, right: 12),
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
                                    if (i < widget.profile.gallery.length)
                                      Positioned(
                                        top: 0,
                                        right: 0,
                                        child: Button(
                                          onPressed: (widget.profile.gallery
                                                          .length <=
                                                      1 ||
                                                  i >=
                                                      widget.profile.gallery
                                                          .length)
                                              ? null
                                              : () => _showDeletePhotoDialog(i),
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Container(
                                              width: 23,
                                              height: 23,
                                              decoration: const BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.white,
                                              ),
                                              alignment: Alignment.center,
                                              child: const Icon(
                                                Icons.close,
                                                size: 16,
                                                color: Colors.black,
                                              ),
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
    final photo = await selectPhoto(
      context,
      label: 'This photo will be used in your profile',
    );
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
                  child: Text('Edit'),
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
          case SendCodeError.quotaExceeded:
            message = 'Unable to send code, we are working to solve this';
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
    const textStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: Colors.white,
    );
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      clipBehavior: Clip.hardEdge,
      decoration: decoration ??
          const BoxDecoration(
            color: Color.fromRGBO(0x2A, 0x2A, 0x2A, 1.0),
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
      child: DefaultTextStyle(
        style: textStyle,
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
            if (trailing != null)
              DefaultTextStyle(
                style: textStyle.copyWith(
                  color: const Color.fromRGBO(0x00, 0x7C, 0xEE, 1.0),
                ),
                child: IconTheme(
                  data: IconTheme.of(context).copyWith(
                    color: const Color.fromRGBO(0x00, 0x7C, 0xEE, 1.0),
                  ),
                  child: trailing!,
                ),
              ),
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
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: Colors.white,
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
              style: DefaultTextStyle.of(context).style,
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
          child: DefaultTextStyle(
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Color.fromRGBO(0x00, 0x7C, 0xEE, 1.0),
            ),
            child: Builder(
              builder: (context) {
                if (_submittingName) {
                  return const Padding(
                    padding: EdgeInsets.only(right: 12.0),
                    child: LoadingIndicator(),
                  );
                }
                if (!_editingName) {
                  return const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Edit'),
                  );
                } else {
                  return const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Done'),
                  );
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}
