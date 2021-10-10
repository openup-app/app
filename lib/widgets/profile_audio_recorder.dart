import 'package:flutter/material.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/theming.dart';

class ProfileAudioRecorder extends StatelessWidget {
  const ProfileAudioRecorder({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Theming.of(context).shadow,
            blurRadius: 4,
            offset: const Offset(0.0, 2.0),
          ),
        ],
        gradient: LinearGradient(
          colors: [
            Colors.red.withOpacity(0.6),
            Colors.white.withOpacity(0.6),
          ],
          stops: const [0.3, 0.3],
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 24),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'John, 28',
                style: Theming.of(context).text.headline.copyWith(
                  fontSize: 28,
                  shadows: [
                    Shadow(
                      color: Theming.of(context).shadow,
                      blurRadius: 4,
                      offset: const Offset(0.0, 2.0),
                    ),
                  ],
                ),
              ),
              Text(
                'Three Words Only',
                style: Theming.of(context).text.bodySecondary.copyWith(
                  fontSize: 20,
                  shadows: [
                    Shadow(
                      color: Theming.of(context).shadow,
                      blurRadius: 4,
                      offset: const Offset(0.0, 2.0),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          Button(
            onPressed: () {},
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Theming.of(context).shadow,
                    blurRadius: 4,
                    offset: const Offset(0.0, 2.0),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 28),
          Button(
            onPressed: () {},
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.rectangle,
                boxShadow: [
                  BoxShadow(
                    color: Theming.of(context).shadow,
                    blurRadius: 4,
                    offset: const Offset(0.0, 2.0),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 20),
        ],
      ),
    );
  }
}
