import 'dart:io';
import 'dart:typed_data';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openup/analytics/analytics.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/location/location_provider.dart';
import 'package:openup/signup_glamour_preview.dart';
import 'package:openup/widgets/gradient_mask.dart';
import 'package:openup/widgets/record.dart';
import 'package:openup/widgets/scaffold.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class SignupGlamourAudio extends ConsumerStatefulWidget {
  const SignupGlamourAudio({
    super.key,
  });

  @override
  ConsumerState<SignupGlamourAudio> createState() => _SignupGlamourAudioState();
}

class _SignupGlamourAudioState extends ConsumerState<SignupGlamourAudio> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      appBar: OpenupAppBar(
        blurBackground: false,
        body: OpenupAppBarBody(
          leadingPadding: EdgeInsets.zero,
          trailingPadding: EdgeInsets.zero,
          leading: OpenupAppBarTextButton(
            onPressed: Navigator.of(context).pop,
            label: 'back',
          ),
          trailing: OpenupAppBarTextButton(
            onPressed: !_canSubmit(ref.watch(accountCreationParamsProvider))
                ? null
                : _submit,
            label: 'finish',
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            top: MediaQuery.of(context).padding.top + 89,
            left: 0,
            right: 0,
            child: const GradientMask(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white,
                  Color.fromRGBO(0x56, 0x56, 0x56, 1.0),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 29),
                child: AutoSizeText(
                  'Introduce\nyourself to\neveryone',
                  maxLines: 3,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).padding.bottom,
            height: 256,
            child: WobblyRingsRecorder(
              autoStart: false,
              submitLabel: const Text('Tap to finish'),
              onRecordingComplete: (audio, duration) async {
                await _onAudioRecorded(audio, duration);
                return Future.value();
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onAudioRecorded(Uint8List audio, Duration duration) async {
    final tempDir = await getTemporaryDirectory();
    final file = File(path.join(tempDir.path, 'collection_audio.m4a'));
    await file.writeAsBytes(audio);
    ref.read(accountCreationParamsProvider.notifier).audio(file);
  }

  bool _canSubmit(AccountCreationParams params) => params.audioValid;

  void _submit() async {
    if (!_canSubmit(ref.read(accountCreationParamsProvider))) {
      return;
    }
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
        context.goNamed(
          'signup_preview',
          extra: SignupGlamourPreviewArgs(r.profile),
        );
      },
    );
  }
}
