import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get_it/get_it.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/online_users_api.dart';
import 'package:openup/api/online_users_api_util.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/platform/just_audio_audio_player.dart';
import 'package:openup/widgets/audio_bio.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/icon_with_shadow.dart';
import 'package:openup/widgets/photo3d.dart';
import 'package:openup/widgets/waveforms.dart';
import 'package:rxdart/subjects.dart';
import 'package:tuple/tuple.dart';

class CountdownTimer extends StatefulWidget {
  final String Function(Duration remaining)? formatter;
  final DateTime endTime;
  final VoidCallback onDone;
  final TextStyle? style;
  const CountdownTimer({
    Key? key,
    this.formatter,
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
      widget.formatter?.call(remaining) ??
          formatDuration(remaining, long: true),
      style: style.copyWith(
        color: remaining < const Duration(days: 1)
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
  final double blur;
  const BlurredSurface({
    Key? key,
    required this.child,
    this.blur = 75.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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

class Surface extends StatelessWidget {
  final bool squareBottom;
  final Widget child;
  const Surface({
    Key? key,
    this.squareBottom = true,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color.fromRGBO(0x00, 0x00, 0x00, 0.5),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(40),
          topRight: const Radius.circular(40),
          bottomLeft: squareBottom ? Radius.zero : const Radius.circular(40),
          bottomRight: squareBottom ? Radius.zero : const Radius.circular(40),
        ),
      ),
      child: CupertinoPopupSurface(
        child: Material(
          elevation: 0,
          type: MaterialType.transparency,
          child: child,
        ),
      ),
    );
  }
}

class ProfileImage extends StatefulWidget {
  final String photo;
  final BoxFit fit;
  final bool animate;
  final VoidCallback? onLoaded;

  const ProfileImage(
    this.photo, {
    super.key,
    this.fit = BoxFit.cover,
    this.animate = true,
    this.onLoaded,
  });

  @override
  State<ProfileImage> createState() => _ProfileImageState();
}

class _ProfileImageState extends State<ProfileImage> {
  late final _photoImageProvider = NetworkImage(widget.photo);
  late final _depthImageProvider = NetworkImage('${widget.photo}_depth');

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final futures = Future.wait([
      _decodeImage(_photoImageProvider),
      _decodeImage(_depthImageProvider),
    ]);
    futures.then((values) {
      values[0].dispose();
      values[1].dispose();
      if (mounted) {
        setState(() => _loading = false);
        widget.onLoaded?.call();
      }
    });
  }

  Future<ui.Image> _decodeImage(ImageProvider provider) {
    final completer = Completer<ui.Image>();
    final listener = ImageStreamListener((imageInfo, _) {
      completer.complete(imageInfo.image);
    }, onError: (error, stackTrace) {
      completer.completeError(error, stackTrace);
    });
    provider.resolve(ImageConfiguration.empty).addListener(listener);
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Photo3dDisplay(
          image: _photoImageProvider,
          depth: _depthImageProvider,
          animate: widget.animate,
        ),
        if (_loading)
          const Center(
            child: LoadingIndicator(),
          ),
      ],
    );
  }
}

class CinematicPhoto extends StatefulWidget {
  final Photo3d photo3d;
  final BoxFit fit;
  final bool animate;
  final VoidCallback? onLoaded;

  const CinematicPhoto({
    super.key,
    required this.photo3d,
    this.fit = BoxFit.cover,
    this.animate = true,
    this.onLoaded,
  });

  @override
  State<CinematicPhoto> createState() => _CinematicPhotoState();
}

class _CinematicPhotoState extends State<CinematicPhoto> {
  late final _photoImageProvider = NetworkImage(widget.photo3d.url);
  late final _depthImageProvider = NetworkImage(widget.photo3d.depthUrl);

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final futures = Future.wait([
      _decodeImage(_photoImageProvider),
      _decodeImage(_depthImageProvider),
    ]);
    futures.then((values) {
      values[0].dispose();
      values[1].dispose();
      if (mounted) {
        setState(() => _loading = false);
        widget.onLoaded?.call();
      }
    });
  }

  Future<ui.Image> _decodeImage(ImageProvider provider) {
    final completer = Completer<ui.Image>();
    final listener = ImageStreamListener((imageInfo, _) {
      completer.complete(imageInfo.image);
    }, onError: (error, stackTrace) {
      completer.completeError(error, stackTrace);
    });
    provider.resolve(ImageConfiguration.empty).addListener(listener);
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Photo3dDisplay(
          image: _photoImageProvider,
          depth: _depthImageProvider,
          animate: widget.animate,
        ),
        if (_loading)
          const Center(
            child: LoadingIndicator(),
          ),
      ],
    );
  }
}

class RecordButton extends StatefulWidget {
  final String label;
  final Duration minimumRecordTime;
  final String submitLabel;
  final bool submitting;
  final bool submitted;
  final void Function(String path) onSubmit;
  final void Function() onBeginRecording;

  const RecordButton({
    Key? key,
    required this.label,
    this.minimumRecordTime = const Duration(seconds: 0),
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

              final lessThanMinimumRecordingTime =
                  DateTime.now().difference(_recordingStart) <
                      widget.minimumRecordTime;
              if (recordInfo.recording) {
                return Button(
                  onPressed: lessThanMinimumRecordingTime
                      ? null
                      : _inviteRecorder.stopRecording,
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
  displayingPlayStop,
}

class RecordButtonSignUp extends StatefulWidget {
  final void Function(RecordButtonDisplayState state) onState;
  final void Function(Uint8List? bytes) onAudioBytes;

  const RecordButtonSignUp({
    Key? key,
    required this.onState,
    required this.onAudioBytes,
  }) : super(key: key);

  @override
  State<RecordButtonSignUp> createState() => RecordButtonSignUpState();
}

class RecordButtonSignUpState extends State<RecordButtonSignUp> {
  late final AudioBioController _inviteRecorder;
  final _audioPlayer = JustAudioAudioPlayer();
  Uint8List? _audioBytes;
  DateTime _recordingStart = DateTime.now();

  @override
  void initState() {
    super.initState();
    _inviteRecorder = AudioBioController(
      onRecordingComplete: (path) async {
        if (mounted) {
          final bytes = await File(path).readAsBytes();
          if (mounted) {
            _audioPlayer.setPath(path);
            setState(() => _audioBytes = bytes);
          }
          widget.onAudioBytes(bytes);
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
    _audioPlayer.dispose();
    super.dispose();
  }

  void stop() => _audioPlayer.stop();

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
              final lessThanFiveSeconds =
                  DateTime.now().difference(_recordingStart) <
                      const Duration(seconds: 5);
              if (_audioBytes == null) {
                return Button(
                  onPressed: lessThanFiveSeconds && recordInfo.recording
                      ? null
                      : () async {
                          if (recordInfo.recording) {
                            await _inviteRecorder.stopRecording();
                            if (mounted) {
                              widget.onState(
                                  RecordButtonDisplayState.displayingPlayStop);
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
                  Button(
                    onPressed: () {
                      _audioPlayer.stop();
                      widget.onState(RecordButtonDisplayState.displayingRecord);
                      setState(() => _audioBytes = null);
                      widget.onAudioBytes(null);
                    },
                    child: const SizedBox(
                      width: 72,
                      child: Icon(
                        Icons.delete,
                        size: 44,
                        color: Colors.red,
                      ),
                    ),
                  ),
                  Container(
                    width: 97,
                    height: 97,
                    alignment: Alignment.center,
                    child: StreamBuilder<PlaybackInfo>(
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
                          child: Container(
                            padding: const EdgeInsets.all(8.0),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              border: Border.all(
                                width: 2,
                                color: Colors.white,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: playbackInfo.state == PlaybackState.playing
                                ? const Center(
                                    child: Icon(
                                      Icons.stop,
                                      size: 56,
                                    ),
                                  )
                                : const Center(
                                    child: Icon(
                                      Icons.play_arrow,
                                      size: 56,
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(
                    width: 72,
                    child: StreamBuilder<PlaybackInfo>(
                      stream: _audioPlayer.playbackInfoStream,
                      initialData: const PlaybackInfo(),
                      builder: (context, snapshot) {
                        final playbackInfo = snapshot.requireData;
                        return Text(
                          formatDuration(
                            playbackInfo.state == PlaybackState.playing
                                ? playbackInfo.position
                                : playbackInfo.duration,
                            canBeZero:
                                playbackInfo.state == PlaybackState.playing,
                          ),
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w300,
                                  ),
                        );
                      },
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

class RecordPanelContents extends StatefulWidget {
  final void Function(Uint8List audio) onSubmit;

  const RecordPanelContents({
    super.key,
    required this.onSubmit,
  });

  @override
  State<RecordPanelContents> createState() => _RecordPanelContentsState();
}

class _RecordPanelContentsState extends State<RecordPanelContents> {
  final _controller = PlaybackRecorderController();

  late Ticker _countdownTicker;
  var _countdown = Duration.zero;
  Uint8List? _recordingBytes;

  @override
  void initState() {
    super.initState();

    // _recorder = AudioBioController(
    //   onRecordingComplete: (path) {
    //     if (mounted) {
    //       setState(() => _recordingPath = path);
    //     }
    //   },
    // );

    // _recorder.recordInfoStream.listen((recordInfo) {
    //   if (_recording != recordInfo.recording) {
    //     setState(() => _recording = recordInfo.recording);
    //   }
    // });

    _restartCountdown();
  }

  @override
  void dispose() {
    _countdownTicker.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _restartCountdown() {
    setState(() {
      _recordingBytes = null;
      _countdown = const Duration(seconds: 3);
    });
    _countdownTicker = Ticker(
      (duration) {
        setState(() => _countdown = duration);
        if (duration >= const Duration(seconds: 3)) {
          _countdownTicker.stop();
          _controller.startRecording(
            onComplete: (recordingBytes) {
              setState(() => _recordingBytes = recordingBytes);
            },
          );
        }
      },
    );
    _countdownTicker.start();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Tuple2<RecordingInfo, PlaybackInfo>>(
      stream: _controller.combinedStream,
      initialData: Tuple2(RecordingInfo.none(), const PlaybackInfo()),
      builder: (context, snapshot) {
        final recordingInfo = snapshot.requireData.item1;
        final playbackInfo = snapshot.requireData.item2;
        return Button(
          onPressed: () {
            if (!recordingInfo.recording && _recordingBytes == null) {
              Navigator.of(context).pop();
            } else {
              _controller.stopRecording();
            }
          },
          child: SizedBox(
            height: 234,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                Text(
                  'Recording message',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium!
                      .copyWith(fontSize: 20, fontWeight: FontWeight.w300),
                ),
                if (recordingInfo.recording) ...[
                  const SizedBox(height: 8),
                  Text(
                    formatDurationWithMillis(
                      recordingInfo.duration,
                      canBeZero: true,
                    ),
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium!
                        .copyWith(fontSize: 16, fontWeight: FontWeight.w300),
                  ),
                ],
                Expanded(
                  child: Center(
                    child: Builder(
                      builder: (context) {
                        if (_recordingBytes == null) {
                          if (recordingInfo.recording) {
                            return Center(
                              child: SizedBox(
                                width: 345,
                                height: 80,
                                child: CustomPaint(
                                  painter: FrequenciesPainter(
                                    frequencies: recordingInfo.frequencies
                                        .map((e) => e.y),
                                    barCount: 54,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            );
                          }

                          return Text(
                            ((const Duration(seconds: 3) - _countdown)
                                        .inSeconds +
                                    1)
                                .toString(),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w300,
                                    color: const Color.fromRGBO(
                                        0xFF, 0x00, 0x00, 1.0)),
                          );
                        } else {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Button(
                                onPressed: Navigator.of(context).pop,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.delete,
                                        color: Color.fromRGBO(
                                            0xFF, 0x00, 0x00, 1.0),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'delete',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium!
                                            .copyWith(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w300),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Button(
                                onPressed: () => _restartCountdown(),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.loop),
                                      const SizedBox(height: 12),
                                      Text(
                                        'retry',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium!
                                            .copyWith(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w300),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Button(
                                onPressed: () =>
                                    widget.onSubmit(_recordingBytes!),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.send),
                                      const SizedBox(height: 12),
                                      Text(
                                        'send',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium!
                                            .copyWith(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w300),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        }
                      },
                    ),
                  ),
                ),
                Visibility(
                  visible: _recordingBytes == null,
                  child: Text(
                    'tap to stop',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium!
                        .copyWith(fontSize: 16, fontWeight: FontWeight.w300),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: MediaQuery.of(context).padding.bottom,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class PlaybackRecorder extends StatefulWidget {
  final PlaybackRecorderController controller;
  final Widget Function(
    BuildContext context,
    RecordingInfo recordingInfo,
    PlaybackInfo playbackInfo,
  ) builder;

  const PlaybackRecorder({
    super.key,
    required this.controller,
    required this.builder,
  });

  @override
  State<PlaybackRecorder> createState() => _PlaybackRecorderState();
}

class _PlaybackRecorderState extends State<PlaybackRecorder> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Tuple2<RecordingInfo, PlaybackInfo>>(
      stream: widget.controller.combinedStream,
      initialData: Tuple2(RecordingInfo.none(), const PlaybackInfo()),
      builder: (context, snapshot) {
        final value = snapshot.requireData;
        return widget.builder(
          context,
          value.item1,
          value.item2,
        );
      },
    );
  }
}

class PlaybackRecorderController extends ChangeNotifier {
  late final AudioBioController _playbackController;
  final _recorder = RecorderWithWaveforms();

  final _combinedController =
      BehaviorSubject<Tuple2<RecordingInfo, PlaybackInfo>>.seeded(
          Tuple2(RecordingInfo.none(), const PlaybackInfo()));

  PlaybackRecorderController() : super() {
    _playbackController = AudioBioController(onRecordingComplete: (_) {});

    _playbackController.playbackInfoStream.listen((playbackInfo) {
      final value = _combinedController.value;
      _combinedController.add(Tuple2(value.item1, playbackInfo));
    });
  }

  Stream<Tuple2<RecordingInfo, PlaybackInfo>> get combinedStream =>
      _combinedController.stream;

  @override
  void dispose() {
    super.dispose();
    _combinedController.close();
    _playbackController.dispose();
    _recorder.dispose();
  }

  void startRecording({
    Duration maxDuration = const Duration(seconds: 30),
    required void Function(Uint8List bytes) onComplete,
  }) {
    _recorder.startRecording(
      onFrequencies: (frequencies) {
        final value = _combinedController.value;
        final recordingInfo = value.item1.copyWith(frequencies: frequencies);
        _combinedController.add(Tuple2(recordingInfo, value.item2));
      },
      onComplete: onComplete,
    );

    final value = _combinedController.value;
    final recordingInfo = value.item1.copyWith(recording: true);
    _combinedController.add(Tuple2(recordingInfo, value.item2));
  }

  void stopRecording() {
    _recorder.stopRecording();

    final value = _combinedController.value;
    final recordingInfo = RecordingInfo.none();
    _combinedController.add(Tuple2(recordingInfo, value.item2));
  }

  void startPlayback() => _playbackController.play();

  void pausePlayback() => _playbackController.pause();

  void stopPlayback() => _playbackController.stop();
}

class RecordingInfo {
  final bool recording;
  final Duration duration;
  final Float64x2List frequencies;

  const RecordingInfo(
    this.recording,
    this.duration,
    this.frequencies,
  );

  RecordingInfo.none()
      : recording = false,
        duration = Duration.zero,
        frequencies = Float64x2List(0);

  RecordingInfo copyWith({
    bool? recording,
    Duration? duration,
    Float64x2List? frequencies,
  }) {
    return RecordingInfo(
      recording ?? this.recording,
      duration ?? this.duration,
      frequencies ?? this.frequencies,
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
    return Container(
      width: 19,
      height: 19,
      alignment: Alignment.center,
      child: const SizedBox(
        width: 7,
        height: 7,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Color.fromRGBO(0xFF, 0x00, 0x00, 1.0),
          ),
        ),
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

class ReportBlockPopupMenu2 extends ConsumerStatefulWidget {
  final String uid;
  final String name;
  final VoidCallback onBlock;
  final WidgetBuilder builder;
  const ReportBlockPopupMenu2({
    Key? key,
    required this.uid,
    required this.name,
    required this.onBlock,
    required this.builder,
  }) : super(key: key);

  @override
  ConsumerState<ReportBlockPopupMenu2> createState() =>
      _ReportBlockPopupMenuState2();
}

class _ReportBlockPopupMenuState2 extends ConsumerState<ReportBlockPopupMenu2> {
  @override
  Widget build(BuildContext context) {
    return Button(
      onPressed: () {
        showCupertinoModalPopup(
          context: context,
          barrierColor: const Color.fromRGBO(0x00, 0x00, 0x00, 0.5),
          builder: (context) {
            return CupertinoActionSheet(
              cancelButton: CupertinoActionSheetAction(
                onPressed: () => _showBlockDialog(context),
                child: const Text('Block User'),
              ),
              actions: [
                CupertinoActionSheetAction(
                  onPressed: () => _showReportModal(context),
                  child: const Text('Report User'),
                ),
              ],
            );
          },
        );
      },
      child: widget.builder(context),
    );
  }

  void _showBlockDialog(BuildContext context) async {
    final block = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) {
        return Center(
          child: Surface(
            squareBottom: false,
            child: Padding(
              padding: const EdgeInsets.all(36.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Block "${widget.name}"?',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium!
                          .copyWith(fontSize: 24, fontWeight: FontWeight.w300),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'They won\'t see you anywhere on this app, and won\'t be able to send you messages.\n\nYou won\'t see them anywhere, and won\'t be able to send them messages.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium!
                        .copyWith(fontSize: 15, fontWeight: FontWeight.w300),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Button(
                        onPressed: () {
                          Navigator.of(context).pop(true);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Block',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                    color: const Color.fromRGBO(
                                        0xFF, 0x07, 0x07, 1.0),
                                    fontSize: 20,
                                    fontWeight: FontWeight.w300),
                          ),
                        ),
                      ),
                      Button(
                        onPressed: Navigator.of(context).pop,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Cancel',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                    fontSize: 20, fontWeight: FontWeight.w300),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (block == true && mounted) {
      final myUid = ref.read(userProvider).uid;
      final api = GetIt.instance.get<Api>();
      final blockFuture = api.blockUser(myUid, widget.uid);
      await withBlockingModal(
        context: context,
        label: 'Blocking...',
        future: blockFuture,
      );
      widget.onBlock();
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _showReportModal(BuildContext context) async {
    final reportReason = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return Surface(
          child: Padding(
            padding: const EdgeInsets.all(36.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Why are you reporting this account?',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium!
                      .copyWith(fontSize: 24, fontWeight: FontWeight.w300),
                ),
                const SizedBox(height: 8),
                RadioTile(
                  label: 'Impersonation or deceptive identity',
                  onTap: () => Navigator.of(context).pop("deceptive"),
                ),
                RadioTile(
                  label: 'Nudity or sexual activity',
                  onTap: () => Navigator.of(context).pop("sexual"),
                ),
                RadioTile(
                  label: 'Suicide or self-harm',
                  onTap: () => Navigator.of(context).pop("self-harm"),
                ),
                RadioTile(
                  label: 'Violence or harmful content',
                  onTap: () => Navigator.of(context).pop("harmful"),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (reportReason != null && mounted) {
      final myUid = ref.read(userProvider).uid;
      final api = GetIt.instance.get<Api>();
      final reportFuture = api.reportUser(
        uid: myUid,
        reportedUid: widget.uid,
        reason: reportReason,
      );
      await withBlockingModal(
        context: context,
        label: 'Reporting...',
        future: reportFuture,
      );
    }

    if (reportReason != null && mounted) {
      final block = await showCupertinoDialog<bool>(
        context: context,
        builder: (context) {
          return Center(
            child: Surface(
              squareBottom: false,
              child: Padding(
                padding: const EdgeInsets.all(36.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Thank you for submitting your report',
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            fontSize: 24, fontWeight: FontWeight.w300),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'We will investigate this issue.\n\nAdditionally you can block the user so they can\'t discover your account.',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium!
                          .copyWith(fontSize: 15, fontWeight: FontWeight.w300),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Button(
                          onPressed: () {
                            Navigator.of(context).pop(true);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              'Block',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(
                                      color: const Color.fromRGBO(
                                          0xFF, 0x07, 0x07, 1.0),
                                      fontSize: 20,
                                      fontWeight: FontWeight.w300),
                            ),
                          ),
                        ),
                        Button(
                          onPressed: Navigator.of(context).pop,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              'Done',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w300),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );

      if (block == true && mounted) {
        final myUid = ref.read(userProvider).uid;
        final api = GetIt.instance.get<Api>();
        final blockFuture = api.blockUser(myUid, widget.uid);
        await withBlockingModal(
          context: context,
          label: 'Blocking...',
          future: blockFuture,
        );
        widget.onBlock();
      }
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}

class RadioTile extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool? selected;
  final bool radioAtEnd;
  final TextStyle? style;

  const RadioTile({
    super.key,
    required this.label,
    this.selected,
    required this.onTap,
    this.radioAtEnd = false,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Button(
      onPressed: onTap,
      child: SizedBox(
        height: 51,
        child: Row(
          children: [
            if (!radioAtEnd)
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: selected == true ? Colors.white : null,
                  border: const Border(
                    left: BorderSide(color: Colors.white, width: 2),
                    top: BorderSide(color: Colors.white, width: 2),
                    right: BorderSide(color: Colors.white, width: 2),
                    bottom: BorderSide(color: Colors.white, width: 2),
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            const SizedBox(width: 18),
            Text(
              label,
              style: style ??
                  Theme.of(context)
                      .textTheme
                      .bodyMedium!
                      .copyWith(fontSize: 14, fontWeight: FontWeight.w300),
            ),
            const Spacer(),
            if (radioAtEnd)
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: selected == true ? Colors.white : null,
                  border: const Border(
                    left: BorderSide(color: Colors.white, width: 2),
                    top: BorderSide(color: Colors.white, width: 2),
                    right: BorderSide(color: Colors.white, width: 2),
                    bottom: BorderSide(color: Colors.white, width: 2),
                  ),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
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

String formatDurationWithMillis(
  Duration d, {
  bool canBeZero = false,
}) {
  if (!canBeZero && d.inSeconds < 1) {
    return '00:00:01';
  }
  return '${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}:${(d.inMilliseconds % 100).toString().padLeft(2, '0')}';
}

String formatCountdown(Duration d) {
  if (d.inDays > 1) {
    return '${d.inDays} days';
  } else if (d.inHours > 24) {
    return '1 day';
  } else if (d.inHours > 1) {
    return '${d.inHours} hours';
  } else if (d.inHours > 0) {
    return '${d.inHours} hour';
  } else {
    return '${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
  }
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
