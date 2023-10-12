import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/auth/auth_provider.dart';
import 'package:openup/notifications/notifications.dart';
import 'package:openup/widgets/button.dart';
import 'package:qr_flutter/qr_flutter.dart';

class WaitlistPage extends ConsumerStatefulWidget {
  final String uid;

  const WaitlistPage({
    super.key,
    required this.uid,
  });

  @override
  ConsumerState<WaitlistPage> createState() => _WaitlistPageState();
}

class _WaitlistPageState extends ConsumerState<WaitlistPage> {
  bool _showNotificationButton = true;
  late final NotificationManager _notificationManager;

  @override
  void initState() {
    super.initState();
    _notificationManager = NotificationManager(
      onToken: (token) => _updateWaitlist(token),
      onDeepLink: (_) {},
    );
    _notificationManager.hasNotificationPermission().then((granted) {
      if (granted) {
        setState(() => _showNotificationButton = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Lottie.asset(
            'assets/images/river_background.json',
            fit: BoxFit.cover,
          ),
          Column(
            children: [
              SizedBox(height: MediaQuery.of(context).padding.top),
              const SizedBox(height: 12),
              const Text(
                'Here\'s your ticket to the\nDelta House party on\nOctober 28th, 2023',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Flexible(
                child: Lottie.asset(
                  'assets/images/ticket.json',
                  height: 96,
                ),
              ),
              Flexible(
                child: Row(
                  children: [
                    Expanded(
                      child: Lottie.asset(
                        'assets/images/bat.json',
                      ),
                    ),
                    AspectRatio(
                      aspectRatio: 1 / 1,
                      child: _QrCodeDisplay(
                        content: widget.uid,
                      ),
                    ),
                    Expanded(
                      child: Lottie.asset(
                        'assets/images/skull.json',
                        width: 60,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color.fromRGBO(0x00, 0x00, 0x00, 0.79),
                  borderRadius: BorderRadius.all(
                    Radius.circular(7),
                  ),
                ),
                child: const Text(
                  'Plus One is gifting you 🎁 a\nfree Glamour Shot at the party!\n(cinematic video of you)',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    height: 1.3,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 41),
                child: _DotPoint(
                  child: Builder(
                    // Builder to get DefaultTextStyle
                    builder: (context) {
                      return RichText(
                        text: TextSpan(
                          style: DefaultTextStyle.of(context).style.copyWith(
                              fontSize: 14, fontWeight: FontWeight.w300),
                          children: const [
                            TextSpan(text: 'You\'re granted a free '),
                            TextSpan(
                              text: 'Glamour Shot',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 41),
                child: _DotPoint(
                  child: Text(
                      'Present this QR code to the videographer at the party'),
                ),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 41),
                child: _DotPoint(
                  child: Text(
                      'We\'ll send your Glamour Shot here once it\'s ready'),
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: 50,
                  minHeight: 16,
                ),
              ),
              if (_showNotificationButton)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 41),
                  child: Consumer(
                    builder: (context, ref, child) {
                      return Button(
                        onPressed:
                            _notificationManager.requestNotificationPermission,
                        child: Container(
                          height: 49,
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(6)),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color.fromRGBO(0xC7, 0x00, 0xCB, 1.0),
                                Color.fromRGBO(0xBE, 0x17, 0xF9, 1.0),
                              ],
                            ),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'Notify me once my Glamour Shot is ready',
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 32),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        ],
      ),
    );
  }

  void _updateWaitlist([NotificationToken? notificationToken]) async {
    final api = ref.read(apiProvider);
    final uid = ref.read(authProvider.notifier).uid;
    final email = ref.read(authProvider.notifier).email;
    if (uid != null && email != null) {
      await api.updateWaitlist(uid, email, notificationToken);
      if (mounted) {
        setState(() => _showNotificationButton = false);
      }
    }
  }
}

class _QrCodeDisplay extends StatelessWidget {
  final String content;

  const _QrCodeDisplay({
    super.key,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 147,
          maxHeight: 147,
        ),
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(
            Radius.circular(15),
          ),
        ),
        child: Button(
          onPressed: () {
            Navigator.of(context).push(
              _HeroDialogRoute(
                builder: (context) {
                  return Button(
                    onPressed: Navigator.of(context).pop,
                    child: Center(
                      child: Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.all(
                            Radius.circular(15),
                          ),
                        ),
                        child: Hero(
                          tag: 'qr',
                          child: ColoredBox(
                            color: Colors.white,
                            child: _QrCode(content),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
          child: Hero(
            tag: 'qr',
            child: ColoredBox(
              color: Colors.white,
              child: _QrCode(content),
            ),
          ),
        ),
      ),
    );
  }
}

class _QrCode extends StatelessWidget {
  final String contents;

  const _QrCode(
    this.contents, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return QrImageView(
      data: contents,
      padding: EdgeInsets.zero,
    );
  }
}

class _DotPoint extends StatelessWidget {
  final Widget child;

  const _DotPoint({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 4.0),
          child: SizedBox(
            width: 9,
            height: 9,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Color.fromRGBO(0xD9, 0xD9, 0xD9, 1.0),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DefaultTextStyle.merge(
            style: const TextStyle(
              height: 1.3,
              fontSize: 14,
              fontWeight: FontWeight.w300,
            ),
            child: child,
          ),
        ),
      ],
    );
  }
}

/// Based on https://stackoverflow.com/a/44404763
class _HeroDialogRoute<T> extends PageRoute<T> {
  final WidgetBuilder builder;

  _HeroDialogRoute({
    required this.builder,
  }) : super();

  @override
  bool get opaque => false;

  @override
  bool get barrierDismissible => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  bool get maintainState => true;

  @override
  Color get barrierColor => Colors.black54;

  @override
  String? get barrierLabel => 'Dialog barrier';

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: Curves.easeOut,
      ),
      child: child,
    );
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return builder(context);
  }
}
