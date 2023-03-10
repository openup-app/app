import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/widgets/back_button.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class SignupCollectionAudio extends ConsumerStatefulWidget {
  final List<File> photos;
  const SignupCollectionAudio({
    super.key,
    required this.photos,
  });

  @override
  ConsumerState<SignupCollectionAudio> createState() =>
      _SignupCollectionAudioState();
}

class _SignupCollectionAudioState extends ConsumerState<SignupCollectionAudio> {
  File? _audio;
  bool _uploaded = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            itemCount: widget.photos.length,
            itemBuilder: (context, index) {
              return Image.file(
                widget.photos[index],
                fit: BoxFit.cover,
              );
            },
          ),
          Container(
            height: 96 + MediaQuery.of(context).padding.top,
            color: Colors.black.withOpacity(0.2),
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 13, sigmaY: 13),
                child: Padding(
                  padding:
                      EdgeInsets.only(top: MediaQuery.of(context).padding.top),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: BackIconButton(),
                        ),
                        Center(
                          child: Text(
                            'Let\'s record your voice bio',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                    fontSize: 16, fontWeight: FontWeight.w400),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Button(
                            onPressed: _audio == null
                                ? null
                                : (_uploaded
                                    ? () => context.pushNamed('signup_friends')
                                    : () => _uploadCollection(context)),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                'next',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium!
                                    .copyWith(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Center(
            child: Button(
              onPressed: () async {
                final result = await _showRecordPanel(context);
                if (result != null) {
                  setState(() => _audio = result);
                }
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                decoration: const BoxDecoration(
                  color: Color.fromRGBO(0x80, 0x0B, 0x06, 1.0),
                  borderRadius: BorderRadius.all(Radius.circular(6)),
                ),
                child: Text(
                  'Record',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium!
                      .copyWith(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Future<File?> _showRecordPanel(BuildContext context) async {
    final audio = await showModalBottomSheet<Uint8List>(
      backgroundColor: Colors.transparent,
      context: context,
      builder: (context) {
        return Surface(
          child: RecordPanelContents(
            submitAction: RecordPanelSubmitAction.done,
            onSubmit: (audio, duration) => Navigator.of(context).pop(audio),
          ),
        );
      },
    );

    if (audio == null || !mounted) {
      return null;
    }

    final tempDir = await getTemporaryDirectory();
    final file = File(path.join(tempDir.path, 'collection_audio.m4a'));
    await file.writeAsBytes(audio);
    return file;
  }

  void _uploadCollection(BuildContext context) async {
    final result = await withBlockingModal(
      context: context,
      label: 'Uploading...',
      future: uploadCollection(
        context: context,
        photos: widget.photos,
        audio: _audio,
        useAsProfile: true,
      ),
    );
    if (!mounted) {
      return;
    }

    if (result == null) {
      return;
    }

    result.fold(
      (l) => displayError(context, l),
      (r) {
        if (!mounted) {
          return;
        }
        result.fold(
          (l) => displayError(context, l),
          (r) {
            // Incase the user navigates back to this page
            setState(() => _uploaded = true);

            final profile = ref.read(userProvider).profile;
            if (profile != null) {
              ref
                  .read(userProvider.notifier)
                  .profile(profile.copyWith(collection: r));
            }

            context.pushNamed('signup_friends');
          },
        );
      },
    );
  }
}

class SignupCollectionAudioArgs {
  final List<File> photos;

  const SignupCollectionAudioArgs(this.photos);
}
