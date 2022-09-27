import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class Policies extends StatefulWidget {
  const Policies({Key? key}) : super(key: key);

  @override
  State<Policies> createState() => _PoliciesState();
}

class _PoliciesState extends State<Policies> {
  late final TapGestureRecognizer _privacyPolicyRecognizer;
  late final TapGestureRecognizer _eulaRecognizer;

  @override
  void initState() {
    super.initState();
    _privacyPolicyRecognizer = TapGestureRecognizer()
      ..onTap = () {
        launchUrl(Uri.parse(
            'https://openup-app.github.io/policies/privacy_policy.html'));
      };

    _eulaRecognizer = TapGestureRecognizer()
      ..onTap = () {
        launchUrl(Uri.parse('https://openup-app.github.io/policies/eula.html'));
      };
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: RichText(
        textAlign: TextAlign.justify,
        text: TextSpan(
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
          children: [
            const TextSpan(
              text:
                  'By tapping Verify Account & Accept, you acknowledge that you have read the ',
            ),
            TextSpan(
              text: 'Privacy Policy',
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: const Color.fromRGBO(0xFF, 0x00, 0x00, 1.0),
                  fontSize: 16,
                  fontWeight: FontWeight.w700),
              recognizer: _privacyPolicyRecognizer,
            ),
            const TextSpan(text: ' and agree to the '),
            TextSpan(
              text: 'EULA',
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: const Color.fromRGBO(0xFF, 0x00, 0x00, 1.0),
                  fontSize: 16,
                  fontWeight: FontWeight.w700),
              recognizer: _eulaRecognizer,
            ),
            const TextSpan(text: '.'),
          ],
        ),
      ),
    );
  }
}
