import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/photo_grid.dart';
import 'package:openup/widgets/theming.dart';

class SignUpAudioScreen extends StatefulWidget {
  const SignUpAudioScreen({Key? key}) : super(key: key);

  @override
  State<SignUpAudioScreen> createState() => _SignUpAudioScreenState();
}

class _SignUpAudioScreenState extends State<SignUpAudioScreen> {
  bool _hide = false;
  bool _uploading = false;
  bool _submitted = false;
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.black,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 100),
          Text(
            'Tell us why you\'re here',
            style: Theming.of(context).text.body.copyWith(
                  fontWeight: FontWeight.w300,
                  fontSize: 32,
                ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Consumer(
              builder: (context, ref, _) {
                return RecordButton(
                  label: 'Record',
                  submitLabel: 'Upload',
                  submitted: _submitted,
                  submitting: _uploading,
                  onSubmit: (path) async {
                    setState(() {
                      _uploading = true;
                      _submitted = false;
                    });
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
                    setState(() {
                      _uploading = false;
                      _submitted = true;
                    });
                  },
                  onBeginRecording: () {},
                );
              },
            ),
          ),
          Text(
            'Tap this button to record',
            style: Theming.of(context).text.body.copyWith(
                fontWeight: FontWeight.w300,
                fontSize: 24,
                color: const Color.fromRGBO(0x7F, 0x7F, 0x7F, 1.0)),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 32.0),
            child: Text(
              '(Messages can only be upto 30 seconds on openup)',
              style: Theming.of(context).text.body.copyWith(
                  fontWeight: FontWeight.w300,
                  fontSize: 16,
                  color: const Color.fromRGBO(0x7F, 0x7F, 0x7F, 1.0)),
            ),
          ),
          Consumer(
            builder: (context, ref, _) {
              final audio =
                  ref.watch(userProvider.select((p) => p.profile?.audio));
              print('audio $audio');
              return Button(
                onPressed: audio == null
                    ? null
                    : () => Navigator.of(context).pushNamed('home'),
                child: const OutlinedArea(
                  child: Center(
                    child: Text('continue'),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}
