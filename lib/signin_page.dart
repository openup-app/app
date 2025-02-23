import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/auth/auth_provider.dart';
import 'package:openup/waitlist/waitlist_provider.dart';
import 'package:openup/widgets/button.dart';
import 'package:url_launcher/url_launcher.dart';

class SigninPage extends ConsumerStatefulWidget {
  const SigninPage({super.key});

  @override
  ConsumerState<SigninPage> createState() => _SigninPageState();
}

class _SigninPageState extends ConsumerState<SigninPage> {
  @override
  void initState() {
    super.initState();
    ref.listenManual(
      waitlistProvider,
      fireImmediately: true,
      (previous, next) {
        if (next != null) {
          _signInComplete(next);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: const TextStyle(
        color: Colors.black,
      ),
      child: Scaffold(
        backgroundColor: const Color.fromRGBO(0xD7, 0xD7, 0xD7, 1.0),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 41),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: MediaQuery.of(context).padding.top),
              const Spacer(),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Plus\nOne',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 64,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: ColorFiltered(
                      colorFilter: const ColorFilter.mode(
                        Colors.black,
                        BlendMode.srcIn,
                      ),
                      child: Lottie.asset(
                        'assets/images/hangout.json',
                        width: 61,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const _Subtitle(),
              const SizedBox(height: 46),
              _SignInButton(
                onPressed: _googleSignIn,
                icon: SvgPicture.asset('assets/images/google_logo.svg'),
                label: const Text('Sign in with Google'),
              ),
              const SizedBox(height: 17),
              _SignInButton(
                onPressed: _appleSignIn,
                icon: SvgPicture.asset('assets/images/apple_logo.svg'),
                label: const Text('Continue with Apple'),
              ),
              const Spacer(),
              const Center(
                child: _Policies(),
              ),
              const SizedBox(height: 50),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        ),
      ),
    );
  }

  void _googleSignIn() async {
    final result = await ref.read(authProvider.notifier).signInWithGoogle();
    if (!mounted) {
      return;
    }

    if (result == null) {
      return;
    }
    final message = switch (result) {
      AuthResult.success => null,
      AuthResult.invalidCode ||
      AuthResult.invalidId ||
      AuthResult.quotaExceeded ||
      AuthResult.failure =>
        'Failed to sign in',
    };
    if (message != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
    }
  }

  void _appleSignIn() async {
    final result = await ref.read(authProvider.notifier).signInWithApple();
    if (!mounted) {
      return;
    }

    if (result == null) {
      return;
    }
    final message = switch (result) {
      AuthResult.success => null,
      AuthResult.invalidCode ||
      AuthResult.invalidId ||
      AuthResult.quotaExceeded ||
      AuthResult.failure =>
        'Failed to sign in',
    };
    if (message != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
    }
  }

  void _signInComplete(WaitlistUser user) async {
    // Using RestartApp here when there is no account causes an exception in
    // Riverpod when RestartApp is used again at the end of signup. It says
    // "Only one task can be scheduled at a time". Perhaps ProviderScope is
    // living through restarts, so using it fewer times causes the errro not
    // to trigger.
    context.goNamed('initial_loading');
    ref.invalidate(getAccountProvider);
  }
}

class _Subtitle extends StatefulWidget {
  const _Subtitle({super.key});

  @override
  State<_Subtitle> createState() => _SubtitleState();
}

class _SubtitleState extends State<_Subtitle> {
  late Widget _text;
  late Timer _timer;
  int _labelIndex = 0;
  final _labels = const [
    'study',
    'drink',
    'dance',
    'sing',
    'game',
    'chill',
    'eat',
  ];

  @override
  void initState() {
    super.initState();
    _cycleText();
  }

  @override
  void dispose() {
    super.dispose();
    _timer.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: const TextStyle(
        color: Colors.black,
        fontSize: 20,
        fontWeight: FontWeight.w300,
      ),
      child: Row(
        children: [
          const Text('Find someone to '),
          AnimatedSize(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              switchInCurve: Curves.easeOut,
              child: DefaultTextStyle.merge(
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
                child: _text,
              ),
            ),
          ),
          const Text(' with'),
        ],
      ),
    );
  }

  void _cycleText() {
    setState(
      () {
        final label = _labels[(_labelIndex++) % _labels.length];
        _text = Text(
          label,
          key: ValueKey(label),
        );
      },
    );
    _timer = Timer(const Duration(seconds: 3), _cycleText);
  }
}

class _SignInButton extends StatelessWidget {
  final Widget icon;
  final Widget label;
  final VoidCallback onPressed;

  const _SignInButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Button(
      onPressed: onPressed,
      child: Container(
        height: 49,
        decoration: const BoxDecoration(
          color: Color.fromRGBO(0xEE, 0xEE, 0xEE, 1.0),
          borderRadius: BorderRadius.all(
            Radius.circular(6),
          ),
        ),
        child: Center(
          child: SizedBox(
            width: 150,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                icon,
                const SizedBox(width: 8),
                Expanded(
                  child: DefaultTextStyle.merge(
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w300,
                    ),
                    child: label,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Policies extends StatefulWidget {
  const _Policies({Key? key}) : super(key: key);

  @override
  State<_Policies> createState() => _PoliciesState();
}

class _PoliciesState extends State<_Policies> {
  late final TapGestureRecognizer _privacyPolicyRecognizer;
  late final TapGestureRecognizer _termsRecognizer;

  @override
  void initState() {
    super.initState();
    _privacyPolicyRecognizer = TapGestureRecognizer()
      ..onTap = () {
        launchUrl(Uri.parse('https://plus-one.app/Privacy.html'));
      };

    _termsRecognizer = TapGestureRecognizer()
      ..onTap = () {
        launchUrl(Uri.parse('https://plus-one.app/Terms.html'));
      };
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: const TextStyle(
            color: Colors.black,
            fontSize: 12,
            fontWeight: FontWeight.w400,
            height: 1.8,
          ),
          children: [
            const TextSpan(
              text: 'By creating an account you agree to the Plus One\n',
            ),
            TextSpan(
              text: 'Terms of Use',
              recognizer: _termsRecognizer,
              style: const TextStyle(
                decoration: TextDecoration.underline,
              ),
            ),
            const TextSpan(text: ' and '),
            TextSpan(
              text: 'Privacy Policy',
              recognizer: _privacyPolicyRecognizer,
              style: const TextStyle(
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
