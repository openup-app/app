import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/audio/audio.dart';
import 'package:openup/audio/audio_player.dart';
import 'package:openup/widgets/animation.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/gallery.dart';
import 'package:openup/widgets/photo_card.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

class ProfileBuilder extends StatefulWidget {
  final Profile profile;
  final void Function(ProfileController controller)? onController;
  final Widget Function(
    BuildContext context,
    ProfileController controller,
  ) builder;

  const ProfileBuilder({
    super.key,
    this.onController,
    required this.profile,
    required this.builder,
  });

  @override
  State<ProfileBuilder> createState() => ProfileBuilderState();
}

class ProfileBuilderState extends State<ProfileBuilder> {
  ProfileController? _controller;

  @override
  Widget build(BuildContext context) {
    return AudioBuilder(
      key: ValueKey(widget.profile.uid),
      uri: Uri.parse(widget.profile.audio),
      autoPlay: true,
      loop: true,
      onController: (controller) {
        final playerController = _constructController(controller);
        setState(() => _controller = playerController);
        widget.onController?.call(playerController);
      },
      builder: (context, child, controller) {
        return widget.builder(
            context, _controller ?? _constructController(controller));
      },
    );
  }

  ProfileController _constructController(AudioController controller) {
    return ProfileController(
      audioController: controller,
    );
  }
}

class PhotoCardProfile extends ConsumerStatefulWidget {
  final double width;
  final double height;
  final Profile profile;
  final int distance;
  final Stream<Playback>? playbackStream;
  final VoidCallback onPlay;
  final VoidCallback onPause;
  final VoidCallback onMessage;

  const PhotoCardProfile({
    super.key,
    required this.width,
    required this.height,
    required this.profile,
    required this.distance,
    required this.playbackStream,
    required this.onPlay,
    required this.onPause,
    required this.onMessage,
  });

  @override
  ConsumerState<PhotoCardProfile> createState() => _ProfileDisplayState();
}

class _ProfileDisplayState extends ConsumerState<PhotoCardProfile> {
  StreamSubscription? _isPlayingSubscription;
  bool _initialDidChangeDeps = true;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _listenForIsPlaying();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialDidChangeDeps) {
      _precache();
      _initialDidChangeDeps = false;
    }
  }

  @override
  void didUpdateWidget(covariant PhotoCardProfile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.playbackStream != widget.playbackStream) {
      _listenForIsPlaying();
    }
  }

  void _listenForIsPlaying() {
    _isPlayingSubscription?.cancel();
    _isPlayingSubscription = widget.playbackStream
        ?.map((e) => e.state.isPlayingOrLoading)
        .listen((e) => setState(() => _isPlaying = e));
  }

  void _precache() async {
    await Future.wait([
      for (final uri in widget.profile.gallery)
        precacheImage(NetworkImage(uri.toString()), context)
    ]);
  }

  @override
  Widget build(BuildContext context) {
    const optionsButton = Center(
      child: Text(
        'Options',
        textAlign: TextAlign.center,
      ),
    );
    return PhotoCard(
      width: widget.width,
      height: widget.height,
      useExtraTopPadding: true,
      photo: Button(
        onPressed: _togglePlayPause,
        child: CameraFlashGallery(
          slideshow: true,
          gallery: widget.profile.gallery.map((e) => Uri.parse(e)).toList(),
        ),
      ),
      titleBuilder: (context) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.profile.name.toUpperCase()),
            const SizedBox(width: 12),
            Text(widget.profile.age.toString()),
          ],
        );
      },
      subtitle: Text(
          '${widget.distance} ${widget.distance == 1 ? 'mile' : 'miles'} away'),
      firstButton: Button(
        onPressed: widget.onMessage,
        child: const Center(
          child: Text(
            'Message',
            textAlign: TextAlign.center,
          ),
        ),
      ),
      secondButton: ref.watch(uidProvider) == widget.profile.uid
          ? optionsButton
          : ReportBlockPopupMenu2(
              name: widget.profile.name,
              uid: widget.profile.uid,
              onBlock: () {},
              builder: (context) => optionsButton,
            ),
      indicatorButton: AudioPlaybackIndicator(
        onTogglePlayPause: _togglePlayPause,
        audioStateStream: widget.playbackStream?.map((e) => e.state),
      ),
    );
  }

  void _togglePlayPause() async {
    if (_isPlaying) {
      widget.onPause();
    } else {
      widget.onPlay();
    }
  }
}

class AudioPlaybackIndicator extends StatelessWidget {
  final VoidCallback onTogglePlayPause;
  final Stream<AudioState?>? audioStateStream;

  const AudioPlaybackIndicator({
    super.key,
    required this.onTogglePlayPause,
    required this.audioStateStream,
  });

  @override
  Widget build(BuildContext context) {
    return Button(
      onPressed: onTogglePlayPause,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: const BoxDecoration(
          color: Colors.black,
          shape: BoxShape.circle,
        ),
        child: StreamBuilder<AudioState?>(
          stream: audioStateStream,
          initialData: AudioState.none,
          builder: (context, snapshot) {
            final state = snapshot.requireData;
            return switch (state) {
              null || AudioState.none => const SizedBox.shrink(),
              AudioState.loading => const LoadingIndicator(),
              AudioState.stopped ||
              AudioState.paused =>
                const Icon(Icons.play_arrow),
              AudioState.playing => Image.asset(
                  'assets/images/audio_playback.gif',
                  width: 32,
                  height: 32,
                ),
            };
          },
        ),
      ),
    );
  }
}

/// Info icon with solid white background
class InfoIcon extends StatelessWidget {
  const InfoIcon({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 14,
          height: 14,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
        Icon(
          Icons.info,
          color: Color.fromRGBO(0x00, 0x85, 0xFF, 1.0),
          size: 16,
        ),
      ],
    );
  }
}

class ProfileButton extends StatelessWidget {
  final Widget icon;
  final Widget? label;
  final double size;
  final VoidCallback onPressed;

  const ProfileButton({
    super.key,
    required this.icon,
    this.label,
    this.size = 35,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Button(
      onPressed: onPressed,
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: _ProfileButtonContents(
          icon: icon,
          label: label,
          size: size,
        ),
      ),
    );
  }
}

class _ProfileButtonContents extends StatelessWidget {
  final Widget icon;
  final Widget? label;
  final double size;

  const _ProfileButtonContents({
    super.key,
    required this.icon,
    this.label,
    this.size = 35,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: label == null ? size : null,
      height: size,
      alignment: Alignment.center,
      padding: label == null
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            offset: Offset(0, 2),
            blurRadius: 4,
            color: Color.fromRGBO(0x00, 0x00, 0x00, 0.25),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          if (label != null) ...[
            const SizedBox(width: 8),
            DefaultTextStyle.merge(
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              child: label!,
            ),
          ],
        ],
      ),
    );
  }
}

class PhotoCardWiggle extends StatelessWidget {
  final Key childKey;
  final Widget child;

  const PhotoCardWiggle({
    super.key,
    this.childKey = const ValueKey('photo'),
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return WiggleBuilder(
      key: childKey,
      seed: childKey.hashCode,
      builder: (context, child, wiggle) {
        final offset = Offset(
          wiggle(frequency: 0.3, amplitude: 30),
          wiggle(frequency: 0.3, amplitude: 30),
        );

        final rotationZ = wiggle(frequency: 0.5, amplitude: radians(8));
        final rotationY = wiggle(frequency: 0.5, amplitude: radians(20));
        const perspectiveDivide = 0.002;
        final transform = Matrix4.identity()
          ..setEntry(3, 2, perspectiveDivide)
          ..rotateY(rotationY)
          ..rotateZ(rotationZ);
        return Transform.translate(
          offset: offset,
          child: Transform(
            transform: transform,
            alignment: Alignment.center,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _RecordButton extends StatelessWidget {
  final Widget label;
  final VoidCallback? onPressed;

  const _RecordButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Button(
      onPressed: onPressed,
      child: Container(
        height: 51,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: Color.fromRGBO(0x00, 0x85, 0xFF, 1.0),
          borderRadius: BorderRadius.all(Radius.circular(11)),
          boxShadow: [
            BoxShadow(
              offset: Offset(0, 2),
              blurRadius: 17,
              color: Color.fromRGBO(0x00, 0x00, 0x00, 0.25),
            ),
          ],
        ),
        child: DefaultTextStyle.merge(
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Colors.white,
          ),
          child: label,
        ),
      ),
    );
  }
}

class ProfileController {
  final AudioController _audioController;

  ProfileController({required AudioController audioController})
      : _audioController = audioController;

  Stream<Playback> get audioPlaybackStream => _audioController.playbackStream;

  void togglePlayPause() => _audioController.togglePlayPause();

  void play() => _audioController.play();

  void pause() => _audioController.pause();
}
