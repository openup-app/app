import 'package:flutter/material.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/icon_with_shadow.dart';
import 'package:openup/widgets/slide_control.dart';
import 'package:openup/widgets/theming.dart';

class EndCallReport extends StatelessWidget {
  final Gradient backgroundGradient;
  final Color thumbIconColor;
  final VoidCallback onHangUp;
  final VoidCallback onCancel;

  const EndCallReport({
    Key? key,
    required this.backgroundGradient,
    required this.thumbIconColor,
    required this.onHangUp,
    required this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: backgroundGradient,
        boxShadow: const [
          BoxShadow(
            blurStyle: BlurStyle.inner,
            color: Color.fromRGBO(0x00, 0x00, 0x00, 0.5),
            offset: Offset(0.0, 2.0),
            blurRadius: 11,
          ),
          BoxShadow(
            color: Color.fromRGBO(0x00, 0x00, 0x00, 0.25),
            offset: Offset(0.0, 4.0),
            blurRadius: 4,
          ),
        ],
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 345),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Stop the call and report the user?',
              textAlign: TextAlign.center,
              style: Theming.of(context).text.body.copyWith(
                  fontSize: 48, height: 1.8, fontWeight: FontWeight.w400),
            ),
            const SizedBox(height: 16),
            SlideControl(
              thumbContents: Center(
                child: IconWithShadow(
                  Icons.call_end,
                  color: thumbIconColor,
                  size: 40,
                ),
              ),
              trackContents: const Text('slide to end call'),
              trackGradient: const LinearGradient(
                colors: [
                  Color.fromRGBO(0xFF, 0xFF, 0xFF, 0.65),
                  Color.fromRGBO(0xFF, 0xFF, 0xFF, 0.54),
                ],
              ),
              onSlideComplete: onHangUp,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 100,
              height: 43,
              child: GradientButton(
                onPressed: onCancel,
                child: const Text('cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
