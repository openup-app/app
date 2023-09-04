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
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/online_users_provider.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/platform/just_audio_audio_player.dart';
import 'package:openup/widgets/audio_bio.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/photo3d.dart';
import 'package:openup/widgets/waveforms.dart';
import 'package:permission_handler/permission_handler.dart';
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
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
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
          animate: false,
          duration: Duration.zero,
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
  final Duration duration;

  const CinematicPhoto({
    super.key,
    required this.photo3d,
    this.fit = BoxFit.cover,
    this.animate = true,
    this.onLoaded,
    required this.duration,
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
          duration: widget.duration,
        ),
        if (_loading)
          const Center(
            child: LoadingIndicator(),
          ),
      ],
    );
  }
}

class NonCinematicPhoto extends StatefulWidget {
  final String url;
  final BoxFit fit;
  final bool animate;
  final VoidCallback? onLoaded;
  final Duration duration;

  const NonCinematicPhoto({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.animate = true,
    this.onLoaded,
    required this.duration,
  });

  @override
  State<NonCinematicPhoto> createState() => _NonCinematicPhotoState();
}

class _NonCinematicPhotoState extends State<NonCinematicPhoto>
    with SingleTickerProviderStateMixin {
  late final _photoImageProvider = NetworkImage(widget.url);

  bool _loading = true;

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    final futures = Future.wait([
      _decodeImage(_photoImageProvider),
    ]);
    futures.then((values) {
      values[0].dispose();
      if (mounted) {
        setState(() => _loading = false);
        widget.onLoaded?.call();
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: 1 + _controller.value * 0.1,
              child: child,
            );
          },
          child: Image(
            image: _photoImageProvider,
            fit: BoxFit.cover,
          ),
        ),
        if (_loading)
          const Center(
            child: LoadingIndicator(
              color: Colors.black,
            ),
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
                              ? const LoadingIndicator()
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

class SignUpRecorder extends ConsumerStatefulWidget {
  final void Function(Uint8List audio, Duration duration) onAudioRecorded;

  const SignUpRecorder({
    super.key,
    required this.onAudioRecorded,
  });

  @override
  ConsumerState<SignUpRecorder> createState() => SignUpRecorderState();
}

class SignUpRecorderState extends ConsumerState<SignUpRecorder> {
  static const _maxDuration = Duration(seconds: 30);

  PlaybackRecorderController? _controller;
  final _recordingDurationNotifier = RecordingDurationNotifier(Duration.zero);
  Ticker? _recordingDurationTicker;

  RecordPanelState _audioBioState = RecordPanelState.deciding;
  Duration? _duration;

  @override
  void dispose() {
    _recordingDurationNotifier.dispose();
    _recordingDurationTicker?.dispose();
    _controller?.dispose();
    super.dispose();
  }

  Future<bool> _hasMicrophonePermission() async {
    const permission = Permission.microphone;
    var status = await permission.status;
    if (status == PermissionStatus.granted ||
        status == PermissionStatus.limited) {
      return true;
    }
    return false;
  }

  Future<void> _requestMicrophonePermission() =>
      Permission.microphone.request();

  void _startRecording() async {
    if (!await _hasMicrophonePermission()) {
      await _requestMicrophonePermission();
      if (!await _hasMicrophonePermission()) {
        return;
      }
    }
    if (!mounted) {
      return;
    }

    _controller?.dispose();
    final controller = PlaybackRecorderController();
    setState(() => _controller = controller);
    await controller.startRecording(
      maxDuration: _maxDuration,
      onComplete: _onRecordingEnded,
    );
    if (mounted) {
      setState(() {
        _audioBioState = RecordPanelState.creating;
        _recordingDurationTicker = Ticker((d) {
          final start = (controller._combinedController.value).item1.start;
          _recordingDurationNotifier.value = DateTime.now().difference(start);
        });
      });
      _recordingDurationTicker?.start();
    }
  }

  void stopRecording() => _stopRecording();

  void _stopRecording() => _controller?.stopRecording();

  void _onRecordingEnded(Uint8List? recordingBytes) {
    _recordingDurationTicker?.dispose();

    if (recordingBytes == null) {
      setState(() {
        _recordingDurationTicker = null;
        _audioBioState = RecordPanelState.deciding;
      });
      return;
    }

    setState(() {
      _recordingDurationTicker = null;
      _duration = _recordingDurationNotifier.value;
      _audioBioState = RecordPanelState.deciding;
    });

    widget.onAudioRecorded(recordingBytes, _recordingDurationNotifier.value);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Spacer(),
        Builder(
          builder: (context) {
            switch (_audioBioState) {
              case RecordPanelState.creating:
                return ValueListenableBuilder<Duration>(
                  valueListenable: _recordingDurationNotifier,
                  builder: (context, duration, child) {
                    return RecordPanelRecorder(
                      duration: duration,
                      maxDuration: _maxDuration,
                      onPressed: _stopRecording,
                    );
                  },
                );
              default:
                return RecordPanelRecorder(
                  duration: _duration ?? Duration.zero,
                  maxDuration: _maxDuration,
                  onPressed: _startRecording,
                );
            }
          },
        ),
        const SizedBox(height: 59),
        ValueListenableBuilder<Duration>(
          valueListenable: _recordingDurationNotifier,
          builder: (context, recordingDuration, child) {
            return Button(
              onPressed: (_audioBioState == RecordPanelState.creating &&
                      recordingDuration < const Duration(seconds: 2))
                  ? null
                  : (_audioBioState == RecordPanelState.creating
                      ? _stopRecording
                      : _startRecording),
              child: Container(
                width: 163,
                height: 56,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(
                    Radius.circular(28),
                  ),
                  color: Colors.white,
                ),
                child: Center(
                  child: DefaultTextStyle(
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                    child: Builder(
                      builder: (context) {
                        switch (_audioBioState) {
                          case RecordPanelState.creating:
                            return const Text('Stop');
                          default:
                            return const Text('Record');
                        }
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const Spacer(),
      ],
    );
  }
}

class RecordPanel extends ConsumerStatefulWidget {
  final Widget title;
  final Widget submitLabel;
  final VoidCallback onCancel;
  final Future<bool> Function(Uint8List audio, Duration duration) onSubmit;

  const RecordPanel({
    super.key,
    required this.title,
    required this.submitLabel,
    required this.onCancel,
    required this.onSubmit,
  });

  @override
  ConsumerState<RecordPanel> createState() => _RecordPanelState();
}

class _RecordPanelState extends ConsumerState<RecordPanel> {
  static const _maxDuration = Duration(seconds: 30);

  PlaybackRecorderController? _controller;
  final _recordingDurationNotifier = RecordingDurationNotifier(Duration.zero);
  Ticker? _recordingDurationTicker;

  RecordPanelState _audioBioState = RecordPanelState.creating;
  Uint8List? _audio;
  Duration? _duration;

  @override
  void initState() {
    super.initState();
    // Avoid jank by starting to record after panel animation
    Future.delayed(const Duration(milliseconds: 200)).then((_) {
      if (mounted) {
        _startRecording();
      }
    });
  }

  @override
  void dispose() {
    _recordingDurationNotifier.dispose();
    _recordingDurationTicker?.dispose();
    _controller?.dispose();
    super.dispose();
  }

  void _startRecording() async {
    _controller?.dispose();
    final controller = PlaybackRecorderController();
    setState(() => _controller = controller);
    await controller.startRecording(
      maxDuration: _maxDuration,
      onComplete: _onRecordingEnded,
    );
    if (mounted) {
      setState(() {
        _audioBioState = RecordPanelState.creating;
        _recordingDurationTicker = Ticker((d) {
          final start = (controller._combinedController.value).item1.start;
          _recordingDurationNotifier.value = DateTime.now().difference(start);
        });
      });
      _recordingDurationTicker?.start();
    }
  }

  void _onRecordingEnded(Uint8List? recordingBytes) {
    _recordingDurationTicker?.dispose();

    if (recordingBytes == null) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _recordingDurationTicker = null;
      _audio = recordingBytes;
      _duration = _recordingDurationNotifier.value;
      _audioBioState = RecordPanelState.deciding;
    });

    _onSubmit();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          right: 16,
          top: 16,
          width: 48,
          height: 48,
          child: Button(
            onPressed: Navigator.of(context).pop,
            child: Container(
              margin: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color.fromRGBO(0xFF, 0xFF, 0xFF, 0.5),
              ),
              child: const Icon(
                Icons.close,
                color: Color.fromRGBO(0x44, 0x44, 0x44, 1.0),
                size: 16,
              ),
            ),
          ),
        ),
        Column(
          children: [
            const SizedBox(height: 44),
            DefaultTextStyle(
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.white,
              ),
              child: widget.title,
            ),
            const SizedBox(height: 40),
            Builder(
              builder: (context) {
                switch (_audioBioState) {
                  case RecordPanelState.creating:
                    return ValueListenableBuilder<Duration>(
                      valueListenable: _recordingDurationNotifier,
                      builder: (context, duration, child) {
                        return RecordPanelRecorder(
                          duration: duration,
                          maxDuration: _maxDuration,
                          onPressed: () => _controller?.stopRecording(),
                        );
                      },
                    );
                  case RecordPanelState.deciding:
                    return RecordPanelDeciding(
                      audio: _audio!,
                      onRestart: () {
                        setState(() {
                          _audio = null;
                          _duration = null;
                          _audioBioState = RecordPanelState.creating;
                          _recordingDurationNotifier.value = Duration.zero;
                          _recordingDurationTicker?.dispose();
                        });
                        _startRecording();
                      },
                    );
                  case RecordPanelState.uploading:
                  case RecordPanelState.uploaded:
                    return const Center(
                      child: LoadingIndicator(
                        color: Colors.black,
                      ),
                    );
                }
              },
            ),
            const Spacer(),
            Button(
              onPressed: _onMaybeStopAndSubmit,
              child: Container(
                height: 56,
                margin: const EdgeInsets.symmetric(horizontal: 57),
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(
                    Radius.circular(11),
                  ),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      offset: Offset(0, 2),
                      blurRadius: 17,
                      color: Color.fromRGBO(0x00, 0x00, 0x00, 0.0625),
                    )
                  ],
                ),
                child: Center(
                  child: DefaultTextStyle(
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                    child: widget.submitLabel,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: MediaQuery.of(context).padding.bottom,
            ),
          ],
        ),
      ],
    );
  }

  void _onMaybeStopAndSubmit() {
    if (_audio == null) {
      _controller?.stopRecording();
    } else {
      _onSubmit();
    }
  }

  void _onSubmit() async {
    setState(() => _audioBioState = RecordPanelState.uploading);
    final success = await widget.onSubmit(_audio!, _duration!);
    if (!mounted) {
      return;
    }

    if (success) {
      setState(() => _audioBioState = RecordPanelState.uploaded);
    } else {
      setState(() => _audioBioState = RecordPanelState.deciding);
    }
  }
}

class RecordPanelSurface extends StatelessWidget {
  final Widget child;

  const RecordPanelSurface({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 460 + 67,
      child: Padding(
        padding: const EdgeInsets.only(top: 67.0),
        child: Container(
          clipBehavior: Clip.hardEdge,
          decoration: const BoxDecoration(
            color: Color.fromRGBO(0x00, 0x00, 0x00, 0.3),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                blurRadius: 50,
                color: Color.fromRGBO(0x00, 0x00, 0x00, 0.1),
                blurStyle: BlurStyle.outer,
              ),
            ],
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 48, sigmaY: 48),
            child: child,
          ),
        ),
      ),
    );
  }
}

enum RecordPanelState { creating, deciding, uploading, uploaded }

class RecordPanelRecorder extends StatelessWidget {
  final Duration duration;
  final Duration maxDuration;
  final VoidCallback onPressed;

  const RecordPanelRecorder({
    super.key,
    required this.duration,
    required this.maxDuration,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Button(
      onPressed: onPressed,
      child: Container(
        width: 212,
        height: 212,
        decoration: const BoxDecoration(
          color: Color.fromRGBO(0x00, 0x85, 0xFF, 0.25),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              blurRadius: 26,
              color: Color.fromRGBO(0x00, 0x00, 0x00, 0.0225),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Builder(
            builder: (context) {
              const max = Duration(seconds: 30);
              final secondsRemaining =
                  ((max - duration).inMilliseconds / 1000).ceil().clamp(0, 30);
              final ratioRecorded =
                  (duration.inMilliseconds / max.inMilliseconds)
                      .clamp(0.0, 1.0);
              return Stack(
                fit: StackFit.expand,
                children: [
                  CustomPaint(
                    painter: _RecordingDurationArcPainter(
                      ratio: ratioRecorded,
                    ),
                  ),
                  Center(
                    child: Text(
                      secondsRemaining.toString(),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _RecordingDurationArcPainter extends CustomPainter {
  final double ratio;

  _RecordingDurationArcPainter({
    required this.ratio,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).inflate(7);
    canvas.drawArc(
      rect,
      -pi / 2,
      // At least draw a dot, even on a ratio of 0
      max(ratio, 0.001) * 2 * pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16
        ..strokeCap = StrokeCap.round
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.fromRGBO(0x68, 0xB7, 0xFF, 1.0),
            Color.fromRGBO(0x16, 0x8F, 0xFF, 1.0),
          ],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _RecordingDurationArcPainter oldDelegate) =>
      oldDelegate.ratio != ratio;
}

class RecordingDurationNotifier extends ValueNotifier<Duration> {
  RecordingDurationNotifier(super.value);

  void update(Duration duration) => value = duration;
}

class RecordPanelDeciding extends StatelessWidget {
  final Uint8List audio;
  final VoidCallback onRestart;

  const RecordPanelDeciding({
    super.key,
    required this.audio,
    required this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    return Button(
      onPressed: onRestart,
      child: Container(
        width: 212,
        height: 212,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: Color.fromRGBO(0x00, 0x85, 0xFF, 0.25),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              blurRadius: 26,
              color: Color.fromRGBO(0x00, 0x00, 0x00, 0.0225),
            ),
          ],
        ),
        child: const Padding(
          padding: EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.loop,
                color: Colors.white,
              ),
              SizedBox(height: 12),
              Text(
                'retry',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
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
  final _recorder = RecorderWithoutWaveforms();

  Timer? _recordingLimitTimer;

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
    _recordingLimitTimer?.cancel();
    _combinedController.close();
    _playbackController.dispose();
    _recorder.dispose();
  }

  Future<void> startRecording({
    Duration? maxDuration,
    required void Function(Uint8List? bytes) onComplete,
  }) async {
    maxDuration ??= const Duration(seconds: 30);
    await _recorder.startRecording(
      onFrequencies: (frequencies) {
        final value = _combinedController.value;
        final recordingInfo = value.item1.copyWith(frequencies: frequencies);
        _combinedController.add(Tuple2(recordingInfo, value.item2));
      },
      onComplete: onComplete,
    );
    final value = _combinedController.value;
    final recordingInfo = value.item1.copyWith(
      recording: true,
      start: DateTime.now(),
    );
    if (!_combinedController.isClosed) {
      _combinedController.add(Tuple2(recordingInfo, value.item2));
      _recordingLimitTimer = Timer(
        maxDuration,
        () => _recorder.stopRecording(),
      );
    }
  }

  void stopRecording() async {
    _recordingLimitTimer?.cancel();
    await _recorder.stopRecording();

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
  final DateTime start;
  final Float64x2List frequencies;

  const RecordingInfo(
    this.recording,
    this.start,
    this.frequencies,
  );

  RecordingInfo.none()
      : recording = false,
        start = DateTime.now(),
        frequencies = Float64x2List(0);

  RecordingInfo copyWith({
    bool? recording,
    DateTime? start,
    Float64x2List? frequencies,
  }) {
    return RecordingInfo(
      recording ?? this.recording,
      start ?? this.start,
      frequencies ?? this.frequencies,
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

class PermissionButton extends StatelessWidget {
  final Widget icon;
  final Text label;
  final bool granted;
  final VoidCallback onPressed;

  const PermissionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.granted,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Button(
      onPressed: onPressed,
      child: RoundedRectangleContainer(
        color: granted ? const Color.fromRGBO(0x06, 0xD9, 0x1B, 0.8) : null,
        child: SizedBox(
          width: 238,
          height: 42,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconTheme(
                  data: IconTheme.of(context)
                      .copyWith(color: granted ? Colors.white : Colors.black),
                  child: icon,
                ),
                const SizedBox(width: 13),
                DefaultTextStyle(
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    color: granted ? Colors.white : Colors.black,
                  ),
                  child: label,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RoundedRectangleContainer extends StatelessWidget {
  final Color color;
  final Widget child;

  const RoundedRectangleContainer({
    super.key,
    Color? color,
    required this.child,
  }) : color = color ?? Colors.white;

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: const TextStyle(color: Colors.black),
      child: Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.all(
            Radius.circular(8),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0x00, 0x00, 0x00, 0.1),
              offset: Offset(0, 0),
              blurRadius: 26,
            ),
          ],
        ),
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

class OnlineIndicatorBuilder extends ConsumerStatefulWidget {
  final String uid;
  final Widget Function(BuildContext context, bool online) builder;

  const OnlineIndicatorBuilder({
    super.key,
    required this.uid,
    required this.builder,
  });

  @override
  ConsumerState<OnlineIndicatorBuilder> createState() =>
      OnlineIndicatorBuilderState();
}

class OnlineIndicatorBuilderState
    extends ConsumerState<OnlineIndicatorBuilder> {
  // Cached to use during dispose()
  late final _cachedNotifier = ref.read(onlineUsersProvider.notifier);

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

  void _subscribe(String uid) => _cachedNotifier.subscribe(uid);

  void _unsubscribe(String uid) => _cachedNotifier.unsubscribe(uid);

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
      width: 16,
      height: 16,
      alignment: Alignment.center,
      child: OverflowBox(
        minWidth: 77,
        minHeight: 77,
        maxWidth: 77,
        maxHeight: 77,
        child: Lottie.asset(
          'assets/images/online.json',
        ),
      ),
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
    final myUid = ref.watch(userProvider2.select((p) {
      return p.map(
        guest: (_) => null,
        signedIn: (signedIn) => signedIn.account.profile.uid,
      );
    }));
    return Button(
      onPressed: myUid == null ? null : () => _onPressed(myUid),
      child: widget.builder(context),
    );
  }

  void _onPressed(String myUid) {
    showCupertinoModalPopup(
      context: context,
      barrierColor: const Color.fromRGBO(0x00, 0x00, 0x00, 0.5),
      builder: (context) {
        return CupertinoActionSheet(
          cancelButton: CupertinoActionSheetAction(
            onPressed: () async {
              final block = await _showBlockDialog(
                context: context,
                myUid: myUid,
              );

              if (block == _BlockResult.block && mounted) {
                final blockFuture = ref.read(apiProvider).blockUser(widget.uid);
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
            },
            child: const Text('Block User'),
          ),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () async {
                final reportReason = await _showReportReasonModal(
                  context: context,
                  myUid: myUid,
                );
                if (reportReason == null || !mounted) {
                  return;
                }

                // Send report
                final api = ref.read(apiProvider);
                final reportFuture = api.reportUser(
                  uid: myUid,
                  reportedUid: widget.uid,
                  reason: reportReason.name,
                );
                await withBlockingModal(
                  context: context,
                  label: 'Reporting...',
                  future: reportFuture,
                );

                if (!mounted) {
                  return;
                }

                final block = await _showReportSubmittedModal(
                  context: context,
                );
                if (block == _BlockResult.block && mounted) {
                  final api = ref.read(apiProvider);
                  final blockFuture = api.blockUser(widget.uid);
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
              },
              child: const Text('Report User'),
            ),
          ],
        );
      },
    );
  }

  Future<_BlockResult> _showBlockDialog({
    required BuildContext context,
    required String myUid,
  }) async {
    final result = await showCupertinoDialog<bool>(
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
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w300,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'They won\'t see you anywhere on this app, and won\'t be able to send you messages.\n\nYou won\'t see them anywhere, and won\'t be able to send them messages.',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w300,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Button(
                        onPressed: () {
                          Navigator.of(context).pop(true);
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            'Block',
                            style: TextStyle(
                                color: Color.fromRGBO(0xFF, 0x07, 0x07, 1.0),
                                fontSize: 20,
                                fontWeight: FontWeight.w300),
                          ),
                        ),
                      ),
                      Button(
                        onPressed: Navigator.of(context).pop,
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w300,
                              color: Colors.white,
                            ),
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

    if (result != null && result == true) {
      return _BlockResult.block;
    }
    return _BlockResult.noBlock;
  }

  Future<_ReportReason?> _showReportReasonModal({
    required BuildContext context,
    required String myUid,
  }) async {
    final reportReason = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
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
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.w300,
                      height: 1.5,
                      color: Colors.white),
                ),
                const SizedBox(height: 8),
                RadioTile(
                  label: 'Spam, impersonation or deception',
                  onTap: () => Navigator.of(context).pop("deceptive"),
                  style: const TextStyle(color: Colors.white),
                ),
                RadioTile(
                  label: 'Nudity or sexual activity',
                  onTap: () => Navigator.of(context).pop("sexual"),
                  style: const TextStyle(color: Colors.white),
                ),
                RadioTile(
                  label: 'Suicide or self-harm',
                  onTap: () => Navigator.of(context).pop("self-harm"),
                  style: const TextStyle(color: Colors.white),
                ),
                RadioTile(
                  label: 'Violence or harmful content',
                  onTap: () => Navigator.of(context).pop("harmful"),
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (reportReason != null && mounted) {
      final index =
          _ReportReason.values.indexWhere((r) => r.name == reportReason);
      if (index == -1) {
        return null;
      }
      return _ReportReason.values[index];
    }
    return null;
  }

  Future<_BlockResult> _showReportSubmittedModal({
    required BuildContext context,
  }) async {
    final result = await showCupertinoDialog<bool>(
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
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium!
                          .copyWith(fontSize: 24, fontWeight: FontWeight.w300),
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

    if (result != null && result == true) {
      return _BlockResult.block;
    }
    return _BlockResult.noBlock;
  }
}

Future<void> showSignInModal(BuildContext context) {
  return showCupertinoModalPopup<void>(
    context: context,
    builder: (context) {
      return CupertinoActionSheet(
        title: const Text('Sign up or log in for free to fully access Bonjour'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              context.pushNamed('signup');
            },
            child: const Text('Sign up or log in'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: Navigator.of(context).pop,
          child: const Text('Cancel'),
        ),
      );
    },
  );
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

class UnreadIndicator extends StatelessWidget {
  final int count;

  const UnreadIndicator({
    super.key,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: count > 0,
      maintainSize: true,
      maintainAnimation: true,
      maintainState: true,
      child: Container(
        width: 23,
        height: 23,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color.fromRGBO(0xFF, 0x00, 0x00, 1.0),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color.fromRGBO(0xF6, 0x28, 0x28, 1.0),
              Color.fromRGBO(0xFF, 0x5F, 0x5F, 1.0),
            ],
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          '${count.clamp(1, 9).toString()}${count > 9 ? '+' : ''}',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              fontSize: 14, fontWeight: FontWeight.w400, color: Colors.white),
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
    this.size = 10,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    // Using Repaintboundary due to this issue and comment: https://github.com/flutter/flutter/issues/120874#issuecomment-1499302781
    return RepaintBoundary(
      child: CupertinoActivityIndicator(
        color: color,
        radius: size,
      ),
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
  return '${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}:${((d.inMilliseconds % 1000) ~/ 10).toString().padLeft(2, '0')}';
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

// Just the date ex. 5:06 PM, regardless of the day
String formatTime(DateTime d) {
  final format = DateFormat.jm();
  return format.format(d);
}

// A long date and timestamp Mar 21, 2023 at 12:00 PM
String formatLongDateAndTime(DateTime d) {
  final dayOfWeekFormat = DateFormat.E();
  final dateFormat = DateFormat.MMMd();
  final timeFormat = DateFormat.jm();
  return '${dayOfWeekFormat.format(d)}, ${dateFormat.format(d)} at ${timeFormat.format(d)}';
}

enum _BlockResult { block, noBlock }

enum _ReportReason { deceptive, sexual, selfHarm, harmful }
