import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AudioPlaybackSymbol extends StatefulWidget {
  final bool play;
  final double size;
  const AudioPlaybackSymbol({
    super.key,
    required this.play,
    this.size = 20.0,
  });

  @override
  State<AudioPlaybackSymbol> createState() => _AudioPlaybackSymbolState();
}

class _AudioPlaybackSymbolState extends State<AudioPlaybackSymbol>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(covariant AudioPlaybackSymbol oldWidget) {
    if (oldWidget.play && !widget.play) {
      _controller.stop();
    } else if (!oldWidget.play && widget.play) {
      _controller.forward(from: 0);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const scale = 1.15;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Icon(
        Icons.volume_up,
        color: const Color.fromRGBO(0x1E, 0x77, 0xF8, 1.0),
        size: widget.size,
      ),
    )
        .animate(
          controller: _controller,
          autoPlay: false,
          onComplete: (c) => c.repeat(),
        )
        .scale(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutQuart,
          begin: const Offset(1.0, 1.0),
          end: const Offset(scale, scale),
        )
        .then()
        .scale(
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOutQuart,
          begin: const Offset(scale, scale),
          end: const Offset(1.0, 1.0),
        )
        .then(delay: const Duration(milliseconds: 600))
        .scale(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutQuart,
          begin: const Offset(1.0, 1.0),
          end: const Offset(scale, scale),
        )
        .then()
        .scale(
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOutQuart,
          begin: const Offset(scale, scale),
          end: const Offset(1.0, 1.0),
        );
  }
}
