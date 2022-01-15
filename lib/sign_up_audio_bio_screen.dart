import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openup/api/users/users_api.dart';
import 'package:openup/util/users_api_util.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/male_female_connection_image.dart';
import 'package:openup/widgets/profile_bio.dart';
import 'package:openup/widgets/theming.dart';

class SignUpAudioBioScreen extends StatefulWidget {
  const SignUpAudioBioScreen({Key? key}) : super(key: key);

  @override
  State<SignUpAudioBioScreen> createState() => _SignUpAudioBioScreenState();
}

class _SignUpAudioBioScreenState extends State<SignUpAudioBioScreen> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.center,
          child: Text(
            'Our bio design is different than any other on the internet. Record your bio for up to 10 seconds, say anything you want and have fun!\n\n(Fill in your name by simply tapping on name)',
            textAlign: TextAlign.center,
            style: Theming.of(context).text.body.copyWith(
                  color: const Color.fromRGBO(0x99, 0x99, 0x99, 1.0),
                  fontWeight: FontWeight.w400,
                  fontSize: 18,
                ),
          ),
        ),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 371,
                maxHeight: 88,
              ),
              child: Consumer(
                builder: (context, ref, child) {
                  final editableProfile = ref.watch(profileProvider);
                  return ProfileBio(
                    key: const Key('audio_bio'),
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
          ),
        ),
        SignificantButton.pink(
          onPressed: () {
            Navigator.of(context).pushNamed('sign-up-welcome-info');
          },
          child: const Text('Continue'),
        ),
        const MaleFemaleConnectionImageApart(),
      ],
    );
  }
}
