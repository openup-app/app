import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/notifications/notifications.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/gradient_mask.dart';
import 'package:openup/widgets/scaffold.dart';
import 'package:permission_handler/permission_handler.dart';

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
            const SizedBox(height: 32),
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
              padding: const EdgeInsets.symmetric(horizontal: 56),
              child: RichText(
                textAlign: TextAlign.center,
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
                          ' for joining Plus One! We will be taking the shot at the Delta House party on the 28th, please present your Party QR code to the Videographer. \n\nYour video will be available here on Plus One after the party so please do not delete your app! See you on the 28th!',
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
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
            const SizedBox(height: 50),
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
