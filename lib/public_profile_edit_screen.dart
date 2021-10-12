import 'dart:typed_data';
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openup/api/users/users_api.dart';
import 'package:openup/platform/photo_picker.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/home_button.dart';
import 'package:openup/widgets/loading_dialog.dart';
import 'package:openup/widgets/notification_banner.dart';
import 'package:openup/widgets/profile_audio_recorder.dart';
import 'package:openup/widgets/theming.dart';

class PublicProfileEditScreen extends ConsumerStatefulWidget {
  const PublicProfileEditScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PublicProfileEditScreen> createState() =>
      _PublicProfileEditScreenState();
}

class _PublicProfileEditScreenState
    extends ConsumerState<PublicProfileEditScreen> {
  final _pageController = PageController(initialPage: 10000);
  final _photoPicker = PhotoPicker();
  final _gallery = <String>[];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final gallery = ref.read(usersApiProvider).publicProfile?.gallery;
    if (gallery != null) {
      _gallery.clear();
      _gallery.addAll(gallery);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top),
          Padding(
            padding: const EdgeInsets.only(top: 24.0, bottom: 16),
            child: Text(
              'Add Up To Six Photos',
              style: Theming.of(context).text.body,
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  bottom: 180,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      for (var i = 0; i < 3; i++)
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (var j = 0; j < 2; j++)
                                Expanded(
                                  child: Button(
                                    onPressed: () async {
                                      final index = i * 2 + j;
                                      final photo = await _pickPhoto();
                                      if (photo != null) {
                                        await _uploadPhoto(photo, index);
                                      }
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 4, vertical: 8),
                                      clipBehavior: Clip.hardEdge,
                                      decoration: BoxDecoration(
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(36)),
                                        color: Colors.white.withOpacity(0.3),
                                      ),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        fit: StackFit.expand,
                                        children: [
                                          if (_gallery.length > i * 2 + j)
                                            ColorFiltered(
                                              colorFilter: ColorFilter.mode(
                                                Colors.black.withOpacity(0.25),
                                                BlendMode.darken,
                                              ),
                                              child: Image.network(
                                                _gallery[i * 2 + j],
                                                fit: BoxFit.cover,
                                                opacity:
                                                    const AlwaysStoppedAnimation(
                                                        0.75),
                                              ),
                                            ),
                                          const Icon(
                                            Icons.add,
                                            size: 48,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const Positioned(
                  right: 0,
                  bottom: 160,
                  child: NotificationBanner(
                    contents: 'Record an audio bio for your connects to hear',
                  ),
                ),
                const Positioned(
                  left: 16,
                  right: 16,
                  bottom: 80,
                  height: 72,
                  child: ProfileAudioRecorder(),
                ),
                Positioned(
                  left: MediaQuery.of(context).padding.left + 16,
                  bottom: MediaQuery.of(context).padding.bottom + 16,
                  child: const BackButton(),
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
        ],
      ),
    );
  }

  Future<Uint8List?> _pickPhoto() async {
    final useCamera = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () => Navigator.of(context).pop(true),
              ),
              ListTile(
                leading: const Icon(Icons.photo),
                title: const Text('Gallery'),
                onTap: () => Navigator.of(context).pop(false),
              ),
            ],
          ),
        );
      },
    );

    if (useCamera != null) {
      return _photoPicker.pickPhoto(useCamera);
    }
  }

  Future<void> _uploadPhoto(Uint8List photo, int index) async {
    final auth = FirebaseAuth.instance;
    final uid = auth.currentUser?.uid;
    if (uid == null) {
      return;
    }

    final popDialog = showBlockingModalDialog(
      context: context,
      builder: (context) {
        return const Loading(
          title: Text('Uploading photo'),
        );
      },
    );

    final usersApi = ref.read(usersApiProvider);
    try {
      await usersApi.uploadProfilePhoto(uid, photo, index);
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to add photo'),
        ),
      );
    }
    popDialog();

    final gallery = usersApi.publicProfile?.gallery;
    if (gallery != null) {
      setState(() {
        _gallery.clear();
        _gallery.addAll(gallery);
      });
    }
  }
}
