import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:openup/analytics/analytics.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/auth/auth_provider.dart';
import 'package:openup/notifications/notifications.dart';
import 'package:openup/video/video.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/notification_request_builder.dart';

import 'widgets/party_force_field.dart';

class AfterPartyWaitlist extends ConsumerStatefulWidget {
  final List<String> videos;

  const AfterPartyWaitlist({
    super.key,
    required this.videos,
  });

  @override
  ConsumerState<AfterPartyWaitlist> createState() => _AfterPartyWaitlistState();
}

class _AfterPartyWaitlistState extends ConsumerState<AfterPartyWaitlist> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          const Positioned.fill(
            child: PartyForceField(),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: MediaQuery.of(context).padding.top),
              if (widget.videos.isEmpty) const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Plus\nOne',
                      style: TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: Lottie.asset(
                        'assets/images/hangout.json',
                        width: 61,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: Text(
                  'Plus one is an exclusive product made for people who want to connect in a real way.\n\nPlease wait to be invited to the next Plus One event to take your Glamour Shot and gain access. ${widget.videos.isEmpty ? 'Check back soon for Glamour shots from our last event' : 'Check out the Glamour shots from our last event.'}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              if (widget.videos.isEmpty)
                const Spacer()
              else
                Expanded(
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    itemCount: widget.videos.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 15),
                    itemBuilder: (context, index) {
                      return _Video(
                        url: widget.videos[index],
                      );
                    },
                  ),
                ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: _NotificationButton2(
                  onRequestNotification: _updateNextEventWaitlist,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        ],
      ),
    );
  }

  void _updateNextEventWaitlist(NotificationToken token) {
    ref.read(analyticsProvider).trackAfterPartyRequestNextEventNotification();
    final api = ref.read(apiProvider);
    final authState = ref.read(authProvider);
    authState.map(
      guest: (_) {},
      signedIn: (signedIn) {
        api.updateWaitlist(
          signedIn.uid,
          signedIn.emailAddress,
          token,
          event: WaitlistEvent.next,
        );
      },
    );
  }
}

class _NotificationButton2 extends StatefulWidget {
  final void Function(NotificationToken token) onRequestNotification;

  const _NotificationButton2({
    super.key,
    required this.onRequestNotification,
  });

  @override
  State<_NotificationButton2> createState() => _NotificationButton2State();
}

class _NotificationButton2State extends State<_NotificationButton2> {
  bool _enabled = false;
  bool _userRequested = false;
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
        return Button(
          onPressed: _userRequested
              ? null
              : () {
                  setState(() => _userRequested = true);
                  onRequest();
                },
          useFadeWheNoPressedCallback: false,
          child: SizedBox(
            width: double.infinity,
            height: 49,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(
                  Radius.circular(6),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color.fromRGBO(0x00, 0x00, 0x00, 0.25),
                    blurRadius: 14,
                  ),
                ],
              ),
              child: SizedBox(
                width: 300,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 32,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 2.0),
                        child: _NotificationIcon(
                          enabled: _enabled,
                        ),
                      ),
                    ),
                    const Text(
                      'Notify me of the next event',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
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
      setState(() => _enabled = true);
      widget.onRequestNotification(token);
    }
  }
}

class _Video extends StatelessWidget {
  final String url;

  const _Video({
    super.key,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 24,
      ),
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(
              Radius.circular(12),
            ),
            boxShadow: [
              BoxShadow(
                offset: Offset(0, 1),
                color: Color.fromRGBO(0x00, 0x00, 0x00, 0.25),
                blurRadius: 13,
              ),
            ],
          ),
          child: VideoBuilder(
            uri: Uri.parse(url),
            autoPlay: true,
            builder: (context, video, controller) {
              return video;
            },
          ),
        ),
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _NotificationButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Button(
      onPressed: onPressed,
      child: SizedBox(
        width: 107,
        height: 36,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(
              Radius.circular(5),
            ),
          ),
          child: Center(
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: 32,
                    height: 24,
                    child: ClipRect(
                      child: OverflowBox(
                        maxWidth: 160,
                        maxHeight: 160,
                        child: ColorFiltered(
                          colorFilter: const ColorFilter.mode(
                            Colors.black,
                            BlendMode.srcIn,
                          ),
                          child: Lottie.asset(
                            'assets/images/notification.json',
                            width: 160,
                            height: 160,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.only(left: 28),
                    child: Text(
                      'Notify me',
                      style: TextStyle(
                        color: Color.fromRGBO(0x4E, 0x4E, 0x4E, 1.0),
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
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

class _NotificationIcon extends StatefulWidget {
  final bool enabled;
  const _NotificationIcon({
    super.key,
    required this.enabled,
  });

  @override
  State<_NotificationIcon> createState() => _NotificationIconState();
}

class _NotificationIconState extends State<_NotificationIcon> {
  Timer? _timer;
  bool _animate = false;

  @override
  void initState() {
    super.initState();
    if (widget.enabled) {
      _animateIcon();
    }
  }

  @override
  void didUpdateWidget(covariant _NotificationIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.enabled && widget.enabled) {
      _animateIcon();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: OverflowBox(
        maxWidth: 180,
        maxHeight: 180,
        child: ColorFiltered(
          colorFilter: const ColorFilter.mode(
            Colors.black,
            BlendMode.srcIn,
          ),
          child: Lottie.asset(
            'assets/images/notification.json',
            width: 180,
            height: 180,
            animate: _animate,
          ),
        ),
      ),
    );
  }

  void _animateIcon() {
    final timer = Timer(
      const Duration(seconds: 2),
      () => setState(() => _animate = false),
    );
    setState(() {
      _timer = timer;
      _animate = true;
    });
  }
}

class AfterPartyWaitlistParams {
  final List<String> sampleVideos;
  const AfterPartyWaitlistParams(this.sampleVideos);
}
