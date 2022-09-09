import 'dart:io';

import 'package:flutter/material.dart' hide Chip;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/api/users/profile.dart';
import 'package:openup/main.dart';
import 'package:openup/profile_view.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/tab_view.dart';
import 'package:openup/widgets/theming.dart';
import 'package:openup/widgets/three_photo_gallery.dart';
import 'package:openup/widgets/toggle_button.dart';

class ProfilePage extends StatefulWidget {
  final Profile profile;

  const ProfilePage({
    Key? key,
    required this.profile,
  }) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _showEdit = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: MediaQuery.of(context).padding.top),
        const SizedBox(height: 12),
        Center(
          child: RichText(
            text: TextSpan(
              style: Theming.of(context)
                  .text
                  .body
                  .copyWith(fontWeight: FontWeight.w300),
              children: [
                TextSpan(
                  text: 'openup ',
                  style: Theming.of(context)
                      .text
                      .body
                      .copyWith(fontWeight: FontWeight.w600),
                ),
                const TextSpan(text: 'make new '),
                TextSpan(
                  text: 'friends',
                  style: Theming.of(context)
                      .text
                      .body
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          height: 56,
          child: Stack(
            alignment: Alignment.center,
            children: [
              TabView(
                firstSelected: _showEdit,
                firstLabel: 'Edit Profile',
                secondLabel: 'Preview',
                onSelected: (first) => setState(() => _showEdit = first),
              ),
              Positioned(
                top: 0,
                bottom: 0,
                right: 16,
                child: Button(
                  child: const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Icon(
                      Icons.settings,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                  onPressed: () => rootNavigatorKey.currentState
                      ?.pushNamed('account-settings'),
                ),
              ),
            ],
          ),
        ),
        if (_showEdit)
          Expanded(
            child: _EditProfileView(
              profile: widget.profile,
            ),
          )
        else
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom),
              child: Consumer(
                builder: (context, ref, _) {
                  return ProfileView(
                    profile: ref.watch(userProvider.select((p) => p.profile)) ??
                        widget.profile,
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

class _EditProfileView extends StatefulWidget {
  final Profile profile;
  const _EditProfileView({
    Key? key,
    required this.profile,
  }) : super(key: key);

  @override
  State<_EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<_EditProfileView> {
  bool _blur = false;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      children: [
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16),
                  child: Text(
                    'My Pictures',
                    style: Theming.of(context).text.body.copyWith(fontSize: 24),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16),
                  child: Text(
                    'Add your best three pictures',
                    style: Theming.of(context)
                        .text
                        .body
                        .copyWith(fontSize: 16, fontWeight: FontWeight.w300),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              'Hide Pictures',
              style: Theming.of(context)
                  .text
                  .body
                  .copyWith(fontSize: 14, fontWeight: FontWeight.w400),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 6.0, right: 16),
              child: Consumer(
                builder: (context, ref, _) {
                  return ToggleButton(
                    value: _blur,
                    onChanged: (value) {
                      setState(() => _blur = value);
                      updateBlurPhotos(
                        context: context,
                        ref: ref,
                        blur: value,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 298,
          margin: const EdgeInsets.only(left: 16, right: 16),
          child: ThreePhotoGallery(
            blur: _blur,
          ),
        ),
        const SizedBox(height: 29),
        const Padding(
          padding: EdgeInsets.only(left: 16, right: 16),
          child: _RecordButton(),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16),
          child: Text(
            'Reason you\'re here',
            style: Theming.of(context).text.body.copyWith(fontSize: 24),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16),
          child: Text(
            'Choose a category that fits with you',
            style: Theming.of(context)
                .text
                .body
                .copyWith(fontSize: 16, fontWeight: FontWeight.w300),
          ),
        ),
        const SizedBox(height: 6),
        SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          scrollDirection: Axis.horizontal,
          child: Consumer(
            builder: (context, ref, _) {
              final selected =
                  ref.watch(userProvider.select((p) => p.profile?.topic));
              return Row(
                children: [
                  for (final topic in Topic.values)
                    Chip(
                      label: topicLabel(topic),
                      selected: selected == topic,
                      onSelected: () async {
                        await withBlockingModal(
                          context: context,
                          label: 'Updating',
                          future: updateTopic(
                            context: context,
                            ref: ref,
                            topic: topic,
                          ),
                        );
                      },
                    ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16),
          child: Text(
            'My Name',
            style: Theming.of(context).text.body.copyWith(fontSize: 24),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16),
          child: Text(
            'Please don\'t use your real name',
            style: Theming.of(context)
                .text
                .body
                .copyWith(fontSize: 16, fontWeight: FontWeight.w300),
          ),
        ),
        const SizedBox(height: 6),
        Consumer(
          builder: (context, ref, _) {
            final name =
                ref.watch(userProvider.select((p) => p.profile?.name ?? ''));
            return Button(
              onPressed: () async {
                final newName = await showDialog<String>(
                  context: context,
                  builder: (contex) => _NameDialog(initialName: name),
                );
                if (newName != null && newName != name) {
                  final result = await withBlockingModal(
                    context: context,
                    label: 'Updating',
                    future: updateName(
                      context: context,
                      ref: ref,
                      name: newName,
                    ),
                  );

                  result.fold(
                    (l) => displayError(context, l),
                    (r) {},
                  );
                }
              },
              child: Container(
                height: 51,
                margin: const EdgeInsets.only(left: 16, right: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white),
                  borderRadius: const BorderRadius.all(
                    Radius.circular(40),
                  ),
                ),
                child: Center(
                  child: Text(
                    name,
                    style: Theming.of(context)
                        .text
                        .body
                        .copyWith(fontSize: 20, fontWeight: FontWeight.w300),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _NameDialog extends StatefulWidget {
  final String initialName;
  const _NameDialog({
    Key? key,
    required this.initialName,
  }) : super(key: key);

  @override
  State<_NameDialog> createState() => __NameDialogState();
}

class __NameDialogState extends State<_NameDialog> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialName;
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: widget.initialName.length,
    );
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('My Name'),
      actions: [
        TextButton(
          onPressed: Navigator.of(context).pop,
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Done'),
        ),
      ],
      content: TextField(
        controller: _controller,
        focusNode: _focusNode,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.done,
        onSubmitted: (a) => Navigator.of(context).pop(_controller.text),
      ),
    );
  }
}

class _RecordButton extends ConsumerStatefulWidget {
  const _RecordButton({Key? key}) : super(key: key);

  @override
  ConsumerState<_RecordButton> createState() => __RecordButtonState();
}

class __RecordButtonState extends ConsumerState<_RecordButton> {
  bool _uploading = false;
  @override
  Widget build(BuildContext context) {
    return RecordButton(
      label: 'Record new status',
      submitLabel: 'Upload status',
      submitting: _uploading,
      submitted: false,
      onSubmit: (path) async {
        setState(() => _uploading = true);
        final bytes = await File(path).readAsBytes();
        final result = await updateAudio(
          context: context,
          ref: ref,
          bytes: bytes,
        );
        if (!mounted) {
          return;
        }

        result.fold(
          (l) => displayError(context, l),
          (r) {},
        );
        setState(() => _uploading = false);
      },
      onBeginRecording: () {},
    );
  }
}
