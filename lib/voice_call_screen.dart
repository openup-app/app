import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:openup/button.dart';
import 'package:openup/slide_control.dart';
import 'package:openup/theming.dart';

class VoiceCallScreen extends StatelessWidget {
  const VoiceCallScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.fromARGB(0xFF, 0x02, 0x4A, 0x5A),
            Color.fromARGB(0xFF, 0x9C, 0xED, 0xFF),
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
                color: const Color.fromARGB(0xFF, 0x01, 0x55, 0x67),
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
                            label: 'add tme',
                            onPressed: () {},
                          ),
                          const SizedBox(width: 30),
                        ],
                      ),
                      Text(
                        'Jose',
                        style: Theming.of(context).text.headline,
                      ),
                      Text(
                        '01:29',
                        style: Theming.of(context).text.body,
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
                        icon: const Icon(Icons.mic),
                        label: 'Mute',
                        onPressed: () {},
                      ),
                      _ButtonWithText(
                        icon: const Icon(
                          Icons.volume_up,
                          color: Color.fromARGB(0xFF, 0x00, 0xFF, 0x19),
                        ),
                        label: 'Speaker',
                        onPressed: () {},
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
            onSlideComplete: Navigator.of(context).pop,
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }
}

class _ButtonWithText extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback onPressed;

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
