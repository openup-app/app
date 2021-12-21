import 'dart:async';
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:openup/api/lobby/lobby_api.dart';
import 'package:openup/api/users/rekindle.dart';
import 'package:openup/api/users/users_api.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/home_button.dart';
import 'package:openup/widgets/male_female_connection_image.dart';
import 'package:openup/widgets/notification_banner.dart';
import 'package:openup/widgets/profile_photo.dart';
import 'package:openup/widgets/slide_control.dart';
import 'package:openup/widgets/theming.dart';

/// Screen to re-connect with matches. This screen will fetch rekindles, then
/// pass them onto [PrecachedRekindleScreen].
class RekindleScreen extends ConsumerStatefulWidget {
  const RekindleScreen({Key? key}) : super(key: key);

  @override
  _RekindleScreenState createState() => _RekindleScreenState();
}

class _RekindleScreenState extends ConsumerState<RekindleScreen> {
  List<Rekindle>? _rekindles;

  @override
  void initState() {
    super.initState();
    final usersApi = ref.read(usersApiProvider);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      usersApi.getRekindleList(uid).then((rekindles) {
        if (mounted) {
          setState(() => _rekindles = rekindles);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const title = 'rekindle';
    final rekindles = _rekindles;
    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 500),
      firstChild: Container(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const Center(
              child: CircularProgressIndicator(),
            ),
            ..._backTitleAndHomeButtons(context, title),
          ],
        ),
      ),
      secondChild: rekindles == null
          ? const DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black,
              ),
            )
          : RekindleScreenPrecached(
              rekindles: rekindles,
              index: 0,
              title: title,
              countdown: false,
            ),
      crossFadeState: _rekindles == null
          ? CrossFadeState.showFirst
          : CrossFadeState.showSecond,
    );
  }
}

/// Screen to re-connect with matches. This screen does not fetch rekindles,
/// instead they must be passed in.
class RekindleScreenPrecached extends ConsumerWidget {
  final List<Rekindle> rekindles;
  final int index;
  final String title;
  final bool countdown;

  const RekindleScreenPrecached({
    Key? key,
    required this.rekindles,
    required this.index,
    required this.title,
    required this.countdown,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (rekindles.isEmpty) {
      return Container(
        color: Colors.black,
        child: Stack(
          children: [
            Center(
              child: Text('No one to rekindle with',
                  style: Theming.of(context).text.headline),
            ),
            ..._backTitleAndHomeButtons(context, title),
          ],
        ),
      );
    }
    final rekindle = rekindles[index];
    final photo = rekindle.photo;
    final dateFormat = DateFormat('MM / dd / yyyy');

    return Stack(
      alignment: Alignment.center,
      fit: StackFit.expand,
      children: [
        ImageFiltered(
          imageFilter: ImageFilter.blur(
            sigmaX: 8.0,
            sigmaY: 8.0,
          ),
          child: ProfilePhoto(url: photo),
        ),
        Container(
          color: rekindle.purpose == Purpose.friends
              ? const Color.fromARGB(0x4F, 0x3F, 0xC8, 0xFD)
              : const Color.fromARGB(0x4F, 0xFF, 0x60, 0x60),
        ),
        const Positioned(
          right: 0,
          bottom: 255,
          width: 250,
          child: NotificationBanner(
            contents:
                'You will still have 48 hours to connect with this person in the Rekindle section if you decide not to now.',
          ),
        ),
        Positioned(
          bottom: 370,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (rekindle.purpose == Purpose.friends)
                const SizedBox(
                  height: 50,
                  child: MaleFemaleConnectionImage(
                    color: Color.fromARGB(0xFF, 0xAA, 0xDD, 0xED),
                  ),
                )
              else
                SizedBox(
                  height: 50,
                  child: Image.asset('assets/images/heart.gif'),
                ),
              Text(rekindle.name, style: Theming.of(context).text.headline),
              const SizedBox(height: 4),
              Text(
                dateFormat.format(DateTime.now()),
                style: Theming.of(context).text.subheading.copyWith(
                      fontWeight: FontWeight.w300,
                    ),
              ),
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'expires ',
                      style: Theming.of(context)
                          .text
                          .subheading
                          .copyWith(fontWeight: FontWeight.w300),
                    ),
                    TextSpan(
                      text: '2',
                      style: Theming.of(context).text.subheading.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    TextSpan(
                      text: ' days',
                      style: Theming.of(context)
                          .text
                          .subheading
                          .copyWith(fontWeight: FontWeight.w300),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SlideControl(
                  thumbContents: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: countdown
                          ? _Countdown(
                              builder: (context, remainingSeconds) {
                                return Text(
                                  remainingSeconds.toString(),
                                  style: Theming.of(context)
                                      .text
                                      .headline
                                      .copyWith(
                                          fontSize: 42,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.grey),
                                );
                              },
                              onTimeUp: () => _moveToNextScreen(context),
                            )
                          : const Padding(
                              padding: EdgeInsets.only(bottom: 4.0),
                              child: Icon(
                                Icons.fingerprint,
                                color: Colors.black12,
                                size: 44,
                              ),
                            ),
                    ),
                  ),
                  trackContents: const Text('slide to connect'),
                  onSlideComplete: () {
                    _addRekindle(ref, rekindle);
                    _moveToNextScreen(context);
                  },
                  trackBorder: true,
                  trackGradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.fromARGB(0xBF, 0x86, 0xCA, 0xE7),
                      Color.fromARGB(0xBF, 0x03, 0x78, 0xA5),
                    ],
                  ),
                ),
              ),
              const SizedBox(
                height: 16,
              ),
              Button(
                onPressed: () => _moveToNextScreen(context),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 2),
                  margin: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(30)),
                    boxShadow: [
                      BoxShadow(
                        color: Theming.of(context).shadow.withOpacity(0.2),
                        offset: const Offset(0.0, 4.0),
                        blurRadius: 4.0,
                      ),
                    ],
                    color: Theming.of(context).datingRed2,
                  ),
                  child: Text(
                    'skip',
                    style: Theming.of(context).text.body.copyWith(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
        ..._backTitleAndHomeButtons(context, title),
      ],
    );
  }

  void _addRekindle(WidgetRef ref, Rekindle rekindle) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return;
    }

    final usersApi = ref.read(usersApiProvider);
    usersApi.addConnectionRequest(uid, rekindle.uid);
  }

  void _moveToNextScreen(BuildContext context) {
    if (index + 1 < rekindles.length) {
      Navigator.of(context).pushReplacementNamed(
        'precached-rekindle',
        arguments: PrecachedRekindleScreenArguments(
          rekindles: rekindles,
          index: index + 1,
          title: 'rekindle',
          countdown: countdown,
        ),
      );
    } else {
      Navigator.of(context).pop();
    }
  }
}

List<Widget> _backTitleAndHomeButtons(BuildContext context, String title) => [
      Positioned(
        top: MediaQuery.of(context).padding.top,
        left: 0,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: IconButton(
            onPressed: Navigator.of(context).pop,
            icon: const Icon(Icons.arrow_back, size: 32),
          ),
        ),
      ),
      Positioned(
        right: MediaQuery.of(context).padding.right + 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
        child: const HomeButton(
          color: Colors.white,
        ),
      ),
      Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding:
              EdgeInsets.only(top: MediaQuery.of(context).padding.top + 20),
          child: Text(
            title,
            style: Theming.of(context).text.bodySecondary.copyWith(
              shadows: [
                BoxShadow(
                  color: Theming.of(context).shadow,
                  spreadRadius: 0.0,
                  blurRadius: 32.0,
                )
              ],
            ),
          ),
        ),
      ),
    ];

class _Countdown extends StatefulWidget {
  final int startSeconds;
  final Widget Function(BuildContext context, int remainingSeconds) builder;
  final VoidCallback onTimeUp;
  const _Countdown({
    Key? key,
    this.startSeconds = 5,
    required this.builder,
    required this.onTimeUp,
  }) : super(key: key);

  @override
  _CountdownState createState() => _CountdownState();
}

class _CountdownState extends State<_Countdown> {
  late final Timer _timer;
  late int _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = widget.startSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        if (_remaining > 0) {
          setState(() => _remaining--);
        } else {
          widget.onTimeUp();
        }
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _remaining);
}

class PrecachedRekindleScreenArguments {
  final List<Rekindle> rekindles;
  final int index;
  final String title;
  final bool countdown;

  PrecachedRekindleScreenArguments({
    required this.rekindles,
    this.index = 0,
    required this.title,
    this.countdown = true,
  });
}
