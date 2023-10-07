import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marquee/marquee.dart';
import 'package:openup/analytics/analytics.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/location/location_provider.dart';
import 'package:openup/platform/just_audio_audio_player.dart';
import 'package:openup/widgets/back_button.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/record.dart';
import 'package:openup/widgets/restart_app.dart';
import 'package:openup/widgets/scaffold.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

import 'widgets/signup_background.dart';

class SignupAudio extends ConsumerStatefulWidget {
  const SignupAudio({
    super.key,
  });

  @override
  ConsumerState<SignupAudio> createState() => _SignupAudioState();
}

class _SignupAudioState extends ConsumerState<SignupAudio> {
  final _recorderKey = GlobalKey<SignUpRecorderState>();
  final _audioPlayer = JustAudioAudioPlayer();

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      appBar: const OpenupAppBar(
        blurBackground: false,
        body: OpenupAppBarBody(
          leading: BackIconButton(
            color: Colors.black,
          ),
        ),
      ),
      body: SignupBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 16),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/signup_recorder.png',
                  ),
                ),
                Align(
                  alignment: const Alignment(-0.15, -0.73),
                  child: Transform.rotate(
                    angle: radians(-3),
                    child: ClipRect(
                      child: SizedBox(
                        width: 176,
                        height: 94,
                        child: OverflowBox(
                          maxWidth: 500,
                          child: Center(
                              child: Marquee(
                            text:
                                'HEY ${ref.watch(accountCreationParamsProvider.select((s) => s.name?.toUpperCase()))} WHAT\'S UP... PLEASE INTRODUCE YOURSELF TO EVERYONE! ',
                            blankSpace: 64,
                            velocity: 50,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                            ),
                          )),
                        ),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: const Alignment(-0.37, -0.15),
                  child: Button(
                    onPressed: () async {
                      _audioPlayer.stop();
                      final result = await showRecordPanel(
                        context: context,
                        title: const Text('Recording Voice Bio'),
                        submitLabel: const Text('Tap to complete'),
                      );
                      if (result != null && mounted) {
                        _onAudioRecorded(result.audio, result.duration);
                      }
                    },
                    child: const SizedBox(
                      width: 72,
                      height: 72,
                    ),
                  ),
                ),
                Align(
                  alignment: const Alignment(0.25, -0.27),
                  child: Button(
                    onPressed: !ref.watch(accountCreationParamsProvider
                            .select((s) => s.audioValid))
                        ? null
                        : () {
                            final audio =
                                ref.read(accountCreationParamsProvider).audio!;
                            _audioPlayer.setPath(audio.path);
                            _audioPlayer.play();
                          },
                    child: const SizedBox(
                      width: 46,
                      height: 46,
                    ),
                  ),
                ),
                Align(
                  alignment: const Alignment(0.29, -0.02),
                  child: Button(
                    onPressed: !ref.watch(accountCreationParamsProvider
                            .select((s) => s.audioValid))
                        ? null
                        : () {
                            _audioPlayer.stop();
                            _signup();
                          },
                    child: const SizedBox(
                      width: 46,
                      height: 46,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onAudioRecorded(Uint8List audio, Duration duration) async {
    final tempDir = await getTemporaryDirectory();
    final file = File(path.join(tempDir.path, 'collection_audio.m4a'));
    await file.writeAsBytes(audio);
    ref.read(accountCreationParamsProvider.notifier).audio(file);
  }

  void _signup() async {
    _recorderKey.currentState?.stopRecording();
    ref.read(analyticsProvider).trackSignupSubmitAudio();

    final latLong = ref.read(locationProvider).current;
    ref.read(accountCreationParamsProvider.notifier).latLong(latLong);
    final params = ref.read(accountCreationParamsProvider);

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
        ref.read(userProvider.notifier).signedIn(r);
        RestartApp.restartApp(context);
      },
    );
  }
}
