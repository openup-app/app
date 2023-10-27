import 'package:flutter/widgets.dart';
import 'package:video_player/video_player.dart';

class PartyForceField extends StatefulWidget {
  const PartyForceField({super.key});

  @override
  State<PartyForceField> createState() => _PartyForceFieldState();
}

class _PartyForceFieldState extends State<PartyForceField> {
  late final VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _init();
  }

  void _init() async {
    _controller = VideoPlayerController.asset(
      'assets/videos/after_party_waitlist_background.mp4',
    );
    await _controller.initialize();
    if (mounted) {
      _controller.play();
      _controller.setLooping(true);
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VideoPlayer(_controller);
  }
}
