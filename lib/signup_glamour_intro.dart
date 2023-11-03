import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/gradient_mask.dart';
import 'package:openup/widgets/party_force_field.dart';
import 'package:openup/widgets/photo_card.dart';
import 'package:openup/widgets/profile_display.dart';

class SignupGlamourIntro extends StatelessWidget {
  const SignupGlamourIntro({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 72),
            const GradientMask(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white,
                  Color.fromRGBO(0xA3, 0xA3, 0xA3, 1.0),
                ],
              ),
              child: Text(
                'Before we show you the\nparty details...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 48),
            Expanded(
              child: PhotoCardWiggle(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return PhotoCard(
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                      useExtraTopPadding: true,
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
                      photo: const PartyForceField(),
                      titleBuilder: (_) => const SizedBox.shrink(),
                      indicatorButton: const SizedBox.shrink(),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 48),
            Button(
              onPressed: () => context.goNamed('signup_name'),
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
                  'Next',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
