import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:openup/api/signaling/phone.dart';
import 'package:openup/call_screen.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/icon_with_shadow.dart';
import 'package:openup/widgets/slide_control.dart';
import 'package:openup/widgets/theming.dart';
import 'package:openup/widgets/time_remaining.dart';

part 'voice_call_screen_content.freezed.dart';

/// Voice call display and controls.
///
/// Setting [endTime] to `null` will disable the timer UI and will not
/// trigger [onTimeUp].
class VoiceCallScreenContent extends StatelessWidget {
  final List<UserConnection> users;
  final bool hasSentTimeRequest;
  final DateTime? endTime;
  final bool muted;
  final bool speakerphone;
  final VoidCallback onTimeUp;
  final VoidCallback onHangUp;
  final VoidCallback onSendTimeRequest;
  final void Function(String uid) onConnect;
  final void Function(String uid) onReport;
  final VoidCallback onToggleMute;
  final VoidCallback onToggleSpeakerphone;

  const VoiceCallScreenContent({
    Key? key,
    required this.users,
    required this.hasSentTimeRequest,
    required this.endTime,
    required this.muted,
    required this.speakerphone,
    required this.onTimeUp,
    required this.onHangUp,
    required this.onSendTimeRequest,
    required this.onConnect,
    required this.onReport,
    required this.onToggleMute,
    required this.onToggleSpeakerphone,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tempFirstUser = users.first;
    final profile = tempFirstUser.profile;
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
          decoration: BoxDecoration(
            gradient: VoiceCallScreenTheme.of(context).backgroundGradient,
          ),
          child: Column(
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: 40,
                  minHeight: 4,
                ),
              ),
              SafeArea(
                top: true,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(
                      Radius.circular(48),
                    ),
                    gradient: VoiceCallScreenTheme.of(context).panelGradient,
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(0x00, 0x00, 0x00, 0.25),
                        offset: Offset(0.0, 4.0),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (endTime == null)
                            const SizedBox(height: 88)
                          else
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                _ButtonWithText(
                                  icon: const IconWithShadow(Icons.alarm_add),
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
                            style: Theming.of(context).text.headline.copyWith(
                              fontSize: 36,
                              shadows: [
                                const Shadow(
                                  offset: Offset(0.0, 4.0),
                                  blurRadius: 4,
                                  color: Color.fromRGBO(0x00, 0x00, 0x00, 0.25),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 29,
                            child: endTime == null
                                ? const SizedBox.shrink()
                                : TimeRemaining(
                                    endTime: endTime!,
                                    onTimeUp: onTimeUp,
                                    builder: (context, remaining) {
                                      return Text(
                                        remaining,
                                        style: Theming.of(context)
                                            .text
                                            .bodySecondary
                                            .copyWith(
                                          fontSize: 24,
                                          shadows: [
                                            const Shadow(
                                              color: Color.fromRGBO(
                                                  0x00, 0x00, 0x00, 0.25),
                                              blurRadius: 4,
                                              offset: Offset(0.0, 4.0),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),
                          Builder(
                            builder: (context) {
                              final style =
                                  Theming.of(context).text.headline.copyWith(
                                fontSize: 24,
                                shadows: [
                                  const Shadow(
                                    color:
                                        Color.fromRGBO(0x00, 0x00, 0x00, 0.25),
                                    blurRadius: 4,
                                    offset: Offset(0.0, 4.0),
                                  ),
                                ],
                              );
                              final text = connectionStateText(
                                connectionState: tempFirstUser.connectionState,
                                name: tempFirstUser.profile.name,
                              );
                              return AnimatedOpacity(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                                opacity: tempFirstUser.connectionState ==
                                        PhoneConnectionState.connected
                                    ? 0.0
                                    : 1.0,
                                child: Text(
                                  text,
                                  style: style,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxHeight: 24,
                          minHeight: 4,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _ButtonWithText(
                            icon: const IconWithShadow(Icons.person_add),
                            label: 'Connect',
                            onPressed: tempFirstUser.rekindle != null
                                ? () => onConnect(profile.uid)
                                : null,
                          ),
                          _ButtonWithText(
                            icon: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Image.asset('assets/images/report.png'),
                            ),
                            label: 'Report',
                            onPressed: () => onReport(profile.uid),
                          ),
                        ],
                      ),
                      ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxHeight: 90,
                          minHeight: 40,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _ButtonWithText(
                            icon: muted
                                ? const IconWithShadow(Icons.mic_off)
                                : const IconWithShadow(Icons.mic),
                            label: 'Mute',
                            onPressed: onToggleMute,
                          ),
                          _ButtonWithText(
                            icon: IconWithShadow(
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
                  color: VoiceCallScreenTheme.of(context).endCallSymbolColor,
                  size: 40,
                ),
                trackContents: const Text('slide to end call'),
                trackGradient: VoiceCallScreenTheme.of(context).endCallGradient,
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
    return SizedBox(
      width: 90,
      child: Center(
        child: Button(
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
              const SizedBox(height: 15),
              Text(
                label,
                style: Theming.of(context).text.bodySecondary.copyWith(
                  fontSize: 20,
                  shadows: [
                    const Shadow(
                      offset: Offset(0.0, 4.0),
                      blurRadius: 4,
                      color: Color.fromRGBO(0x00, 0x00, 0x00, 0.25),
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

class VoiceCallScreenTheme extends InheritedWidget {
  final VoiceCallScreenThemeData themeData;

  const VoiceCallScreenTheme({
    Key? key,
    required Widget child,
    required this.themeData,
  }) : super(key: key, child: child);

  static VoiceCallScreenThemeData of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<VoiceCallScreenTheme>()!
        .themeData;
  }

  @override
  bool updateShouldNotify(VoiceCallScreenTheme oldWidget) =>
      oldWidget.themeData != themeData;
}

@freezed
class VoiceCallScreenThemeData with _$VoiceCallScreenThemeData {
  const factory VoiceCallScreenThemeData({
    required LinearGradient backgroundGradient,
    required LinearGradient panelGradient,
    required LinearGradient endCallGradient,
    required Color endCallSymbolColor,
  }) = _VoiceCallScreenThemeData;
}
