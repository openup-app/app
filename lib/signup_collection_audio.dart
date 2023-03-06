import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/widgets/back_button.dart';
import 'package:openup/widgets/button.dart';

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
                            'Let\'s record your voice bio?',
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
                            onPressed: _uploaded
                                ? () => context.pushNamed('signup_friends')
                                : () => _uploadCollection(context),
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
        ],
      ),
    );
  }

  void _uploadCollection(BuildContext context) async {
    final result = await withBlockingModal(
      context: context,
      label: 'Uploading...',
      future: uploadCollection(
        context: context,
        photos: widget.photos,
        audio: _audio,
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
            // TODO: Set profile collection when it ready
            // ref.read(userProvider.notifier).profile(profile.copyWith())

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
