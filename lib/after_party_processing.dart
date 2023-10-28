import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class AfterPartyProcessing extends StatelessWidget {
  const AfterPartyProcessing({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top),
          Expanded(
            child: Center(
              child: Transform.scale(
                scale: 1.3,
                child: Lottie.asset('assets/images/thankyou.json'),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: RichText(
              textAlign: TextAlign.center,
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
                children: [
                  TextSpan(
                    text:
                        'Your Glamour Shot will be ready very soon! Once it is ready you will have full access to the app and be able to see everyone’s video also.\n',
                  ),
                  TextSpan(
                    text:
                        'Only people who have had a Glamour Shot taken will have access to the app.\n\n',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text:
                        'Plus one is an exclusive product made for people who want to connect in a real way.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 54),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Container(
              height: 49,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.all(
                  Radius.circular(6),
                ),
              ),
              child: const Text(
                'Notify me once my glamour shot is ready',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
          ),
          const SizedBox(height: 100),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
