import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/notifications/notifications.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/gradient_mask.dart';
import 'package:openup/widgets/scaffold.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';

class GiftPage extends ConsumerStatefulWidget {
  final String uid;
  final String email;

  const GiftPage({
    super.key,
    required this.uid,
    required this.email,
  });

  @override
  ConsumerState<GiftPage> createState() => _WaitlistPageState();
}

class _WaitlistPageState extends ConsumerState<GiftPage> {
  bool _showNotificationButton = true;
  late final NotificationManager _notificationManager;
  late final String _qrContent;

  @override
  void initState() {
    super.initState();
    _notificationManager = NotificationManager(
      onToken: (token) => _updateWaitlist(token),
      onDeepLink: (_) {},
    );
    _qrContent = widget.email;

    _notificationManager.hasNotificationPermission().then((granted) {
      if (granted) {
        setState(() => _showNotificationButton = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const OpenupAppBar(
        blurBackground: false,
        body: OpenupAppBarBody(
          leading: OpenupAppBarBackButtonOutlined(
            iconColor: Colors.white,
            backgroundColor: Color.fromRGBO(0x52, 0x52, 0x52, 1.0),
            padding: EdgeInsets.only(left: 16),
          ),
        ),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Color.fromRGBO(0xFD, 0xE2, 0xFF, 1.0),
            ],
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: MediaQuery.of(context).padding.top),
            const SizedBox(
              height: 170,
              child: GradientMask(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.fromRGBO(0xDE, 0x80, 0xEF, 1.0),
                    Color.fromRGBO(0xD8, 0x00, 0xFF, 1.0),
                  ],
                ),
                child: Text(
                  'A FREE\nGLAMOUR\nSHOT',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    shadows: [
                      Shadow(
                        offset: Offset(0, 4),
                        blurRadius: 7,
                        color: Color.fromRGBO(0x00, 0x00, 0x00, 0.55),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: Lottie.asset(
                      'assets/images/photo_session.json',
                    ),
                  ),
                  Positioned(
                    left: -30,
                    top: -50,
                    right: -30,
                    child: Lottie.asset('assets/images/glitter.json'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: RichText(
                textAlign: TextAlign.left,
                text: const TextSpan(
                  style: TextStyle(
                    color: Color.fromRGBO(0x5F, 0x5F, 0x5F, 1.0),
                    height: 1.2,
                    fontSize: 15,
                    fontWeight: FontWeight.w300,
                  ),
                  children: [
                    TextSpan(text: 'You are granted a free '),
                    TextSpan(
                      text: 'Glamour Shot',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextSpan(
                      text:
                          ' for joining Plus One! We will be taking the shot at the Delta House party on the 28th, please present your Party QR code to the Videographer.\n\n',
                    ),
                    TextSpan(
                      text:
                          'Your video will be available here on Plus One after the party so please do not delete your app! See you on the 28th!',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: AspectRatio(
                aspectRatio: 1 / 1,
                child: _QrCodeDisplay(
                  content: _qrContent,
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_showNotificationButton)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 41),
                child: Consumer(
                  builder: (context, ref, child) {
                    return Button(
                      onPressed: () async {
                        final permanentlyDenied =
                            await Permission.notification.isPermanentlyDenied;
                        if (!mounted) {
                          return;
                        }
                        if (permanentlyDenied) {
                          openAppSettings();
                        } else {
                          _notificationManager.requestNotificationPermission();
                        }
                      },
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
            const SizedBox(height: 24),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  void _updateWaitlist([NotificationToken? notificationToken]) async {
    final api = ref.read(apiProvider);
    await api.updateWaitlist(widget.uid, widget.email, notificationToken);
    if (mounted) {
      setState(() => _showNotificationButton = false);
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
          boxShadow: [
            BoxShadow(
              blurRadius: 23,
              color: Color.fromRGBO(0x00, 0x00, 0x00, 0.1),
            ),
          ],
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
