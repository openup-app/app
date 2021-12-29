import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:openup/api/users/profile.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/slide_control.dart';
import 'package:openup/widgets/theming.dart';
import 'package:openup/widgets/time_remaining.dart';

/// Voice call display and controls.
class VoiceCallScreenContent extends StatelessWidget {
  final List<PublicProfile> profiles;
  final bool hasSentTimeRequest;
  final DateTime endTime;
  final bool muted;
  final bool speakerphone;
  final VoidCallback onTimeUp;
  final VoidCallback onHangUp;
  final VoidCallback onSendTimeRequest;
  final VoidCallback onToggleMute;
  final VoidCallback onToggleSpeakerphone;

  const VoiceCallScreenContent({
    Key? key,
    required this.profiles,
    required this.hasSentTimeRequest,
    required this.endTime,
    required this.muted,
    required this.speakerphone,
    required this.onTimeUp,
    required this.onHangUp,
    required this.onSendTimeRequest,
    required this.onToggleMute,
    required this.onToggleSpeakerphone,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final profile = profiles.first;
    final photo = profile.photo;
    return Stack(
      alignment: Alignment.center,
      fit: StackFit.expand,
      children: [
        ImageFiltered(
          imageFilter: ImageFilter.blur(
            sigmaX: 8.0,
            sigmaY: 8.0,
          ),
          child: photo != null
              ? Image.network(
                  photo,
                  fit: BoxFit.cover,
                )
              : Image.asset(
                  'assets/images/profile.png',
                  fit: BoxFit.fitHeight,
                ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(0xAA, 0x02, 0x4A, 0x5A),
                Color.fromARGB(0xAA, 0x9C, 0xED, 0xFF),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 40),
              SafeArea(
                top: true,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(
                      Radius.circular(48),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theming.of(context).shadow,
                        offset: const Offset(0.0, 4.0),
                        blurRadius: 2,
                      ),
                    ],
                    color: const Color.fromARGB(0xAA, 0x01, 0x55, 0x67),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              _ButtonWithText(
                                icon: const Icon(Icons.alarm_add),
                                label: 'add time',
                                onPressed: hasSentTimeRequest
                                    ? null
                                    : onSendTimeRequest,
                              ),
                              const SizedBox(width: 30),
                            ],
                          ),
                          Text(
                            profile.name,
                            style: Theming.of(context).text.headline,
                          ),
                          TimeRemaining(
                            endTime: endTime,
                            onTimeUp: onTimeUp,
                            builder: (context, remaining) {
                              return Text(
                                remaining,
                                style: Theming.of(context).text.body,
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _ButtonWithText(
                            icon: const Icon(Icons.person_add),
                            label: 'Connect',
                            onPressed: () {},
                          ),
                          _ButtonWithText(
                            icon: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Image.asset('assets/images/report.png'),
                            ),
                            label: 'Report',
                            onPressed: () {},
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _ButtonWithText(
                            icon: muted
                                ? const Icon(Icons.mic_off)
                                : const Icon(Icons.mic),
                            label: 'Mute',
                            onPressed: onToggleMute,
                          ),
                          _ButtonWithText(
                            icon: Icon(
                              Icons.volume_up,
                              color: speakerphone
                                  ? const Color.fromARGB(0xFF, 0x00, 0xFF, 0x19)
                                  : null,
                            ),
                            label: 'Speaker',
                            onPressed: onToggleSpeakerphone,
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              SlideControl(
                thumbContents: Icon(
                  Icons.call_end,
                  color: Theming.of(context).friendBlue4,
                  size: 40,
                ),
                trackContents: const Text('slide to end call'),
                trackColor: const Color.fromARGB(0xFF, 0x01, 0x55, 0x67),
                onSlideComplete: onHangUp,
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ],
    );
  }
}

class _ButtonWithText extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback? onPressed;

  const _ButtonWithText({
    Key? key,
    required this.icon,
    required this.label,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Button(
      onPressed: onPressed,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 48,
              maxHeight: 48,
            ),
            child: IconTheme(
              data: IconTheme.of(context).copyWith(size: 48),
              child: icon,
            ),
          ),
          const SizedBox(height: 10),
          Text(label, style: Theming.of(context).text.button),
        ],
      ),
    );
  }
}
