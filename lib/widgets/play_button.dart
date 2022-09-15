import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:openup/platform/just_audio_audio_player.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';

class PlayButton extends StatefulWidget {
  final String? path;
  final String? url;
  final Widget Function(BuildContext context, PlaybackState state)? builder;

  const PlayButton({
    Key? key,
    this.path,
    this.url,
    this.builder,
  })  : assert(!(path == null && url == null) && (path != url)),
        super(key: key);

  @override
  State<PlayButton> createState() => _PlayButtonState();
}

class _PlayButtonState extends State<PlayButton> {
  final _audioPlayer = JustAudioAudioPlayer();
  PlaybackState _state = PlaybackState.disabled;
  late final StreamSubscription _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = _audioPlayer.playbackInfoStream.listen((info) {
      setState(() => _state = info.state);
    });
    _setAudio(null, null);
  }

  @override
  void didUpdateWidget(covariant PlayButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    _setAudio(oldWidget.url, oldWidget.path);
  }

  void _setAudio(String? oldUrl, String? oldPath) {
    if (widget.url != oldUrl || widget.path != oldPath) {
      if (widget.url != null) {
        _audioPlayer.setUrl(widget.url!);
      } else {
        _audioPlayer.setPath(widget.path!);
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
    _subscription.cancel();
    _audioPlayer.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Button(
      onPressed: () {
        if (_state == PlaybackState.idle || _state == PlaybackState.paused) {
          _audioPlayer.play();
        } else {
          _audioPlayer.stop();
        }
      },
      child:
          widget.builder?.call(context, _state) ?? PlayStopArrow(state: _state),
    );
  }
}

class PlayStopArrow extends StatelessWidget {
  final PlaybackState state;
  final Color? color;
  final double? size;
  const PlayStopArrow({
    Key? key,
    required this.state,
    this.color,
    this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case PlaybackState.loading:
        return const Padding(
          padding: EdgeInsets.all(8.0),
          child: LoadingIndicator(),
        );
      case PlaybackState.playing:
        return Icon(
          Icons.stop,
          size: size == null ? 57 : size! * 1.5,
          color: color,
        );
      case PlaybackState.idle:
      case PlaybackState.paused:
      case PlaybackState.disabled:
        return Padding(
          padding: const EdgeInsets.only(top: 8.0, left: 8.0),
          child: SvgPicture.asset(
            'assets/images/play_icon.svg',
            color: color,
            width: size,
            height: size,
          ),
        );
    }
  }
}
