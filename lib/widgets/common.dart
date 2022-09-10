import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/api/users/profile.dart';
import 'package:openup/platform/just_audio_audio_player.dart';
import 'package:openup/widgets/audio_bio.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/icon_with_shadow.dart';
import 'package:openup/widgets/image_builder.dart';
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

class CountdownTimer extends StatefulWidget {
  final DateTime endTime;
  final VoidCallback onDone;
  final TextStyle? style;
  const CountdownTimer({
    Key? key,
    required this.endTime,
    required this.onDone,
    this.style,
  }) : super(key: key);

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        final remaining = widget.endTime.difference(DateTime.now());
        if (remaining.isNegative) {
          widget.onDone();
        } else {
          setState(() {});
        }
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.endTime.difference(DateTime.now());
    final style = widget.style ??
        Theming.of(context).text.body.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w400,
            );
    return Text(
      formatDuration(remaining, long: true),
      style: style.copyWith(
        color: remaining < const Duration(hours: 3)
            ? const Color.fromRGBO(0xFF, 0x00, 0x00, 1.0)
            : null,
      ),
    );
  }
}

class CountUpTimer extends StatefulWidget {
  final DateTime start;
  final TextStyle? style;
  const CountUpTimer({
    Key? key,
    required this.start,
    this.style,
  }) : super(key: key);

  @override
  State<CountUpTimer> createState() => _CountUpTimerState();
}

class _CountUpTimerState extends State<CountUpTimer> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    super.dispose();
    _timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final time = DateTime.now().difference(widget.start);
    return Text(
      formatDuration(time, long: true),
      style: widget.style ??
          Theming.of(context).text.body.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: const Color.fromRGBO(0x7B, 0x7B, 0x7B, 1.0)),
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
        child: Stack(
          fit: StackFit.expand,
          children: [
            const AbsorbPointer(),
            child,
          ],
        ),
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

class ProfileImage extends StatelessWidget {
  final String photo;
  final BoxFit fit;
  final bool blur;
  const ProfileImage(
    this.photo, {
    super.key,
    this.fit = BoxFit.cover,
    required this.blur,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      clipBehavior: Clip.hardEdge,
      child: ImageFiltered(
        enabled: blur,
        imageFilter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Image.network(
          photo,
          fit: fit,
          frameBuilder: fadeInFrameBuilder,
          loadingBuilder: circularProgressLoadingBuilder,
          errorBuilder: iconErrorBuilder,
        ),
      ),
    );
  }
}

class _RecordingIndicator extends StatelessWidget {
  final _colors = const [
    Color.fromARGB(255, 202, 0, 0),
    Color.fromARGB(255, 255, 52, 37),
    Color.fromARGB(255, 249, 99, 24),
    Color.fromARGB(255, 255, 200, 0),
    Color.fromARGB(255, 252, 241, 113),
    Color.fromARGB(255, 255, 244, 28),
    Color.fromARGB(255, 255, 204, 0),
    Color.fromARGB(255, 249, 99, 24),
    Color.fromARGB(255, 255, 52, 37),
    Color.fromARGB(255, 202, 0, 0),
  ];
  final _durations = const [780, 450, 600, 500, 685, 850, 725, 675, 625, 825];

  @override
  Widget build(BuildContext context) {
    const length = 10;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (var i = 0; i < length; i++)
          _RecordingIndicatorBar(
            duration: Duration(milliseconds: _durations[i % length]),
            color: _colors[i % length],
          ),
      ],
    );
  }
}

class _RecordingIndicatorBar extends StatefulWidget {
  final Duration duration;
  final Color color;

  const _RecordingIndicatorBar({
    Key? key,
    required this.duration,
    required this.color,
  }) : super(key: key);

  @override
  _RecordingIndicatorBarState createState() => _RecordingIndicatorBarState();
}

class _RecordingIndicatorBarState extends State<_RecordingIndicatorBar>
    with SingleTickerProviderStateMixin {
  late final Animation<double> _animation;
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    final curvedAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutExpo,
    );
    _animation = Tween<double>(begin: 0, end: 100).animate(curvedAnimation);
    _animation.addListener(() => setState(() {}));
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      decoration: BoxDecoration(
        color: widget.color,
        borderRadius: BorderRadius.circular(5),
      ),
      height: _animation.value,
    );
  }
}

class RecordButton extends StatefulWidget {
  final String label;
  final String submitLabel;
  final bool submitting;
  final bool submitted;
  final void Function(String path) onSubmit;
  final void Function() onBeginRecording;

  const RecordButton({
    Key? key,
    required this.label,
    required this.submitLabel,
    required this.submitting,
    required this.submitted,
    required this.onSubmit,
    required this.onBeginRecording,
  }) : super(key: key);

  @override
  State<RecordButton> createState() => RecordButtonState();
}

class RecordButtonState extends State<RecordButton> {
  late final AudioBioController _inviteRecorder;
  final _invitePlayer = JustAudioAudioPlayer();
  String? _audioPath;
  DateTime _recordingStart = DateTime.now();

  @override
  void initState() {
    super.initState();
    _inviteRecorder = AudioBioController(
      onRecordingComplete: (path) async {
        if (mounted) {
          _invitePlayer.setPath(path);
          setState(() => _audioPath = path);
        }
      },
    );
  }

  @override
  void didUpdateWidget(covariant RecordButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.submitting && !widget.submitting) {
      _audioPath = null;
    }
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
                    child: Row(
                      children: [
                        const Icon(Icons.send),
                        const SizedBox(width: 16),
                        Text(
                          'Your invitation has been sent!',
                          style: Theming.of(context).text.body.copyWith(
                              fontSize: 18, fontWeight: FontWeight.w400),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (!recordInfo.recording && _audioPath == null) {
                return Button(
                  onPressed: () {
                    widget.onBeginRecording();
                    setState(() => _recordingStart = DateTime.now());
                    _inviteRecorder.startRecording();
                  },
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
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 3),
                          SizedBox(
                            width: 80,
                            height: 40,
                            child: _RecordingIndicator(),
                          ),
                          Text(
                            widget.label,
                            style: Theming.of(context).text.body.copyWith(
                                fontSize: 20, fontWeight: FontWeight.w400),
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
                    decoration: BoxDecoration(
                      gradient: recordInfo.recording
                          ? const LinearGradient(
                              colors: [
                                Color.fromRGBO(0xFF, 0x00, 0x00, 1.0),
                                Color.fromRGBO(0xCD, 0x00, 0x00, 1.0),
                              ],
                            )
                          : null,
                      borderRadius: const BorderRadius.all(
                        Radius.circular(40),
                      ),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.stop,
                            size: 30,
                          ),
                          const SizedBox(width: 20),
                          Text(
                            'recording message',
                            style: Theming.of(context).text.body.copyWith(
                                fontSize: 20, fontWeight: FontWeight.w300),
                          ),
                          const SizedBox(width: 20),
                          Builder(
                            builder: (context) {
                              final time =
                                  DateTime.now().difference(_recordingStart);
                              return Text(
                                formatDuration(
                                  time,
                                  canBeZero: true,
                                ),
                                style: Theming.of(context).text.body.copyWith(
                                    fontSize: 20, fontWeight: FontWeight.w300),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black,
                  border: Border.all(
                    color: const Color.fromRGBO(0xA9, 0xA9, 0xA9, 1.0),
                  ),
                  borderRadius: const BorderRadius.all(
                    Radius.circular(40),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    const SizedBox(width: 16),
                    Button(
                      onPressed: widget.submitting
                          ? null
                          : () {
                              _invitePlayer.stop();
                              setState(() => _audioPath = null);
                            },
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.delete,
                          size: 34,
                          color: Color.fromRGBO(0xFF, 0x21, 0x21, 1.0),
                        ),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Button(
                          onPressed: widget.submitting
                              ? null
                              : () => widget.onSubmit(_audioPath!),
                          child: widget.submitting
                              ? const CircularProgressIndicator()
                              : Container(
                                  padding: const EdgeInsets.all(4.0),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(
                                        color: const Color.fromRGBO(
                                            0x82, 0x82, 0x82, 1.0)),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.arrow_upward_rounded,
                                      size: 28,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.submitLabel,
                          style: Theming.of(context).text.body.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color:
                                  const Color.fromRGBO(0x70, 0x70, 0x70, 1.0)),
                        ),
                      ],
                    ),
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
                      },
                    ),
                    const SizedBox(width: 16),
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

enum RecordButtonDisplayState {
  displayingRecord,
  displayingRecording,
  displayingUpload,
}

class RecordButtonSignUp extends StatefulWidget {
  final void Function(RecordButtonDisplayState state) onState;

  const RecordButtonSignUp({
    Key? key,
    required this.onState,
  }) : super(key: key);

  @override
  State<RecordButtonSignUp> createState() => RecordButtonSignUpState();
}

class RecordButtonSignUpState extends State<RecordButtonSignUp> {
  late final AudioBioController _inviteRecorder;
  final _invitePlayer = JustAudioAudioPlayer();
  Uint8List? _audioBytes;
  DateTime _recordingStart = DateTime.now();
  bool _submitted = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _inviteRecorder = AudioBioController(
      onRecordingComplete: (path) async {
        if (mounted) {
          final bytes = await File(path).readAsBytes();
          if (mounted) {
            _invitePlayer.setPath(path);
            setState(() => _audioBytes = bytes);
          }
        }
      },
    );
    Future.delayed(Duration.zero, () {
      if (mounted) {
        widget.onState(RecordButtonDisplayState.displayingRecord);
      }
    });
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
          height: 91,
          child: Builder(
            builder: (context) {
              if (_audioBytes == null) {
                return Button(
                  onPressed: () {
                    if (recordInfo.recording) {
                      _inviteRecorder.stopRecording();
                      widget.onState(RecordButtonDisplayState.displayingUpload);
                    } else {
                      _inviteRecorder.startRecording();
                      setState(() => _recordingStart = DateTime.now());
                      widget.onState(
                          RecordButtonDisplayState.displayingRecording);
                    }
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 91,
                        height: 91,
                        padding: const EdgeInsets.all(4),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 2),
                          shape: BoxShape.circle,
                        ),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          child: Container(
                            margin: recordInfo.recording
                                ? const EdgeInsets.all(15)
                                : EdgeInsets.zero,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: recordInfo.recording
                                  ? BorderRadius.circular(10)
                                  : BorderRadius.circular(100),
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 200.0),
                          child: Text(
                            recordInfo.recording
                                ? formatDuration(
                                    DateTime.now().difference(_recordingStart),
                                    canBeZero: true)
                                : formatDuration(
                                    Duration.zero,
                                    canBeZero: true,
                                  ),
                            style: Theming.of(context).text.body.copyWith(
                                fontSize: 20, fontWeight: FontWeight.w300),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SizedBox(
                    width: 72,
                    child: Button(
                      onPressed: _submitting
                          ? null
                          : () {
                              _invitePlayer.stop();
                              widget.onState(
                                  RecordButtonDisplayState.displayingRecord);
                              setState(() {
                                _submitted = false;
                                _audioBytes = null;
                              });
                            },
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.delete,
                          size: 44,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 97,
                    height: 97,
                    child: Center(
                      child: Consumer(
                        builder: (context, ref, _) {
                          if (_submitting) {
                            return const CircularProgressIndicator();
                          }

                          if (_submitted) {
                            return Container(
                              padding: const EdgeInsets.all(8.0),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                    color: const Color.fromRGBO(
                                        0x82, 0x82, 0x82, 1.0)),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.done,
                                size: 48,
                                color: Colors.green,
                              ),
                            );
                          }

                          return Button(
                            onPressed: _submitting || _submitted
                                ? null
                                : () async {
                                    final audioBytes = _audioBytes;
                                    if (audioBytes == null) {
                                      return;
                                    }
                                    setState(() => _submitting = true);

                                    final result = await updateAudio(
                                      context: context,
                                      ref: ref,
                                      bytes: audioBytes,
                                    );
                                    if (!mounted) {
                                      return;
                                    }

                                    setState(() => _submitting = false);
                                    result.fold(
                                      (l) => displayError(context, l),
                                      (r) => setState(() => _submitted = true),
                                    );
                                  },
                            child: Container(
                              padding: const EdgeInsets.all(8.0),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                    color: const Color.fromRGBO(
                                        0x82, 0x82, 0x82, 1.0)),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_upward_rounded,
                                size: 48,
                                color: Colors.black,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 72,
                    child: Center(
                      child: StreamBuilder<PlaybackInfo>(
                        stream: _invitePlayer.playbackInfoStream,
                        initialData: const PlaybackInfo(),
                        builder: (context, snapshot) {
                          final playbackInfo = snapshot.requireData;
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              Button(
                                onPressed: _submitting
                                    ? null
                                    : () async {
                                        if (playbackInfo.state ==
                                            PlaybackState.playing) {
                                          _invitePlayer.stop();
                                        } else {
                                          _invitePlayer.play();
                                        }
                                      },
                                child:
                                    playbackInfo.state == PlaybackState.playing
                                        ? const Center(
                                            child: Icon(
                                              Icons.stop,
                                              size: 44,
                                            ),
                                          )
                                        : const Center(
                                            child: Icon(
                                              Icons.play_arrow,
                                              size: 44,
                                            ),
                                          ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 72.0),
                                child: Text(
                                  formatDuration(
                                    playbackInfo.state == PlaybackState.playing
                                        ? playbackInfo.position
                                        : playbackInfo.duration,
                                    canBeZero: playbackInfo.state ==
                                        PlaybackState.playing,
                                  ),
                                  textAlign: TextAlign.center,
                                  style: Theming.of(context).text.body.copyWith(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w300),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class RecordButtonChat extends StatefulWidget {
  final void Function(String path) onSubmit;
  final void Function() onBeginRecording;
  final void Function() onEndRecording;

  const RecordButtonChat({
    Key? key,
    required this.onSubmit,
    required this.onBeginRecording,
    required this.onEndRecording,
  }) : super(key: key);

  @override
  State<RecordButtonChat> createState() => RecordButtonChatState();
}

class RecordButtonChatState extends State<RecordButtonChat> {
  late final AudioBioController _recorder;
  final _audioPlayer = JustAudioAudioPlayer();
  String? _audioPath;
  DateTime _recordingStart = DateTime.now();

  @override
  void initState() {
    super.initState();
    _recorder = AudioBioController(
      maxDuration: const Duration(seconds: 30),
      onRecordingComplete: (path) async {
        if (mounted) {
          setState(() => _audioPath = path);
          _audioPlayer.setPath(path);
        }
      },
    );
  }

  @override
  void dispose() {
    _recorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<RecordInfo>(
      initialData: const RecordInfo(),
      stream: _recorder.recordInfoStream,
      builder: (context, snapshot) {
        final recordInfo = snapshot.requireData;
        return Container(
          height: 87,
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color.fromRGBO(0x32, 0x32, 0x32, 1.0),
            ),
            borderRadius: BorderRadius.circular(50),
          ),
          alignment: Alignment.center,
          child: Builder(
            builder: (context) {
              if (_audioPath == null) {
                return Button(
                  onPressed: () {
                    if (recordInfo.recording) {
                      widget.onEndRecording();
                      _recorder.stopRecording();
                    } else {
                      widget.onBeginRecording();
                      _recorder.startRecording();
                      setState(() {
                        _recordingStart = DateTime.now();
                      });
                    }
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: AnimatedContainer(
                            width: recordInfo.recording ? 27 : 50,
                            height: recordInfo.recording ? 27 : 50,
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color:
                                  const Color.fromRGBO(0xFF, 0x00, 0x00, 1.0),
                              shape: BoxShape.rectangle,
                              borderRadius: recordInfo.recording
                                  ? const BorderRadius.all(Radius.circular(2))
                                  : const BorderRadius.all(Radius.circular(25)),
                            ),
                          ),
                        ),
                      ),
                      if (recordInfo.recording)
                        Align(
                          alignment: Alignment.center,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 104.0),
                            child: Text(
                              formatDuration(
                                  DateTime.now().difference(_recordingStart)),
                              style: Theming.of(context).text.body.copyWith(
                                  fontSize: 20, fontWeight: FontWeight.w300),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Button(
                    onPressed: () {
                      _audioPlayer.stop();
                      setState(() => _audioPath = null);
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.delete,
                        size: 34,
                        color: Colors.red,
                      ),
                    ),
                  ),
                  Button(
                    onPressed: () {
                      _audioPlayer.stop();
                      widget.onSubmit(_audioPath!);
                      setState(() => _audioPath = null);
                    },
                    child: Container(
                      width: 56,
                      height: 56,
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                            color: const Color.fromRGBO(0x82, 0x82, 0x82, 1.0)),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.arrow_upward,
                          size: 32,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  StreamBuilder<PlaybackInfo>(
                    stream: _audioPlayer.playbackInfoStream,
                    initialData: const PlaybackInfo(),
                    builder: (context, snapshot) {
                      final playbackInfo = snapshot.requireData;
                      return Button(
                        onPressed: () async {
                          if (playbackInfo.state == PlaybackState.playing) {
                            _audioPlayer.stop();
                          } else {
                            _audioPlayer.play();
                          }
                        },
                        child: Column(
                          children: [
                            const SizedBox(height: 22),
                            SizedBox(
                              width: 41,
                              child: playbackInfo.state == PlaybackState.playing
                                  ? const Center(
                                      child: Icon(
                                        Icons.stop,
                                        size: 32,
                                      ),
                                    )
                                  : const Center(
                                      child: Icon(
                                        Icons.play_arrow,
                                        size: 32,
                                      ),
                                    ),
                            ),
                            Text(
                              playbackInfo.state == PlaybackState.playing
                                  ? formatDuration(playbackInfo.position)
                                  : formatDuration(playbackInfo.duration),
                              style: Theming.of(context).text.body.copyWith(
                                  fontSize: 15, fontWeight: FontWeight.w300),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
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
  final double? height;
  final bool selected;
  final VoidCallback? onSelected;
  const Chip({
    Key? key,
    required this.label,
    this.height,
    required this.selected,
    this.onSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Button(
      onPressed: onSelected,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
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
        child: Padding(
          // Setting height on container expands the container to max width
          // this is just a hacky goodenough workaround to set height
          padding:
              EdgeInsets.symmetric(vertical: max(0, (height ?? 0) - 38) / 2),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theming.of(context).text.body.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w300,
                color: selected ? Colors.black : null),
          ),
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

class OvalButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  const OvalButton({
    Key? key,
    required this.onPressed,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Button(
      onPressed: onPressed,
      child: Container(
        width: 305,
        height: 63,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(
            Radius.circular(58),
          ),
        ),
        child: Center(
          child: DefaultTextStyle.merge(
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w300,
              color: Colors.black,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class OnlineIndicator extends StatelessWidget {
  const OnlineIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.circle,
      color: Color.fromRGBO(0x01, 0xA5, 0x43, 1.0),
      size: 16,
    );
  }
}

class ReportBlockPopupMenu extends ConsumerStatefulWidget {
  final String uid;
  final String name;
  final VoidCallback onBlock;
  final VoidCallback onReport;
  const ReportBlockPopupMenu({
    Key? key,
    required this.uid,
    required this.name,
    required this.onBlock,
    required this.onReport,
  }) : super(key: key);

  @override
  ConsumerState<ReportBlockPopupMenu> createState() =>
      _ReportBlockPopupMenuState();
}

class _ReportBlockPopupMenuState extends ConsumerState<ReportBlockPopupMenu> {
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      padding: EdgeInsets.zero,
      icon: const IconWithShadow(Icons.more_horiz, size: 32),
      onSelected: (value) {
        if (value == 'block') {
          showDialog(
            context: context,
            builder: (context) {
              return CupertinoTheme(
                data: const CupertinoThemeData(brightness: Brightness.dark),
                child: CupertinoAlertDialog(
                  title: Text('Block ${widget.name}?'),
                  content: Text(
                      '${widget.name} will be unable to see or call you, and you will not be able to see or call ${widget.name}.'),
                  actions: [
                    CupertinoDialogAction(
                      onPressed: Navigator.of(context).pop,
                      child: const Text('Cancel'),
                    ),
                    CupertinoDialogAction(
                      onPressed: () async {
                        final myUid = ref.read(userProvider).uid;
                        final api = GetIt.instance.get<Api>();
                        await api.blockUser(myUid, widget.uid);
                        if (mounted) {
                          Navigator.of(context).pop();
                          widget.onBlock();
                        }
                      },
                      isDestructiveAction: true,
                      child: const Text('Block'),
                    ),
                  ],
                ),
              );
            },
          );
        } else if (value == 'report') {
          widget.onReport();
        }
      },
      itemBuilder: (context) {
        return [
          const PopupMenuItem(
            value: 'block',
            child: ListTile(
              title: Text('Block user'),
              trailing: Icon(Icons.block),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const PopupMenuItem(
            value: 'report',
            child: ListTile(
              title: Text('Report user'),
              trailing: Icon(Icons.flag_outlined),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ];
      },
    );
  }
}

String formatDuration(
  Duration d, {
  bool long = false,
  bool canBeZero = false,
}) {
  if (long || d.inHours > 1) {
    return '${(d.inHours).toString().padLeft(2, '0')}:${(d.inMinutes % 60).toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
  }
  if (!canBeZero && d.inSeconds < 1) {
    return '00:01';
  }
  return '${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
}

String topicLabel(Topic topic) {
  switch (topic) {
    case Topic.lonely:
      return 'Lonely';
    case Topic.moved:
      return 'Just Moved';
    case Topic.sleep:
      return 'Can\'t Sleep';
    case Topic.bored:
      return 'Bored';
    case Topic.introvert:
      return 'Introvert';
    case Topic.sad:
      return 'Sad';
    case Topic.talk:
      return 'Talk';
  }
}
