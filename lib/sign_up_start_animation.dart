import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class SignUpStartAnimationScreen extends StatefulWidget {
  const SignUpStartAnimationScreen({Key? key}) : super(key: key);

  @override
  State<SignUpStartAnimationScreen> createState() =>
      _SignUpStartAnimationScreenState();
}

class _SignUpStartAnimationScreenState
    extends State<SignUpStartAnimationScreen> {
  late final VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(
      'assets/videos/welcome.mp4',
    );

    final futures = [
      _controller.initialize(),
    ];
    Future.wait(futures).then((_) {
      if (mounted) {
        _controller.play();
        setState(() {});
      }
    }).onError((error, stackTrace) {
      debugPrint(error.toString());
      debugPrint(stackTrace.toString());
      _goHome();
    });

    _controller.addListener(
      () {
        if (_controller.value.position == _controller.value.duration) {
          _goHome();
        }
      },
    );
  }

  void _goHome() {
    Navigator.of(context).pushReplacementNamed('home');
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return const DecoratedBox(
        decoration: BoxDecoration(color: Colors.black),
      );
    }
    return DecoratedBox(
      decoration: const BoxDecoration(color: Colors.black),
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _controller.value.size.width,
            height: _controller.value.size.height,
            child: VideoPlayer(_controller),
          ),
        ),
      ),
    );
  }
}
