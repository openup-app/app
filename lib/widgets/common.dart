import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/date_symbols.dart';
import 'package:lottie/lottie.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/online_users_api.dart';
import 'package:openup/api/online_users_api_util.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/platform/just_audio_audio_player.dart';
import 'package:openup/widgets/audio_bio.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/icon_with_shadow.dart';
import 'package:openup/widgets/image_builder.dart';

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
        Theme.of(context).textTheme.bodyMedium!.copyWith(
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
          Theme.of(context).textTheme.bodyMedium!.copyWith(
                fontWeight: FontWeight.w500,
                color: const Color.fromRGBO(0x7B, 0x7B, 0x7B, 1.0),
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

class ProfileImage extends StatelessWidget {
  final String photo;
  final BoxFit fit;
  final bool blur;
  final double blurSigma;
  const ProfileImage(
    this.photo, {
    super.key,
    this.fit = BoxFit.cover,
    this.blurSigma = 10.0,
    required this.blur,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Image.network(
        photo,
        fit: fit,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          return fadeInFrameBuilder(
            context,
            blur ? _blurred(child) : child,
            frame,
            wasSynchronouslyLoaded,
          );
        },
        loadingBuilder: (context, child, progress) {
          return loadingBuilder(
            context,
            blur ? _blurred(child) : child,
            progress,
          );
        },
        errorBuilder: iconErrorBuilder,
      ),
    );
  }

  Widget _blurred(Widget child) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(
        sigmaX: blurSigma,
        sigmaY: blurSigma,
      ),
      child: child,
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
                        Color.fromRGBO(0xC3, 0x06, 0x06, 1.0),
                        Color.fromRGBO(0x64, 0x00, 0x00, 1.0),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.send),
                        const SizedBox(width: 16),
                        Text(
                          'Your invitation has been sent!',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium!
                              .copyWith(fontWeight: FontWeight.w400),
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white),
                              shape: BoxShape.circle,
                            ),
                            child: const DecoratedBox(
                              decoration: BoxDecoration(
                                color: Color.fromRGBO(0xFF, 0x00, 0x00, 1.0),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Text(
                            widget.label,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w400,
                                ),
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
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w300,
                                ),
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
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium!
                                    .copyWith(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w300,
                                    ),
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
                              ? const LoadingIndicator(size: 32)
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
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium!
                              .copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color:
                                    const Color.fromRGBO(0x70, 0x70, 0x70, 1.0),
                              ),
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
                  onPressed: () async {
                    if (recordInfo.recording) {
                      await _inviteRecorder.stopRecording();
                      if (mounted) {
                        if (_recordingStart.difference(DateTime.now()) <
                            const Duration(seconds: 5)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Must record at least 5 seconds'),
                            ),
                          );
                          widget.onState(
                              RecordButtonDisplayState.displayingRecord);
                          setState(() {
                            _submitted = false;
                            _audioBytes = null;
                          });
                        } else {
                          widget.onState(
                              RecordButtonDisplayState.displayingUpload);
                        }
                      }
                    } else {
                      await _inviteRecorder.startRecording();
                      if (mounted) {
                        setState(() => _recordingStart = DateTime.now());
                        widget.onState(
                            RecordButtonDisplayState.displayingRecording);
                      }
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
                      if (recordInfo.recording)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 200.0),
                            child: Text(
                              recordInfo.recording
                                  ? formatDuration(
                                      DateTime.now()
                                          .difference(_recordingStart),
                                      canBeZero: true)
                                  : formatDuration(
                                      Duration.zero,
                                      canBeZero: true,
                                    ),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w300,
                                  ),
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
                            return const LoadingIndicator();
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
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium!
                                      .copyWith(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w300,
                                      ),
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
      maxDuration: const Duration(seconds: 60),
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
                        width: 68,
                        height: 68,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: AnimatedContainer(
                            width: recordInfo.recording ? 35 : 62,
                            height: recordInfo.recording ? 35 : 62,
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color:
                                  const Color.fromRGBO(0xFF, 0x00, 0x00, 1.0),
                              shape: BoxShape.rectangle,
                              borderRadius: recordInfo.recording
                                  ? const BorderRadius.all(Radius.circular(6))
                                  : const BorderRadius.all(Radius.circular(30)),
                            ),
                          ),
                        ),
                      ),
                      if (recordInfo.recording)
                        Align(
                          alignment: Alignment.center,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 140.0),
                            child: Text(
                              formatDuration(
                                  DateTime.now().difference(_recordingStart)),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w300,
                                  ),
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
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w300,
                                  ),
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
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
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w300,
                  color: selected ? Colors.black : null,
                ),
          ),
        ),
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

class OnlineIndicatorBuilder extends StatefulWidget {
  final String uid;
  final Widget Function(BuildContext context, bool online) builder;

  const OnlineIndicatorBuilder({
    super.key,
    required this.uid,
    required this.builder,
  });

  @override
  State<OnlineIndicatorBuilder> createState() => OnlineIndicatorBuilderState();
}

class OnlineIndicatorBuilderState extends State<OnlineIndicatorBuilder> {
  @override
  void initState() {
    super.initState();
    _subscribe(widget.uid);
  }

  @override
  void didUpdateWidget(covariant OnlineIndicatorBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uid != widget.uid) {
      _unsubscribe(oldWidget.uid);
      _subscribe(widget.uid);
    }
  }

  @override
  void dispose() {
    _unsubscribe(widget.uid);
    super.dispose();
  }

  void _subscribe(String uid) {
    final onlineUsersApi = GetIt.instance.get<OnlineUsersApi>();
    onlineUsersApi.subscribeToOnlineStatus(uid);
  }

  void _unsubscribe(String uid) {
    final onlineUsersApi = GetIt.instance.get<OnlineUsersApi>();
    onlineUsersApi.unsubscribeToOnlineStatus(uid);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final isOnline = ref
            .watch(onlineUsersProvider.select((p) => p.isOnline(widget.uid)));
        return widget.builder(context, isOnline);
      },
    );
  }
}

class OnlineIndicator extends StatelessWidget {
  const OnlineIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedOverflowBox(
      size: const Size(24, 24),
      child: Lottie.asset(
        'assets/images/online.json',
        width: 72,
        height: 72,
      ),
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

class LoadingIndicator extends StatelessWidget {
  final double size;
  final Color color;
  const LoadingIndicator({
    super.key,
    this.size = 50,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return SpinKitWave(
      size: size,
      color: color,
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
    case Topic.moved:
      return 'Just Moved';
    case Topic.sports:
      return 'Sports fan';
    case Topic.sleep:
      return 'Can\'t Sleep';
    case Topic.books:
      return 'Bookworm';
    case Topic.school:
      return 'New to School';
    case Topic.gym:
      return 'Gym Fanatic';
    case Topic.lonely:
      return 'Lonely';
    case Topic.videoGames:
      return 'Video Game Lover';
    case Topic.restaurants:
      return 'Restaurant-goer';
    case Topic.tourism:
      return 'Tourist';
    case Topic.party:
      return 'Partygoer';
    case Topic.backpacking:
      return 'Backpacker';
    case Topic.dance:
      return 'Dancer';
    case Topic.conversation:
      return 'Conversationalist';
  }
}
