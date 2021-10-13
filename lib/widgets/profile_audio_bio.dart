import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:openup/platform/just_audio_audio_player.dart';
import 'package:openup/platform/record_audio_recorder.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/theming.dart';

class ProfileAudioBio extends StatefulWidget {
  final String uri;
  final void Function(Uint8List newBio) onRecorded;

  const ProfileAudioBio({
    Key? key,
    required this.uri,
    required this.onRecorded,
  }) : super(key: key);

  @override
  _ProfileAudioBioState createState() => _ProfileAudioBioState();
}

class _ProfileAudioBioState extends State<ProfileAudioBio> {
  final _audio = JustAudioAudioPlayer();
  final _recorder = RecordAudioRecorder();

  PlaybackInfo _playbackInfo = const PlaybackInfo();
  bool _needsToLoadAudio = true;
  bool _recording = false;

  @override
  void initState() {
    super.initState();
    _audio.playbackInfoStream.listen((info) {
      if (_playbackInfo != info) {
        setState(() => _playbackInfo = info);
      }
    });
  }

  @override
  void dispose() {
    _audio.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ProfileAudioBio oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uri != widget.uri) {
      setState(() => _needsToLoadAudio = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: _ProfileAudioBioDisplay(
        playButton: _playbackInfo.state == PlaybackState.loading
            ? PlayButtonState.loading
            : (_playbackInfo.state == PlaybackState.playing
                ? PlayButtonState.playing
                : PlayButtonState.paused),
        recording: _recording,
        progress: _playbackInfo.position.inMilliseconds /
            (_playbackInfo.duration.inMilliseconds == 0
                ? 1
                : _playbackInfo.duration.inMilliseconds),
        onPlay: () {
          if (_needsToLoadAudio) {
            _audio.play(uri: widget.uri);
            setState(() => _needsToLoadAudio = false);
          } else {
            _audio.play();
          }
        },
        onPause: () => _audio.pause(),
        onRecord: () async {
          setState(() => _recording = true);
          await _recorder.start();
        },
        onRecordComplete: () async {
          final output = await _recorder.stop();
          setState(() => _recording = false);
          if (output != null) {
            widget.onRecorded(output);
          }
        },
      ),
    );
  }
}

class _ProfileAudioBioDisplay extends StatelessWidget {
  final PlayButtonState playButton;
  final bool recording;
  final double progress;
  final VoidCallback onPlay;
  final VoidCallback onPause;
  final VoidCallback onRecord;
  final VoidCallback onRecordComplete;

  const _ProfileAudioBioDisplay({
    Key? key,
    required this.playButton,
    required this.recording,
    required this.progress,
    required this.onPlay,
    required this.onPause,
    required this.onRecord,
    required this.onRecordComplete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Theming.of(context).shadow,
            blurRadius: 4,
            offset: const Offset(0.0, 2.0),
          ),
        ],
        gradient: LinearGradient(
          colors: [
            Colors.red.withOpacity(0.6),
            Colors.white.withOpacity(0.6),
          ],
          stops: [progress, progress],
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 24),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'John, 28',
                style: Theming.of(context).text.headline.copyWith(
                  fontSize: 28,
                  shadows: [
                    Shadow(
                      color: Theming.of(context).shadow,
                      blurRadius: 4,
                      offset: const Offset(0.0, 2.0),
                    ),
                  ],
                ),
              ),
              Text(
                'Three Words Only',
                style: Theming.of(context).text.bodySecondary.copyWith(
                  fontSize: 20,
                  shadows: [
                    Shadow(
                      color: Theming.of(context).shadow,
                      blurRadius: 4,
                      offset: const Offset(0.0, 2.0),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          Button(
            onPressed: playButton == PlayButtonState.playing
                ? null
                : (recording ? onRecordComplete : onRecord),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color.fromARGB(0xFF, 0xFF, 0x00, 0x00),
                shape: recording ? BoxShape.rectangle : BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Theming.of(context).shadow,
                    blurRadius: 4,
                    offset: const Offset(0.0, 2.0),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 28),
          IgnorePointer(
            ignoring: recording,
            child: Button(
              onPressed: (recording || playButton == PlayButtonState.loading)
                  ? null
                  : (playButton == PlayButtonState.playing ? onPause : onPlay),
              child: SizedBox(
                width: 48,
                height: 48,
                child: playButton == PlayButtonState.loading
                    ? const CircularProgressIndicator()
                    : (playButton == PlayButtonState.playing
                        ? Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: SvgPicture.asset(
                                'assets/images/pause_icon.svg'),
                          )
                        : Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child:
                                SvgPicture.asset('assets/images/play_icon.svg'),
                          )),
              ),
            ),
          ),
          const SizedBox(width: 20),
        ],
      ),
    );
  }
}

enum PlayButtonState { playing, paused, loading }
