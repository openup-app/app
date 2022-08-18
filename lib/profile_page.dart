import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide Chip;
import 'package:openup/api/users/profile.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/theming.dart';

class ProfilePage extends StatelessWidget {
  final Profile profile;

  const ProfilePage({
    Key? key,
    required this.profile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: MediaQuery.of(context).padding.top),
        const SizedBox(height: 12),
        RichText(
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
        SizedBox(
          height: 56,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                child: CupertinoSlidingSegmentedControl(
                  children: {
                    'edit': Text(
                      'Edit Profile',
                      style: Theming.of(context).text.body,
                    ),
                    'preview': Text(
                      'Preview',
                      style: Theming.of(context).text.body,
                    ),
                  },
                  onValueChanged: (value) {},
                ),
              ),
              Positioned(
                top: 0,
                bottom: 0,
                right: 0,
                child: Button(
                  child: const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Icon(
                      Icons.settings,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding:
                EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
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
              const SizedBox(height: 6),
              Container(
                height: 298,
                margin: const EdgeInsets.only(left: 16, right: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(24)),
                        child: _PhotoOrUploadButton(
                          url: profile.photo,
                          onUpload: (_) {},
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(24)),
                              child: _PhotoOrUploadButton(
                                url: profile.gallery.length > 1
                                    ? profile.gallery[1]
                                    : null,
                                onUpload: (data) {},
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(24)),
                              child: _PhotoOrUploadButton(
                                url: profile.gallery.length > 2
                                    ? profile.gallery[2]
                                    : null,
                                onUpload: (_) {},
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
                child: Row(
                  children: [
                    Chip(
                      label: 'Sad',
                      selected: false,
                      onSelected: () {},
                    ),
                    Chip(
                      label: 'Lonely',
                      selected: false,
                      onSelected: () {},
                    ),
                    Chip(
                      label: 'Introvert',
                      selected: false,
                      onSelected: () {},
                    ),
                    Chip(
                      label: 'Talk',
                      selected: true,
                      onSelected: () {},
                    ),
                  ],
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
              Container(
                height: 51,
                margin: const EdgeInsets.only(left: 16, right: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white),
                  borderRadius: const BorderRadius.all(
                    Radius.circular(40),
                  ),
                ),
                child: Center(
                  child: Text(profile.name,
                      style: Theming.of(context)
                          .text
                          .body
                          .copyWith(fontSize: 20, fontWeight: FontWeight.w300)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}

class _RecordButton extends StatefulWidget {
  const _RecordButton({Key? key}) : super(key: key);

  @override
  State<_RecordButton> createState() => __RecordButtonState();
}

class __RecordButtonState extends State<_RecordButton> {
  bool _uploading = false;
  @override
  Widget build(BuildContext context) {
    return RecordButton(
      label: 'Record new status',
      submitLabel: 'Upload status',
      submitting: _uploading,
      submitted: false,
      onSubmit: (_) async {
        setState(() => _uploading = true);
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          setState(() => _uploading = false);
        }
      },
    );
  }
}

class _PhotoOrUploadButton extends StatelessWidget {
  final String? url;
  final void Function(Uint8List photo) onUpload;
  const _PhotoOrUploadButton({
    Key? key,
    required this.url,
    required this.onUpload,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Button(
      onPressed: () {},
      child: Builder(builder: (context) {
        final photoUrl = url;
        if (photoUrl != null) {
          return Image.network(
            photoUrl,
            fit: BoxFit.cover,
          );
        }
        return Container(
          color: const Color.fromRGBO(0x7D, 0x7D, 0x7D, 1.0),
          alignment: Alignment.center,
          child: const Icon(
            Icons.add_photo_alternate,
            color: Colors.white,
            size: 34,
          ),
        );
      }),
    );
  }
}
