import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openup/api/users/users_api.dart';
import 'package:openup/platform/photo_picker.dart';
import 'package:openup/util/users_api_util.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/home_button.dart';
import 'package:openup/widgets/notification_banner.dart';
import 'package:openup/widgets/profile_bio.dart';
import 'package:openup/widgets/image_builder.dart';
import 'package:openup/widgets/theming.dart';

class PublicProfileEditScreen extends StatefulWidget {
  const PublicProfileEditScreen({Key? key}) : super(key: key);

  @override
  State<PublicProfileEditScreen> createState() =>
      _PublicProfileEditScreenState();
}

class _PublicProfileEditScreenState extends State<PublicProfileEditScreen> {
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
                      final editableProfile = ref.watch(profileProvider);
                      return ProfileBio(
                        key: _audioBioKey,
                        name: editableProfile?.name,
                        birthday: editableProfile?.birthday,
                        url: editableProfile?.audio,
                        editable: true,
                        onRecorded: (audio) =>
                            uploadAudio(context: context, audio: audio),
                        onUpdateName: (name) {
                          updateName(
                            context: context,
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
}

class PhotoGrid extends StatelessWidget {
  final bool horizontal;
  const PhotoGrid({
    Key? key,
    this.horizontal = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final gallery =
            ref.watch(profileProvider.select((value) => value?.gallery ?? []));
        return Column(
          children: [
            for (var i = 0; i < (horizontal ? 2 : 3); i++)
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: horizontal
                      ? (i == 0
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start)
                      : CrossAxisAlignment.stretch,
                  children: [
                    for (var j = 0; j < (horizontal ? 3 : 2); j++)
                      Expanded(
                        child: Stack(
                          children: [
                            Button(
                              onPressed: () async {
                                final index = i * 2 + j;
                                final photo = await _pickPhoto(context);
                                if (photo != null) {
                                  uploadPhoto(
                                    context: context,
                                    photo: photo,
                                    index: index,
                                  );
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
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(36)),
                                  color: Colors.black.withOpacity(0.2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.25),
                                      blurRadius: 4,
                                      offset: const Offset(0.0, 4.0),
                                      blurStyle: BlurStyle.normal,
                                    )
                                  ],
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
                                    deletePhoto(
                                      context: context,
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
                        ),
                      ),
                  ],
                ),
              ),
          ],
        );
      },
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
  }
}
