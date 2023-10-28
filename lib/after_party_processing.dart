import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:openup/analytics/analytics.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/auth/auth_provider.dart';
import 'package:openup/notifications/notifications.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/notification_request_builder.dart';

class AfterPartyProcessing extends ConsumerStatefulWidget {
  const AfterPartyProcessing({super.key});

  @override
  ConsumerState<AfterPartyProcessing> createState() =>
      _AfterPartyProcessingState();
}

class _AfterPartyProcessingState extends ConsumerState<AfterPartyProcessing> {
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
            child: _NotificationButton(
              onRequestNotification: _updateWaitlist,
            ),
          ),
          const SizedBox(height: 100),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  void _updateWaitlist([NotificationToken? notificationToken]) async {
    ref
        .read(analyticsProvider)
        .trackAfterPartyProcessingRequestGlamourShotNotification();
    final api = ref.read(apiProvider);
    final authState = ref.read(authProvider);
    authState.map(
      guest: (_) {},
      signedIn: (signedIn) async {
        await api.updateWaitlist(
          signedIn.uid,
          signedIn.emailAddress,
          notificationToken,
          event: WaitlistEvent.glamourShotDeltaHouseHalloween2023,
        );
      },
    );
  }
}

class _NotificationButton extends StatefulWidget {
  final void Function(NotificationToken token) onRequestNotification;
  const _NotificationButton({super.key, required this.onRequestNotification});

  @override
  State<_NotificationButton> createState() => _NotificationButtonState();
}

class _NotificationButtonState extends State<_NotificationButton> {
  bool _userRequested = false;
  bool _calledback = false;
  NotificationToken? _token;

  @override
  Widget build(BuildContext context) {
    return NotificationRequestBuilder(
      onGranted: _maybeCallback,
      onToken: (token) {
        setState(() => _token = token);
        _maybeCallback();
      },
      builder: (context, granted, onRequest) {
        if (_calledback) {
          return const SizedBox.shrink();
        }
        return Button(
          onPressed: () async {
            setState(() => _userRequested = true);
            onRequest();
          },
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
        );
      },
    );
  }

  void _maybeCallback() {
    final token = _token;
    if (_userRequested && token != null) {
      setState(() {
        _userRequested = false;
        _calledback = true;
      });
      widget.onRequestNotification(token);
    }
  }
}
