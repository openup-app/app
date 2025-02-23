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
  late final TapGestureRecognizer _termsRecognizer;

  @override
  void initState() {
    super.initState();
    _privacyPolicyRecognizer = TapGestureRecognizer()
      ..onTap = () {
        launchUrl(Uri.parse(
            'https://openup-app.github.io/policies/privacy_policy.html'));
      };

    _termsRecognizer = TapGestureRecognizer()
      ..onTap = () {
        launchUrl(Uri.parse('https://openup-app.github.io/policies/eula.html'));
      };
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              color: const Color.fromRGBO(0xFF, 0xFF, 0xFF, 0.5),
              fontSize: 12,
              fontWeight: FontWeight.w400,
              height: 1.8),
          children: [
            const TextSpan(
              text: 'By continuing, you agree to our\n',
            ),
            TextSpan(
              text: 'Privacy Policy',
              recognizer: _privacyPolicyRecognizer,
            ),
            const TextSpan(text: ' and '),
            TextSpan(
              text: 'Terms of Service',
              recognizer: _termsRecognizer,
            ),
            const TextSpan(text: '.'),
          ],
        ),
      ),
    );
  }
}
