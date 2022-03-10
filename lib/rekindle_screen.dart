import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:lottie/lottie.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/lobby/lobby_api.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/api/users/rekindle.dart';
import 'package:openup/lobby_screen.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/home_button.dart';
import 'package:openup/widgets/profile_photo.dart';
import 'package:openup/widgets/slide_control.dart';
import 'package:openup/widgets/theming.dart';

/// Screen to re-connect with matches. This screen will fetch rekindles, then
/// pass them onto [PrecachedRekindleScreen].
class RekindleScreen extends ConsumerStatefulWidget {
  final bool video;
  final bool serious;

  const RekindleScreen({
    Key? key,
    required this.video,
    required this.serious,
  }) : super(key: key);

  @override
  _RekindleScreenState createState() => _RekindleScreenState();
}

class _RekindleScreenState extends ConsumerState<RekindleScreen> {
  List<Rekindle>? _rekindles;
  String? _error;

  @override
  void initState() {
    super.initState();
    final userState = ref.read(userProvider);
    final api = GetIt.instance.get<Api>();
    if (!mounted) {
      return;
    }
    api.getRekindles(userState.uid).then((result) {
      result.fold(
        (l) => setState(() => _error = errorToMessage(l)),
        (r) => setState(() => _rekindles = r),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final rekindles = _rekindles;
    final error = _error;
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.black,
      ),
      child: AnimatedCrossFade(
        duration: const Duration(milliseconds: 500),
        firstChild: error == null
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    error,
                    textAlign: TextAlign.center,
                    style: Theming.of(context)
                        .text
                        .headline
                        .copyWith(color: Colors.red),
                  ),
                ),
              ),
        secondChild: rekindles == null
            ? const SizedBox.shrink()
            : RekindleScreenPrecached(
                rekindles: rekindles,
                video: widget.video,
                serious: widget.serious,
                index: 0,
                countdown: false,
              ),
        crossFadeState: _rekindles == null
            ? CrossFadeState.showFirst
            : CrossFadeState.showSecond,
      ),
    );
  }
}

/// Screen to re-connect with matches. This screen does not fetch rekindles,
/// instead they must be passed in.
class RekindleScreenPrecached extends ConsumerWidget {
  final List<Rekindle> rekindles;
  final bool video;
  final bool serious;
  final int index;
  final bool countdown;

  const RekindleScreenPrecached({
    Key? key,
    required this.rekindles,
    required this.video,
    required this.serious,
    required this.index,
    required this.countdown,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (rekindles.isEmpty) {
      return Container(
        color: Colors.black,
        alignment: Alignment.center,
        child: Text(
          'No one to rekindle with',
          style: Theming.of(context).text.headline,
        ),
      );
    }
    final rekindle = rekindles[index];
    final photo = rekindle.photo;

    final myPhoto = ref.watch(userProvider.select((p) => p.profile!.photo));

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: rekindle.purpose == Purpose.friends
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.fromRGBO(0x2E, 0x2E, 0x2E, 1.0),
                  Color.fromRGBO(0x0D, 0x6D, 0x84, 1.0),
                ],
              )
            : const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.fromRGBO(0x2E, 0x2E, 0x2E, 1.0),
                  Color.fromRGBO(0x65, 0x03, 0x07, 1.0),
                ],
              ),
      ),
      child: Stack(
        children: [
          SafeArea(
            top: true,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 80),
                  Text(
                    'Want to chat more?',
                    textAlign: TextAlign.center,
                    style: Theming.of(context)
                        .text
                        .body
                        .copyWith(fontSize: 36, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  Flexible(
                    flex: 6,
                    fit: FlexFit.loose,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minHeight: 100,
                        maxHeight: 160,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 160,
                            height: 160,
                            clipBehavior: Clip.hardEdge,
                            decoration:
                                const BoxDecoration(shape: BoxShape.circle),
                            child: ProfilePhoto(
                              url: myPhoto,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 28),
                          Container(
                            width: 160,
                            height: 160,
                            clipBehavior: Clip.hardEdge,
                            decoration:
                                const BoxDecoration(shape: BoxShape.circle),
                            child: ImageFiltered(
                              imageFilter: ImageFilter.blur(
                                sigmaX: 12.0,
                                sigmaY: 12.0,
                              ),
                              child: ProfilePhoto(
                                url: photo,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (rekindle.purpose == Purpose.friends)
                    Flexible(
                      flex: 4,
                      fit: FlexFit.loose,
                      child: Lottie.asset(
                        'assets/images/friends.json',
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints:
                          const BoxConstraints(minHeight: 40, maxHeight: 126),
                      child: Lottie.asset('assets/images/heart.json'),
                    ),
                  Text(
                    'To become friends and see each others\nprofiles, tap connect below!',
                    textAlign: TextAlign.center,
                    style: Theming.of(context)
                        .text
                        .body
                        .copyWith(fontSize: 18, fontWeight: FontWeight.w300),
                  ),
                  const Spacer(),
                  Button(
                    onPressed: () {
                      _addRekindle(ref, rekindle);
                      _moveToNextScreen(context);
                    },
                    child: Container(
                      width: 256,
                      height: 60,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [
                          Color.fromRGBO(0xFF, 0x71, 0x71, 1.0),
                          Color.fromRGBO(0xFF, 0x3A, 0x42, 1.0),
                        ]),
                        border: Border.all(color: Colors.white),
                        borderRadius: const BorderRadius.all(
                          Radius.circular(76),
                        ),
                      ),
                      child: Text(
                        'Connect',
                        style: Theming.of(context).text.body.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w300,
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Button(
                    onPressed: () => _moveToNextScreen(context),
                    child: Container(
                      width: 256,
                      height: 60,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [
                          Color.fromRGBO(0x27, 0x76, 0x89, 1.0),
                          Color.fromRGBO(0x03, 0xAC, 0xD4, 1.0),
                        ]),
                        border: Border.all(color: Colors.white),
                        borderRadius: const BorderRadius.all(
                          Radius.circular(76),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (video)
                            Lottie.asset(
                              'assets/images/video_call.json',
                              width: 50,
                            )
                          else
                            Lottie.asset(
                              'assets/images/call.json',
                              width: 36,
                            ),
                          const SizedBox(width: 8),
                          Text(
                            'Talk to someone else',
                            style: Theming.of(context).text.body.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w300,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
          Positioned(
            right: MediaQuery.of(context).padding.right + 16,
            bottom: MediaQuery.of(context).padding.bottom + 16,
            child: HomeButton(
              color: rekindle.purpose == Purpose.friends
                  ? const Color.fromRGBO(0x00, 0xA0, 0xD1, 1.0)
                  : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _addRekindle(WidgetRef ref, Rekindle rekindle) {
    final uid = ref.read(userProvider).uid;
    final api = GetIt.instance.get<Api>();
    api.addConnectionRequest(uid, rekindle.uid);
  }

  void _moveToNextScreen(BuildContext context) {
    if (index + 1 < rekindles.length) {
      Navigator.of(context).pushReplacementNamed(
        'precached-rekindle',
        arguments: PrecachedRekindleScreenArguments(
          rekindles: rekindles,
          video: video,
          serious: serious,
          index: index + 1,
          countdown: countdown,
        ),
      );
    } else {
      final purpose = rekindles.first.purpose;
      final route =
          purpose == Purpose.friends ? 'friends-lobby' : 'dating-lobby';
      Navigator.of(context).popAndPushNamed(
        route,
        arguments: LobbyScreenArguments(
          video: video,
          serious: serious,
        ),
      );
    }
  }
}

class ColoredSlider extends StatefulWidget {
  final bool countdown;
  final Duration duration;
  final VoidCallback onTimeUp;
  final VoidCallback onSlideComplete;
  const ColoredSlider({
    Key? key,
    required this.countdown,
    required this.duration,
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
                  duration: widget.duration,
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
    required this.duration,
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

class RekindleScreenArguments {
  final bool video;
  final bool serious;

  RekindleScreenArguments({
    required this.video,
    required this.serious,
  });
}

class PrecachedRekindleScreenArguments {
  final List<Rekindle> rekindles;
  final bool video;
  final bool serious;
  final int index;
  final bool countdown;

  PrecachedRekindleScreenArguments({
    required this.rekindles,
    required this.video,
    required this.serious,
    this.index = 0,
    this.countdown = true,
  });
}
