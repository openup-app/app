import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:openup/api/lobby/lobby_api.dart';
import 'package:openup/api/users/rekindle.dart';
import 'package:openup/api/users/users_api.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/home_button.dart';
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
      usersApi.getRekindles(uid).then((rekindles) {
        if (mounted) {
          setState(() => _rekindles = rekindles);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
            ..._backTitleAndHomeButtons(context, 'rekindle'),
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
  final bool countdown;

  const RekindleScreenPrecached({
    Key? key,
    required this.rekindles,
    required this.index,
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
            ..._backTitleAndHomeButtons(context, 'rekindle'),
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
            sigmaX: 4.0,
            sigmaY: 4.0,
          ),
          child: ProfilePhoto(url: photo),
        ),
        countdown
            ? _Countdown(
                onTimeUp: () {},
                builder: (context, remaining) {
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      color: rekindle.purpose == Purpose.friends
                          ? Color.fromRGBO(
                              0x3F,
                              0xC8,
                              0xFD,
                              1 -
                                  remaining.inMilliseconds /
                                      const Duration(seconds: 5).inMilliseconds)
                          : Color.fromRGBO(
                              0xFF,
                              0x60,
                              0x60,
                              1 -
                                  remaining.inMilliseconds /
                                      const Duration(seconds: 5)
                                          .inMilliseconds),
                    ),
                  );
                },
              )
            : DecoratedBox(
                decoration: BoxDecoration(
                  color: rekindle.purpose == Purpose.friends
                      ? const Color.fromRGBO(0x3F, 0xC8, 0xFD, 0.75)
                      : const Color.fromRGBO(0xFF, 0x60, 0x60, 0.75),
                ),
              ),
        // Workaround for BlurStyle.inner not being an inner glow
        for (final ltrbwh in [
          [-35.0, 0.0, null, 0.0, 50.0, null], // Left
          [null, 0.0, -35.0, 0.0, 50.0, null], // Right
          [0.0, -35.0, 0.0, null, null, 50.0], // Top
          [0.0, null, 0.0, -35.0, null, 50.0], // Bottom
        ])
          Positioned(
            left: ltrbwh[0],
            top: ltrbwh[1],
            right: ltrbwh[2],
            bottom: ltrbwh[3],
            width: ltrbwh[4],
            height: ltrbwh[5],
            child: const DecoratedBox(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    blurStyle: BlurStyle.normal,
                    blurRadius: 139,
                    color: Color.fromRGBO(0xC7, 0xC7, 0xC7, 1.0),
                  ),
                ],
              ),
            ),
          ),
        Positioned(
          bottom: 370,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (rekindle.purpose == Purpose.friends)
                SizedBox(
                  height: 50,
                  child: Image.asset(
                    'assets/images/friends.gif',
                    color: const Color.fromARGB(0xFF, 0xAA, 0xDD, 0xED),
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
                child: ColoredSlider(
                  countdown: countdown,
                  onTimeUp: () => _moveToNextScreen(context),
                  onSlideComplete: () {
                    _addRekindle(ref, rekindle);
                    _moveToNextScreen(context);
                  },
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
        ..._backTitleAndHomeButtons(context,
            rekindle.purpose == Purpose.friends ? 'make friends' : 'dating'),
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

class ColoredSlider extends StatefulWidget {
  final bool countdown;
  final VoidCallback onTimeUp;
  final VoidCallback onSlideComplete;
  const ColoredSlider({
    Key? key,
    required this.countdown,
    required this.onTimeUp,
    required this.onSlideComplete,
  }) : super(key: key);

  @override
  _ColoredSliderState createState() => _ColoredSliderState();
}

class _ColoredSliderState extends State<ColoredSlider> {
  double _value = 0.0;

  @override
  Widget build(BuildContext context) {
    return SlideControl(
      thumbContents: Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: widget.countdown
              ? _Countdown(
                  builder: (context, remaining) {
                    return Text(
                      remaining.inSeconds.toString(),
                      style: Theming.of(context).text.headline.copyWith(
                          fontSize: 42,
                          fontWeight: FontWeight.w800,
                          color: Colors.grey),
                    );
                  },
                  onTimeUp: widget.onTimeUp,
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
      onSlideComplete: widget.onSlideComplete,
      onSlideUpdate: (value) {
        setState(() => _value = value);
      },
      trackBorder: true,
      trackGradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          ColorTween(
                  begin: const Color.fromRGBO(0x86, 0xCA, 0xE7, 0.75),
                  end: const Color.fromRGBO(0x86, 0xE7, 0x95, 0.75))
              .evaluate(
            AlwaysStoppedAnimation(_value),
          )!,
          ColorTween(
                  begin: const Color.fromRGBO(0x03, 0x78, 0xA5, 0.75),
                  end: const Color.fromRGBO(0x03, 0x94, 0x1A, 0.75))
              .evaluate(
            AlwaysStoppedAnimation(_value),
          )!,
        ],
      ),
    );
  }
}

class _Countdown extends StatefulWidget {
  final Duration duration;
  final Widget Function(BuildContext context, Duration duration) builder;
  final VoidCallback onTimeUp;
  const _Countdown({
    Key? key,
    this.duration = const Duration(seconds: 5),
    required this.builder,
    required this.onTimeUp,
  }) : super(key: key);

  @override
  _CountdownState createState() => _CountdownState();
}

class _CountdownState extends State<_Countdown> {
  late Duration _remaining;
  late final Duration _initialDuration;

  @override
  void initState() {
    super.initState();
    _remaining = widget.duration;
    _initialDuration = SchedulerBinding.instance!.currentFrameTimeStamp;
    SchedulerBinding.instance?.addPostFrameCallback(_update);
  }

  void _update(Duration duration) {
    if (mounted) {
      if (_remaining > Duration.zero) {
        final remaining = widget.duration - (duration - _initialDuration);
        setState(() =>
            _remaining = remaining < Duration.zero ? Duration.zero : remaining);
        SchedulerBinding.instance?.addPostFrameCallback(_update);
      } else {
        widget.onTimeUp();
      }
    }
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _remaining);
}

class PrecachedRekindleScreenArguments {
  final List<Rekindle> rekindles;
  final int index;
  final bool countdown;

  PrecachedRekindleScreenArguments({
    required this.rekindles,
    this.index = 0,
    this.countdown = true,
  });
}
