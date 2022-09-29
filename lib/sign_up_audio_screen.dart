import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/widgets/common.dart';

class SignUpAudioScreen extends StatefulWidget {
  const SignUpAudioScreen({Key? key}) : super(key: key);

  @override
  State<SignUpAudioScreen> createState() => _SignUpAudioScreenState();
}

class _SignUpAudioScreenState extends State<SignUpAudioScreen> {
  RecordButtonDisplayState _recordState =
      RecordButtonDisplayState.displayingRecord;

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
                    onState: (state) async {
                      setState(() => _recordState = state);
                    },
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
                  case RecordButtonDisplayState.displayingUpload:
                    message = 'Tap this button to post';
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
              child: Text(
                '(Messages can only be upto 30 seconds on openup)',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontWeight: FontWeight.w300,
                      fontSize: 16,
                      color: const Color.fromRGBO(0x7F, 0x7F, 0x7F, 1.0),
                    ),
              ),
            ),
            const Spacer(),
            Consumer(
              builder: (context, ref, _) {
                final canGoNext = ref.watch(
                    userProvider.select((p) => p.profile?.audio != null));
                return OvalButton(
                  onPressed:
                      !canGoNext ? null : () => context.goNamed('discover'),
                  child: const Text('continue'),
                );
              },
            ),
            const SizedBox(height: 59),
          ],
        ),
      ),
    );
  }
}
