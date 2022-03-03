import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/api/users/users_api.dart';
import 'package:openup/platform/photo_picker.dart';
import 'package:openup/widgets/back_button.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/home_button.dart';
import 'package:openup/widgets/notification_banner.dart';
import 'package:openup/widgets/profile_bio.dart';
import 'package:openup/widgets/image_builder.dart';
import 'package:openup/widgets/theming.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({Key? key}) : super(key: key);

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _audioBioKey = GlobalKey<ProfileBioState>();
  final _pageController = PageController(initialPage: 10000);

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
                const Positioned(
                  top: 0,
                  bottom: 180,
                  left: 0,
                  right: 0,
                  child: PhotoGrid(),
                ),
                const Positioned(
                  right: 0,
                  bottom: 172,
                  child: NotificationBanner(
                    contents: 'Record an audio bio for your connects to hear',
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 80,
                  height: 88,
                  child: Consumer(
                    builder: (context, ref, child) {
                      final editableProfile =
                          ref.watch(userProvider.select((p) => p.profile));
                      return ProfileBio(
                        key: _audioBioKey,
                        name: editableProfile?.name,
                        birthday: editableProfile?.birthday,
                        url: editableProfile?.audio,
                        editable: true,
                        onRecorded: (audio) {
                          _uploadAudio(
                            context: context,
                            ref: ref,
                            bytes: audio,
                          );
                        },
                        onUpdateName: (name) {
                          _updateName(
                            context: context,
                            ref: ref,
                            name: name,
                          );
                        },
                      );
                    },
                  ),
                ),
                Positioned(
                  left: MediaQuery.of(context).padding.left + 16,
                  bottom: MediaQuery.of(context).padding.bottom + 16,
                  child: const BackIconButton(),
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
}

class PhotoGrid extends ConsumerWidget {
  final bool horizontal;
  const PhotoGrid({
    Key? key,
    this.horizontal = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        for (var i = 0; i < (horizontal ? 2 : 3); i++)
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: horizontal
                  ? (i == 0 ? CrossAxisAlignment.end : CrossAxisAlignment.start)
                  : CrossAxisAlignment.stretch,
              children: [
                for (var j = 0; j < (horizontal ? 3 : 2); j++)
                  Expanded(
                    child: Consumer(
                      builder: (context, ref, _) {
                        final gallery = ref.watch(userProvider
                            .select((p) => p.profile?.gallery ?? []));
                        return Stack(
                          children: [
                            Button(
                              onPressed: () async {
                                final index = i * 2 + j;
                                final photo = await _pickPhoto(context);
                                if (photo != null) {
                                  _uploadPhoto(context, ref, photo, index);
                                }
                              },
                              child: Container(
                                constraints:
                                    const BoxConstraints(maxHeight: 145),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 12,
                                ),
                                clipBehavior: Clip.hardEdge,
                                decoration: const BoxDecoration(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(36)),
                                  color: Color.fromRGBO(0xC4, 0xC4, 0xC4, 0.5),
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  fit: StackFit.expand,
                                  children: [
                                    if (gallery.length > i * 2 + j)
                                      ColorFiltered(
                                        colorFilter: ColorFilter.mode(
                                          Colors.black.withOpacity(0.25),
                                          BlendMode.darken,
                                        ),
                                        child: Image.network(
                                          gallery[i * 2 + j],
                                          fit: BoxFit.cover,
                                          frameBuilder: fadeInFrameBuilder,
                                          loadingBuilder:
                                              circularProgressLoadingBuilder,
                                          errorBuilder: iconErrorBuilder,
                                          opacity: const AlwaysStoppedAnimation(
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
                            if (gallery.length > i * 2 + j)
                              Positioned(
                                right: 20,
                                top: 20,
                                child: Button(
                                  onPressed: () {
                                    _deletePhoto(
                                      context: context,
                                      ref: ref,
                                      index: i * 2 + j,
                                    );
                                  },
                                  child: const Icon(
                                    Icons.close,
                                    size: 21,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Future<Uint8List?> _pickPhoto(BuildContext context) async {
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
      return PhotoPicker().pickPhoto(useCamera);
    }
    return null;
  }
}

void _uploadPhoto(
  BuildContext context,
  WidgetRef ref,
  Uint8List bytes,
  int index,
) async {
  final result = await withBlockingModal(
    context: context,
    label: 'Uploading photo',
    future: updatePhoto(
      context: context,
      ref: ref,
      bytes: bytes,
      index: index,
    ),
  );

  result.fold(
    (l) => displayError(context, l),
    (r) {},
  );
}

void _deletePhoto({
  required BuildContext context,
  required WidgetRef ref,
  required int index,
}) async {
  final result = await withBlockingModal(
    context: context,
    label: 'Deleting photo',
    future: deletePhoto(
      context: context,
      ref: ref,
      index: index,
    ),
  );

  result.fold(
    (l) => displayError(context, l),
    (r) {},
  );
}

void _uploadAudio({
  required BuildContext context,
  required WidgetRef ref,
  required Uint8List bytes,
}) async {
  final result = await withBlockingModal(
    context: context,
    label: 'Uploading audio',
    future: updateAudio(
      context: context,
      ref: ref,
      bytes: bytes,
    ),
  );

  result.fold(
    (l) => displayError(context, l),
    (r) {},
  );
}

void _updateName({
  required BuildContext context,
  required WidgetRef ref,
  required String name,
}) async {
  final result = await withBlockingModal(
    context: context,
    label: 'Updating name',
    future: updateName(
      context: context,
      ref: ref,
      name: name,
    ),
  );

  result.fold(
    (l) => displayError(context, l),
    (r) {},
  );
}
