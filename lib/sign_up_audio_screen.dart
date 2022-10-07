import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/widgets/common.dart';

class SignUpAudioScreen extends StatefulWidget {
  const SignUpAudioScreen({Key? key}) : super(key: key);

  @override
  State<SignUpAudioScreen> createState() => _SignUpAudioScreenState();
}

class _SignUpAudioScreenState extends State<SignUpAudioScreen> {
  RecordButtonDisplayState _recordState =
      RecordButtonDisplayState.displayingRecord;

  Uint8List? _audioBytes;
  bool _uploaded = false;
  final _recordButtonKey = GlobalKey<RecordButtonSignUpState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 75),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Tell us why you\'re here',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 36,
                    ),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Consumer(
                builder: (context, ref, _) {
                  return RecordButtonSignUp(
                    key: _recordButtonKey,
                    onState: (state) => setState(() => _recordState = state),
                    onAudioBytes: (bytes) =>
                        setState(() => _audioBytes = bytes),
                  );
                },
              ),
            ),
            Builder(
              builder: (context) {
                final String message;
                switch (_recordState) {
                  case RecordButtonDisplayState.displayingRecord:
                    message = 'Tap this button to record';
                    break;
                  case RecordButtonDisplayState.displayingRecording:
                    message = 'Tap this button to stop';
                    break;
                  case RecordButtonDisplayState.displayingPlayStop:
                    message = 'Tap this button to play';
                    break;
                }
                return Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.w300,
                        fontSize: 24,
                        color: const Color.fromRGBO(0x7F, 0x7F, 0x7F, 1.0),
                      ),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.only(
                  top: 16, bottom: 32.0, left: 8, right: 8),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: Text(
                  'Messages can only be upto 30 seconds on openup. Must record a minimum of 5 seconds in order to join.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.w400,
                        fontSize: 16,
                      ),
                ),
              ),
            ),
            const Spacer(),
            Consumer(
              builder: (context, ref, child) {
                return OvalButton(
                  onPressed: _uploaded
                      ? () => context.goNamed('discover')
                      : (_audioBytes == null
                          ? null
                          : () async {
                              final result = await _upload(ref);
                              if (result && mounted) {
                                context.goNamed('discover');
                              }
                            }),
                  child: child!,
                );
              },
              child: const Text('continue'),
            ),
            const SizedBox(height: 59),
          ],
        ),
      ),
    );
  }

  Future<bool> _upload(WidgetRef ref) async {
    _recordButtonKey.currentState?.stop();

    final audioBytes = _audioBytes;
    if (audioBytes == null) {
      return false;
    }

    final uploadFuture = updateAudio(
      context: context,
      ref: ref,
      bytes: audioBytes,
    );
    final uploadResult = await withBlockingModal(
      context: context,
      label: 'Uploading audio',
      future: uploadFuture,
    );

    if (!mounted) {
      return false;
    }

    return uploadResult.fold(
      (l) {
        displayError(context, l);
        return false;
      },
      (r) {
        GetIt.instance.get<Mixpanel>().track("sign_up_submit_audio");
        setState(() => _uploaded = true);
        return true;
      },
    );
  }
}
