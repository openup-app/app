import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/widgets/back_button.dart';
import 'package:openup/widgets/home_button.dart';
import 'package:openup/widgets/photo_grid.dart';
import 'package:openup/widgets/profile_bio.dart';
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
