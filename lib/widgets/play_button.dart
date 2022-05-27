import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:openup/platform/just_audio_audio_player.dart';
import 'package:openup/widgets/button.dart';

class PlayButton extends StatefulWidget {
  final String? path;
  final String? url;
  final Widget Function(BuildContext context, PlaybackState state)? builder;

  const PlayButton({
    Key? key,
    this.path,
    this.url,
    this.builder,
  })  : assert(path != url && (path == null || url == null)),
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
    _setUrlOrPath(null, null);
  }

  @override
  void didUpdateWidget(covariant PlayButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    _setUrlOrPath(oldWidget.url, oldWidget.path);
  }

  void _setUrlOrPath(String? oldUrl, String? oldPath) {
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
      child: widget.builder?.call(context, _state) ?? PlayStopArrow(state: _state),
    );
  }
}

class PlayStopArrow extends StatelessWidget {
  final PlaybackState state;
  const PlayStopArrow({ Key? key, required this.state, }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: 48,
        height: 48,
        child: Builder(
          builder: (context) {
            switch (state) {
              case PlaybackState.loading:
                return const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                );
              case PlaybackState.playing:
                return const Icon(Icons.stop, size: 44);
              case PlaybackState.idle:
              case PlaybackState.paused:
              case PlaybackState.disabled:
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SvgPicture.asset(
                    'assets/images/play_icon.svg',
                  ),
                );
            }
          },
        ),
      );
  }
}
