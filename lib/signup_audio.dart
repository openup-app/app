import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
  File? _audio;

  @override
  Widget build(BuildContext context) {
    final photos = ref.watch(accountCreationParamsProvider).photos ?? [];
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            itemCount: photos.length,
            itemBuilder: (context, index) {
              return Image.file(
                File(photos[index]),
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
                                : () {
                                    _signup(
                                      context: context,
                                      params: ref
                                          .read(accountCreationParamsProvider),
                                    );
                                  },
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
                  ref
                      .read(accountCreationParamsProvider.notifier)
                      .audio(result.path);
                  setState(() => _audio = result);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    vertical: 16.0, horizontal: 20.0),
                decoration: const BoxDecoration(
                  color: Color.fromRGBO(0x80, 0x0B, 0x06, 1.0),
                  borderRadius: BorderRadius.all(Radius.circular(6)),
                ),
                child: Text(
                  'Record',
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white),
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

  void _signup({
    required BuildContext context,
    required AccountCreationParams params,
  }) async {
    final result = await withBlockingModal(
      context: context,
      label: 'Creating account...',
      future: createAccount(params),
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

        ref.read(userProvider.notifier).profile(r);
        ref.read(userProvider2.notifier).signedIn(r);
        context.goNamed('signup_friends');
      },
    );
  }
}
