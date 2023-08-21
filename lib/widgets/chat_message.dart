import 'package:flutter/material.dart';
import 'package:openup/api/chat_api.dart';
import 'package:openup/platform/just_audio_audio_player.dart';
import 'package:openup/widgets/audio_playback_symbol.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';

class AudioChatMessage extends StatelessWidget {
  final ChatMessage message;
  final bool fromMe;
  final String photo;
  final PlaybackInfo playbackInfo;
  final double height;
  final VoidCallback onPressed;

  const AudioChatMessage({
    super.key,
    required this.message,
    required this.fromMe,
    required this.photo,
    required this.playbackInfo,
    required this.height,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isPlaying = playbackInfo.state == PlaybackState.playing;
    final isLoading = playbackInfo.state == PlaybackState.loading;
    final isLoadingOrPlaying = isLoading || isPlaying;
    const verticalMargin = 4.0;
    return Button(
      onPressed: onPressed,
      child: Container(
        height: height - verticalMargin * 2,
        margin: const EdgeInsets.symmetric(vertical: verticalMargin),
        child: Stack(
          fit: StackFit.expand,
          alignment: Alignment.center,
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutQuart,
              height: 60,
              left: fromMe ? (isLoadingOrPlaying ? 24 : 100) : 24,
              right: fromMe ? 24 : (isLoadingOrPlaying ? 24 : 100),
              child: Row(
                children: [
                  if (fromMe)
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutQuart,
                      opacity: isLoadingOrPlaying ? 1.0 : 0.0,
                      child: AudioPlaybackSymbol(
                        play: isPlaying,
                      ),
                    ),
                  Expanded(
                    child: Stack(
                      children: [
                        Align(
                          alignment: fromMe
                              ? Alignment.bottomRight
                              : Alignment.bottomLeft,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  formatDuration(
                                    isLoadingOrPlaying
                                        ? playbackInfo.position
                                        : message.content.duration,
                                    canBeZero: true,
                                  ),
                                  textAlign:
                                      fromMe ? TextAlign.right : TextAlign.left,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                    color:
                                        Color.fromRGBO(0x9D, 0x9D, 0x9D, 1.0),
                                  ),
                                ),
                              ),
                              if (fromMe && message.messageId != null)
                                const Padding(
                                  padding: EdgeInsets.only(left: 2.0),
                                  child: Icon(
                                    Icons.done,
                                    size: 12,
                                    color:
                                        Color.fromRGBO(0x9D, 0x9D, 0x9D, 1.0),
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
                              color: isLoadingOrPlaying
                                  ? Colors.white
                                  : (fromMe
                                      ? const Color.fromRGBO(
                                          0x13, 0x77, 0xFF, 1.0)
                                      : const Color.fromRGBO(
                                          0xE9, 0xE9, 0xEB, 1.0)),
                              border: isLoadingOrPlaying
                                  ? Border.all(
                                      color: const Color.fromRGBO(
                                          0xC4, 0xC4, 0xC4, 1.0))
                                  : null,
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(12)),
                            ),
                            child: FractionallySizedBox(
                              widthFactor:
                                  playbackInfo.duration.inMilliseconds == 0
                                      ? 0
                                      : playbackInfo.position.inMilliseconds /
                                          playbackInfo.duration.inMilliseconds,
                              heightFactor: 1.0,
                              alignment: Alignment.centerLeft,
                              child: const ColoredBox(
                                color: Color.fromRGBO(0x13, 0x77, 0xFF, 1.0),
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
                      child: AudioPlaybackSymbol(
                        play: isPlaying,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
