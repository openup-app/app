import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/widgets/audio_bio.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/male_female_connection_image.dart';
import 'package:openup/widgets/theming.dart';

class SignUpAudioBioScreen extends ConsumerStatefulWidget {
  const SignUpAudioBioScreen({Key? key}) : super(key: key);

  @override
  _SignUpAudioBioScreenState createState() => _SignUpAudioBioScreenState();
}

class _SignUpAudioBioScreenState extends ConsumerState<SignUpAudioBioScreen> {
  late final AudioBioController _audioBioController;

  @override
  void initState() {
    super.initState();
    _audioBioController = AudioBioController(
      onRecordingComplete: _upload,
    );
  }

  @override
  void dispose() {
    super.dispose();
    _audioBioController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          height: MediaQuery.of(context).padding.top + 32,
        ),
        Align(
          alignment: Alignment.center,
          child: Text(
            'Record your bio',
            style: Theming.of(context).text.body.copyWith(
                  color: const Color.fromRGBO(0x62, 0xCD, 0xE3, 1.0),
                  fontWeight: FontWeight.w400,
                  fontSize: 30,
                ),
          ),
        ),
        const SizedBox(height: 24),
        Align(
          alignment: Alignment.center,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Instead of typing out your bio, lets say it! Tap the record button below to record your own audio bio, this recording will only be heard by your friends.',
              textAlign: TextAlign.left,
              style: Theming.of(context).text.body.copyWith(
                    color: const Color.fromRGBO(0x99, 0x99, 0x99, 1.0),
                    fontWeight: FontWeight.w400,
                    fontSize: 18,
                  ),
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: AudioBioRecordButton(
              controller: _audioBioController,
            ),
          ),
        ),
        Consumer(
          builder: (context, ref, child) {
            final url = ref.watch(userProvider).profile!.audio;
            return AudioBioPlaybackControls(
              playbackUrl: url,
              audioBioController: _audioBioController,
            );
          },
        ),
        const SizedBox(height: 16),
        SignificantButton.blue(
          onPressed: () {
            Navigator.of(context).pushNamed('sign-up-welcome-info');
          },
          child: const Text('Continue'),
        ),
        const MaleFemaleConnectionImageApart(),
      ],
    );
  }

  void _upload(Uint8List bytes) async {
    final result = await withBlockingModal(
      context: context,
      label: 'Uploading audio',
      future: updateAudio(context: context, ref: ref, bytes: bytes),
    );

    if (!mounted) {
      return;
    }

    result.fold(
      (l) => displayError(context, l),
      (r) {},
    );
  }
}
