import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:openup/platform/just_audio_audio_player.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';

class PhotoCard extends StatelessWidget {
  final double width;
  final double height;
  final Widget photo;
  final WidgetBuilder titleBuilder;
  final Widget subtitle;
  final Widget firstButton;
  final Widget secondButton;
  final PlaybackState? playbackState;
  final Stream<PlaybackInfo>? playbackInfoStream;
  final VoidCallback onPlaybackIndicatorPressed;

  const PhotoCard({
    super.key,
    required this.width,
    required this.height,
    required this.photo,
    required this.titleBuilder,
    required this.subtitle,
    required this.firstButton,
    required this.secondButton,
    required this.playbackState,
    required this.playbackInfoStream,
    required this.onPlaybackIndicatorPressed,
  });

  @override
  Widget build(BuildContext context) {
    const margin = 24.0;
    const topPadding = 20.0;
    const bottomHeight = 132.0;
    const leftPadding = 20.0;
    const rightPadding = 20.0;
    const requiredWidth = leftPadding + rightPadding;
    const requiredHeight = topPadding + bottomHeight;
    final availableWidth = width - requiredWidth - margin;
    final availableHeight = height - requiredHeight - margin;
    final availableAspect = availableWidth / availableHeight;
    const targetAspect = 14 / 23;

    final double outputWidth, outputHeight;
    if (availableAspect > targetAspect) {
      outputHeight = height;
      outputWidth = height * targetAspect;
    } else {
      outputWidth = width;
      outputHeight = width * targetAspect;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(margin),
        child: Container(
          width: outputWidth,
          height: outputHeight,
          color: Colors.white,
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: leftPadding,
                    top: topPadding,
                    right: rightPadding,
                  ),
                  child: SizedBox.expand(child: photo),
                ),
              ),
              SizedBox(
                height: bottomHeight,
                child: Column(
                  children: [
                    const SizedBox(height: 11),
                    Padding(
                      padding: const EdgeInsets.only(
                        left: leftPadding,
                        right: rightPadding,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              DefaultTextStyle(
                                style: const TextStyle(
                                  fontFamily: 'Covered By Your Grace',
                                  fontSize: 29,
                                  color: Color.fromRGBO(0x27, 0x27, 0x27, 1.0),
                                ),
                                child: Builder(
                                  builder: (context) {
                                    return titleBuilder(context);
                                  },
                                ),
                              ),
                              DefaultTextStyle(
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w300,
                                  color: Color.fromRGBO(0x27, 0x27, 0x27, 1.0),
                                ),
                                child: subtitle,
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                          const Spacer(),
                          Button(
                            onPressed: onPlaybackIndicatorPressed,
                            child: Container(
                              width: 36,
                              height: 36,
                              alignment: Alignment.center,
                              margin: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Colors.black,
                                shape: BoxShape.circle,
                              ),
                              child: Builder(
                                builder: (context) {
                                  return switch (playbackState) {
                                    null => const SizedBox.shrink(),
                                    PlaybackState.idle ||
                                    PlaybackState.paused =>
                                      const Icon(Icons.play_arrow),
                                    PlaybackState.playing => SvgPicture.asset(
                                        'assets/images/audio_indicator.svg',
                                        width: 16,
                                        height: 18,
                                      ),
                                    _ => const LoadingIndicator(),
                                  };
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Divider(
                      height: 1,
                      color: Color.fromRGBO(0xD2, 0xD2, 0xD2, 1.0),
                    ),
                    SizedBox(
                      height: 50,
                      child: DefaultTextStyle(
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: firstButton,
                            ),
                            const VerticalDivider(
                              width: 1,
                              color: Color.fromRGBO(0xD2, 0xD2, 0xD2, 1.0),
                            ),
                            Expanded(
                              child: secondButton,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
