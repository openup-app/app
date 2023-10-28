import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openup/api/api.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/gradient_mask.dart';
import 'package:openup/widgets/party_force_field.dart';
import 'package:openup/widgets/photo_card.dart';
import 'package:openup/widgets/profile_display.dart';
import 'package:openup/widgets/restart_app.dart';

class SignupGlamourPreview extends ConsumerWidget {
  final Profile profile;

  const SignupGlamourPreview({
    super.key,
    required this.profile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            const Center(
              child: GradientMask(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white,
                    Color.fromRGBO(0x56, 0x56, 0x56, 1.0),
                  ],
                ),
                child: Text(
                  'Here is your Profile',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ).animate().fadeOut(delay: const Duration(seconds: 2)),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 89, bottom: 140),
                child: ProfileBuilder(
                  profile: profile,
                  autoPlay: false,
                  builder: (context, video, controller) {
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        return PhotoCardWiggle(
                          child: PhotoCard(
                            width: constraints.maxWidth,
                            height: constraints.maxHeight,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  offset: Offset(0, 4),
                                  color: Color.fromRGBO(0x25, 0x97, 0xFF, 0.75),
                                  blurRadius: 85,
                                ),
                              ],
                            ),
                            photo: Stack(
                              fit: StackFit.expand,
                              children: [
                                const PartyForceField()
                                    .animate()
                                    .fadeOut(delay: const Duration(seconds: 6)),
                                Button(
                                  onPressed: controller.togglePlayPause,
                                  child: video.animate().custom(
                                        delay: const Duration(seconds: 6),
                                        builder: (context, value, child) {
                                          if (value != 0) {
                                            controller.play();
                                          }
                                          return Opacity(
                                            opacity: value,
                                            child: child,
                                          );
                                        },
                                      ),
                                ),
                              ],
                            ),
                            titleBuilder: (context) {
                              return Text(profile.name)
                                  .animate()
                                  .fadeIn(delay: const Duration(seconds: 4));
                            },
                            indicatorButton: AudioPlaybackIndicator(
                              onTogglePlayPause: controller.togglePlayPause,
                              audioStateStream: controller.audioPlaybackStream
                                  .map((event) => event.state),
                            ).animate().custom(
                                  delay: const Duration(seconds: 5),
                                  builder: (context, value, child) {
                                    if (value != 0) {
                                      controller.playAudioOnly();
                                    }
                                    return Opacity(
                                      opacity: value,
                                      child: child,
                                    );
                                  },
                                ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ).animate().fadeIn(delay: const Duration(milliseconds: 2500)),
            Positioned(
              left: 0,
              right: 0,
              bottom: 62,
              child: Button(
                onPressed: () => RestartApp.restartApp(context),
                child: Container(
                  height: 42,
                  margin: const EdgeInsets.symmetric(horizontal: 58),
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(
                      Radius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'See everyone else',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ).animate().fadeIn(delay: const Duration(seconds: 9)),
          ],
        ),
      ),
    );
  }
}

class SignupGlamourPreviewArgs {
  final Profile profile;
  SignupGlamourPreviewArgs(this.profile);
}
