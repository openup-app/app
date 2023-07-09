import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:openup/api/chat_api.dart';
import 'package:openup/platform/just_audio_audio_player.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';

class AudioChatMessage extends StatelessWidget {
  final ChatMessage message;
  final bool fromMe;
  final String photo;
  final PlaybackInfo playbackInfo;
  final VoidCallback onPressed;

  const AudioChatMessage({
    super.key,
    required this.message,
    required this.fromMe,
    required this.photo,
    required this.playbackInfo,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isPlaying = playbackInfo.state == PlaybackState.playing;
    final isLoading = playbackInfo.state == PlaybackState.loading;
    final isLoadingOrPlaying = isLoading || isPlaying;
    return Button(
      onPressed: onPressed,
      child: Container(
        height: 54,
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (!fromMe)
              Container(
                width: 54,
                height: 54,
                margin: const EdgeInsets.only(left: 36, right: 10),
                alignment: Alignment.center,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutQuart,
                  width: isLoadingOrPlaying ? 53 : 40,
                  height: isLoadingOrPlaying ? 53 : 40,
                  clipBehavior: Clip.hardEdge,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  child: Image.network(
                    photo,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                alignment: Alignment.center,
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutQuart,
                    width: isLoadingOrPlaying ? 234 : 182,
                    height: 54,
                    left: fromMe ? null : 0,
                    right: fromMe ? 0 : null,
                    child: Row(
                      children: [
                        if (fromMe)
                          AnimatedOpacity(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutQuart,
                            opacity: isLoadingOrPlaying ? 1.0 : 0.0,
                            child: _AudioPlayingSymbol(
                              play: isPlaying,
                            ),
                          ),
                        Expanded(
                          child: Stack(
                            children: [
                              Align(
                                alignment: Alignment.bottomLeft,
                                child: Text(
                                  formatDate(message.date),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                    color:
                                        Color.fromRGBO(0x9D, 0x9D, 0x9D, 1.0),
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.bottomRight,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        formatDuration(
                                          isLoadingOrPlaying
                                              ? playbackInfo.position
                                              : playbackInfo.duration,
                                          canBeZero: true,
                                        ),
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w400,
                                          color: Color.fromRGBO(
                                              0x9D, 0x9D, 0x9D, 1.0),
                                        ),
                                      ),
                                    ),
                                    if (fromMe && message.messageId != null)
                                      const Padding(
                                        padding: EdgeInsets.only(left: 2.0),
                                        child: Icon(
                                          Icons.done,
                                          size: 12,
                                          color: Color.fromRGBO(
                                              0x9D, 0x9D, 0x9D, 1.0),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Center(
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOut,
                                  width: double.infinity,
                                  clipBehavior: Clip.hardEdge,
                                  height: isLoadingOrPlaying ? 16 : 8,
                                  decoration: BoxDecoration(
                                    color: const Color.fromRGBO(
                                        0xC4, 0xC4, 0xC4, 1.0),
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(12)),
                                    boxShadow: isLoadingOrPlaying
                                        ? [
                                            const BoxShadow(
                                              offset: Offset(0, 2),
                                              blurRadius: 9,
                                              color: Color.fromRGBO(
                                                  0x00, 0x00, 0x00, 0.1),
                                            ),
                                          ]
                                        : [],
                                  ),
                                  child: FractionallySizedBox(
                                    widthFactor: playbackInfo
                                                .duration.inMilliseconds ==
                                            0
                                        ? 0
                                        : playbackInfo.position.inMilliseconds /
                                            playbackInfo
                                                .duration.inMilliseconds,
                                    heightFactor: 1.0,
                                    alignment: Alignment.centerLeft,
                                    child: const ColoredBox(
                                      color:
                                          Color.fromRGBO(0x1E, 0x77, 0xF8, 1.0),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!fromMe)
                          AnimatedOpacity(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutQuart,
                            opacity: isLoadingOrPlaying ? 1.0 : 0.0,
                            child: _AudioPlayingSymbol(
                              play: isPlaying,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (fromMe)
              Container(
                width: 53,
                height: 53,
                margin: const EdgeInsets.only(left: 10, right: 36),
                alignment: Alignment.center,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutQuart,
                  width: isLoadingOrPlaying ? 53 : 40,
                  height: isLoadingOrPlaying ? 53 : 40,
                  clipBehavior: Clip.hardEdge,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  child: Image.network(
                    photo,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AudioPlayingSymbol extends StatefulWidget {
  final bool play;
  const _AudioPlayingSymbol({
    super.key,
    required this.play,
  });

  @override
  State<_AudioPlayingSymbol> createState() => _AudioPlayingSymbolState();
}

class _AudioPlayingSymbolState extends State<_AudioPlayingSymbol>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
  );

  @override
  void didUpdateWidget(covariant _AudioPlayingSymbol oldWidget) {
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
    return const Padding(
      padding: EdgeInsets.all(8.0),
      child: Icon(
        Icons.volume_up,
        color: Color.fromRGBO(0x1E, 0x77, 0xF8, 1.0),
        size: 20,
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
