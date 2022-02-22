import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:openup/api/signaling/phone.dart';
import 'package:openup/call_screen.dart';
import 'package:openup/widgets/button.dart';
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
          child: Opacity(
            opacity: 0.25,
            child: Image.network(
              photo,
              fit: BoxFit.cover,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: VoiceCallScreenTheme.of(context).backgroundGradient,
          ),
          child: SafeArea(
            top: true,
            child: Column(
              children: [
                const Spacer(),
                if (endTime == null)
                  const SizedBox(height: 88)
                else
                  _ButtonWithText(
                    icon: const Icon(Icons.alarm_add, size: 54),
                    label: 'tap to talk more',
                    onPressed: hasSentTimeRequest ? null : onSendTimeRequest,
                  ),
                const SizedBox(height: 5),
                // if (kDebugMode)
                //   Text(
                //     profile.name,
                //     style: Theming.of(context).text.headline.copyWith(
                //           fontSize: 36,
                //         ),
                //   ),
                SizedBox(
                  height: 64,
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
                                    fontSize: 64,
                                  ),
                            );
                          },
                        ),
                ),
                Builder(
                  builder: (context) {
                    final style = Theming.of(context).text.headline.copyWith(
                          fontSize: 24,
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
                const Spacer(flex: 1),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Opacity(
                      opacity: tempFirstUser.rekindle == null ? 0.0 : 1.0,
                      child: _ButtonWithText(
                        icon: const Icon(Icons.person_add),
                        label: 'Add friend',
                        onPressed: () => onConnect(profile.uid),
                      ),
                    ),
                    const SizedBox(width: 89),
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
                const Spacer(flex: 1),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ButtonWithText(
                      icon: muted
                          ? const Icon(Icons.mic_off)
                          : const Icon(Icons.mic),
                      label: 'Mute',
                      onPressed: onToggleMute,
                    ),
                    const SizedBox(width: 89),
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
                const Spacer(),
                Container(
                  constraints: const BoxConstraints(maxWidth: 434),
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  child: SlideControl(
                    thumbContents: Icon(
                      Icons.call_end,
                      color:
                          VoiceCallScreenTheme.of(context).endCallSymbolColor,
                      size: 40,
                    ),
                    trackContents: const Text('slide to end call'),
                    trackGradient:
                        VoiceCallScreenTheme.of(context).endCallGradient,
                    onSlideComplete: onHangUp,
                  ),
                ),
                const Spacer(),
              ],
            ),
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
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 90),
      child: Center(
        child: Button(
          onPressed: onPressed,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(
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
                textAlign: TextAlign.center,
                style: Theming.of(context).text.bodySecondary.copyWith(
                      fontSize: 20,
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
