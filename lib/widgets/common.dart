import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:openup/platform/just_audio_audio_player.dart';
import 'package:openup/widgets/audio_bio.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/theming.dart';

/// Prominent button with a horizontal gradient styling.
class SignificantButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final BorderRadius borderRadius;
  final double height;
  final Gradient gradient;

  const SignificantButton({
    Key? key,
    required this.onPressed,
    required this.gradient,
    required this.child,
  })  : borderRadius = const BorderRadius.all(Radius.circular(94)),
        height = 69.0,
        super(key: key);

  const SignificantButton.pink({
    Key? key,
    required this.onPressed,
    required this.child,
  })  : borderRadius = const BorderRadius.all(Radius.circular(94)),
        height = 69.0,
        gradient = const LinearGradient(
          colors: [
            Color.fromRGBO(0xFF, 0x83, 0x83, 1.0),
            Color.fromRGBO(0x8A, 0x0, 0x00, 1.0),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        super(key: key);

  const SignificantButton.blue({
    Key? key,
    required this.onPressed,
    required this.child,
  })  : borderRadius = const BorderRadius.all(Radius.circular(94)),
        height = 69.0,
        gradient = const LinearGradient(
          colors: [
            Color.fromRGBO(0x26, 0xC4, 0xE6, 1.0),
            Color.fromRGBO(0x7B, 0xDC, 0xF1, 1.0),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Button(
      onPressed: onPressed,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 300),
        height: height,
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          gradient: gradient,
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class BlurredSurface extends StatelessWidget {
  final Widget child;
  const BlurredSurface({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const blur = 75.0;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: child,
      ),
    );
  }
}

// class RecordButton extends StatelessWidget {
//   final String label;
//   const RecordButton({
//     Key? key,
//     required this.label,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Button(
//       onPressed: () {},
//       child: Container(
//         height: 67,
//
//         child: Center(
//           child: Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Container(
//                 width: 36,
//                 height: 36,
//                 padding: const EdgeInsets.all(2),
//                 decoration: BoxDecoration(
//                   border: Border.all(color: Colors.white),
//                   shape: BoxShape.circle,
//                 ),
//                 child: Container(
//                   decoration: const BoxDecoration(
//                       color: Colors.red, shape: BoxShape.circle),
//                 ),
//               ),
//               const SizedBox(width: 14),
//               Text(
//                 label,
//                 style: Theming.of(context)
//                     .text
//                     .body
//                     .copyWith(fontSize: 20, fontWeight: FontWeight.w300),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

class RecordButton extends StatefulWidget {
  final String label;
  final String submitLabel;
  final bool submitting;
  final bool submitted;
  final void Function(String path) onSubmit;
  const RecordButton({
    Key? key,
    required this.label,
    required this.submitLabel,
    required this.submitting,
    required this.submitted,
    required this.onSubmit,
  }) : super(key: key);

  @override
  State<RecordButton> createState() => RecordButtonState();
}

class RecordButtonState extends State<RecordButton> {
  late final AudioBioController _inviteRecorder;
  final _invitePlayer = JustAudioAudioPlayer();
  String? _audioPath;

  @override
  void initState() {
    super.initState();
    _inviteRecorder = AudioBioController(
      onRecordingComplete: (path) async {
        if (mounted) {
          setState(() => _audioPath = path);
        }
      },
    );
  }

  @override
  void dispose() {
    _inviteRecorder.dispose();
    _invitePlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<RecordInfo>(
      initialData: const RecordInfo(),
      stream: _inviteRecorder.recordInfoStream,
      builder: (context, snapshot) {
        final recordInfo = snapshot.requireData;
        return SizedBox(
          height: 67,
          child: Builder(
            builder: (context) {
              if (widget.submitted) {
                return Container(
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(
                      Radius.circular(40),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color.fromRGBO(0x8F, 0x14, 0x14, 1.0),
                        Color.fromRGBO(0x8F, 0x32, 0x32, 1.0),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Your invitation has been sent today!',
                      style: Theming.of(context)
                          .text
                          .body
                          .copyWith(fontSize: 18, fontWeight: FontWeight.w400),
                    ),
                  ),
                );
              }

              if (!recordInfo.recording && _audioPath == null) {
                return Button(
                  onPressed: _inviteRecorder.startRecording,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: recordInfo.recording
                          ? const Color.fromRGBO(0xFF, 0x00, 0x00, 1.0)
                          : null,
                      border: recordInfo.recording
                          ? null
                          : Border.all(
                              color:
                                  const Color.fromRGBO(0xA9, 0xA9, 0xA9, 1.0),
                            ),
                      borderRadius: const BorderRadius.all(
                        Radius.circular(40),
                      ),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white),
                              shape: BoxShape.circle,
                            ),
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Text(
                            widget.label,
                            style: Theming.of(context).text.body.copyWith(
                                fontSize: 20, fontWeight: FontWeight.w300),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              if (recordInfo.recording) {
                return Button(
                  onPressed: _inviteRecorder.stopRecording,
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      color: Color.fromRGBO(0xFF, 0x00, 0x00, 1.0),
                      borderRadius: BorderRadius.all(
                        Radius.circular(40),
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.stop,
                            size: 30,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'recording',
                            style: Theming.of(context).text.body.copyWith(
                                fontSize: 20, fontWeight: FontWeight.w300),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return DecoratedBox(
                decoration: const BoxDecoration(
                  color: Color.fromRGBO(0x32, 0x32, 0x32, 0.5),
                  borderRadius: BorderRadius.all(
                    Radius.circular(40),
                  ),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 20),
                    StreamBuilder<PlaybackInfo>(
                        stream: _invitePlayer.playbackInfoStream,
                        initialData: const PlaybackInfo(),
                        builder: (context, snapshot) {
                          final playbackInfo = snapshot.requireData;
                          return Button(
                            onPressed: widget.submitting
                                ? null
                                : () async {
                                    if (playbackInfo.state ==
                                        PlaybackState.playing) {
                                      _invitePlayer.stop();
                                    } else {
                                      _invitePlayer.play();
                                    }
                                  },
                            child: SizedBox(
                              width: 41,
                              height: 41,
                              child: playbackInfo.state == PlaybackState.playing
                                  ? const Center(
                                      child: Icon(
                                        Icons.stop,
                                        size: 34,
                                      ),
                                    )
                                  : const Center(
                                      child: Icon(
                                        Icons.play_arrow,
                                        size: 34,
                                      ),
                                    ),
                            ),
                          );
                        }),
                    Button(
                      onPressed: widget.submitting
                          ? null
                          : () => setState(() => _audioPath = null),
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.delete,
                          size: 34,
                          color: Colors.red,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.submitLabel,
                      style: Theming.of(context)
                          .text
                          .body
                          .copyWith(fontSize: 20, fontWeight: FontWeight.w300),
                    ),
                    const Spacer(),
                    Button(
                      onPressed: widget.submitting
                          ? null
                          : () => widget.onSubmit(_audioPath!),
                      child: widget.submitting
                          ? const CircularProgressIndicator()
                          : Container(
                              padding: const EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                    color: const Color.fromRGBO(
                                        0x82, 0x82, 0x82, 1.0)),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.arrow_upward,
                                  size: 20,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(width: 24),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onSelected;
  const Chip({
    Key? key,
    required this.label,
    required this.selected,
    this.onSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Button(
      onPressed: onSelected,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? Colors.white
              : const Color.fromRGBO(0x77, 0x77, 0x77, 1.0),
          borderRadius: const BorderRadius.all(Radius.circular(50)),
          border: selected
              ? Border.all(color: Colors.white)
              : Border.all(
                  color: const Color.fromRGBO(0xB9, 0xB9, 0xB9, 1.0),
                ),
        ),
        child: Text(
          label,
          style: Theming.of(context).text.body.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w300,
              color: selected ? Colors.black : null),
        ),
      ),
    );
  }
}

class OutlinedArea extends StatelessWidget {
  final Widget child;
  const OutlinedArea({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 51,
      margin: const EdgeInsets.only(left: 16, right: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white),
        borderRadius: const BorderRadius.all(
          Radius.circular(40),
        ),
      ),
      child: Center(
        child: child,
      ),
    );
  }
}
