import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openup/analytics/analytics.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/widgets/back_button.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class SignupAudio extends ConsumerStatefulWidget {
  const SignupAudio({
    super.key,
  });

  @override
  ConsumerState<SignupAudio> createState() => _SignupAudioState();
}

class _SignupAudioState extends ConsumerState<SignupAudio> {
  final _recorderKey = GlobalKey<SignUpRecorderState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(0xF2, 0xF2, 0xF6, 1.0),
      resizeToAvoidBottomInset: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: MediaQuery.of(context).padding.top,
          ),
          const SizedBox(height: 16),
          const Align(
            alignment: Alignment.topCenter,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: BackIconButton(
                    color: Colors.black,
                  ),
                ),
                Text(
                  'Add a voice bio',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Text(
            'To join you must add a voice bio',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Color.fromRGBO(0x8D, 0x8D, 0x8D, 1.0),
            ),
          ),
          Expanded(
            child: SignUpRecorder(
              key: _recorderKey,
              onAudioRecorded: _onAudioRecorded,
            ),
          ),
          Button(
            onPressed: ref.watch(accountCreationParamsProvider
                    .select((p) => p.audio == null))
                ? null
                : () =>
                    _signup(params: ref.read(accountCreationParamsProvider)),
            child: RoundedRectangleContainer(
              child: SizedBox(
                width: 171,
                height: 42,
                child: Center(
                  child: Text(
                    'Next',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium!
                        .copyWith(fontSize: 20, fontWeight: FontWeight.w400),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 36),
          SizedBox(
            height: MediaQuery.of(context).padding.bottom,
          ),
        ],
      ),
    );
  }

  void _onAudioRecorded(Uint8List audio, Duration duration) async {
    final tempDir = await getTemporaryDirectory();
    final file = File(path.join(tempDir.path, 'collection_audio.m4a'));
    await file.writeAsBytes(audio);
    ref.read(accountCreationParamsProvider.notifier).audio(file);
  }

  void _signup({
    required AccountCreationParams params,
  }) async {
    _recorderKey.currentState?.stopRecording();
    ref.read(analyticsProvider).trackSignupSubmitAudio();

    final result = await withBlockingModal(
      context: context,
      label: 'Creating account...',
      future: ref.read(userProvider.notifier).createAccount(params),
    );
    if (!mounted) {
      return;
    }

    result.fold(
      (l) => displayError(context, l),
      (r) {
        if (!mounted) {
          return;
        }

        final analytics = ref.read(analyticsProvider);
        analytics.setUserProperty('name', r.profile.name);
        analytics.setUserProperty('age', r.profile.age);
        analytics.setUserProperty('gender', r.profile.gender.name);
        ref.read(userProvider.notifier).signedIn(r);
        context.goNamed('signup_friends');
      },
    );
  }
}
