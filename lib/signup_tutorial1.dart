import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openup/analytics/analytics.dart';
import 'package:openup/widgets/back_button.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';

class SignupTutorial1 extends ConsumerStatefulWidget {
  const SignupTutorial1({
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<SignupTutorial1> createState() => _SignupTutorial1();
}

class _SignupTutorial1 extends ConsumerState<SignupTutorial1> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(0xF2, 0xF2, 0xF6, 1.0),
      resizeToAvoidBottomInset: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: MediaQuery.of(context).padding.top,
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.topCenter,
            child: Stack(
              alignment: Alignment.center,
              children: const [
                Align(
                  alignment: Alignment.centerLeft,
                  child: BackIconButton(
                    color: Colors.black,
                  ),
                ),
                Text(
                  'A Good Photo Example',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Container(
                    clipBehavior: Clip.hardEdge,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(32)),
                      boxShadow: [
                        BoxShadow(
                          color: Color.fromRGBO(0x00, 0x00, 0x00, 0.1),
                          offset: Offset(0, 11),
                          blurRadius: 26,
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/tutorial_photo_good.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: EdgeInsets.only(right: 8, top: 48),
                    child: TutorialBubble.tick(
                      text: Text('Photos are well lit,\n sharp and in color'),
                    ),
                  ),
                ),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: TutorialBubble.tick(
                      text: Text('You are centered\n and happy'),
                    ),
                  ),
                ),
                const Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: EdgeInsets.only(right: 8, bottom: 48),
                    child: TutorialBubble.tick(
                      text: Text('Alone in portrait and\nfocused in depth'),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Button(
            onPressed: _submit,
            child: RoundedRectangleContainer(
              child: SizedBox(
                width: 171,
                height: 42,
                child: Center(
                  child: Text(
                    'Next',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium!
                        .copyWith(fontSize: 20, fontWeight: FontWeight.w400),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 36),
          SizedBox(
            height: MediaQuery.of(context).padding.bottom,
          ),
        ],
      ),
    );
  }

  void _submit() async {
    ref.read(mixpanelProvider).track("signup_submit_tutorial1");
    context.pushNamed('signup_tutorial2');
  }
}

class TutorialBubble extends StatefulWidget {
  final Text text;
  final bool tick;

  const TutorialBubble.tick({
    super.key,
    required this.text,
  }) : tick = true;

  const TutorialBubble.cross({
    super.key,
    required this.text,
  }) : tick = false;

  @override
  State<TutorialBubble> createState() => _TutorialBubbleState();
}

class _TutorialBubbleState extends State<TutorialBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration:
          Duration(milliseconds: (Random().nextDouble() * 3000 + 8000).toInt()),
    );
    _controller.forward(from: Random().nextDouble());
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.forward(from: 0);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 176,
      height: 96,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final t = _controller.value;
                const intensity = 2;
                final x = cos(t * 6 * pi) * intensity;
                final y = sin(t * 2 * pi) * intensity;
                return Transform.translate(
                  offset: Offset(x, y),
                  child: child,
                );
              },
              child: Container(
                clipBehavior: Clip.hardEdge,
                decoration: const BoxDecoration(
                  color: Color.fromRGBO(0xFF, 0xFF, 0xFF, 0.95),
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
                alignment: Alignment.center,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                  child: Center(
                    child: DefaultTextStyle(
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                        color: Color.fromRGBO(0x00, 0x00, 0x00, 0.6),
                      ),
                      child: widget.text,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topRight,
            child: Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(width: 2, color: Colors.white),
                shape: BoxShape.circle,
                color: widget.tick
                    ? const Color.fromRGBO(0x2D, 0xDA, 0x01, 1.0)
                    : const Color.fromRGBO(0xFF, 0x00, 0x00, 1.0),
                boxShadow: const [
                  BoxShadow(
                    offset: Offset(0, 2),
                    blurRadius: 4,
                    color: Color.fromRGBO(0x00, 0x00, 0x00, 0.15),
                  ),
                ],
              ),
              child: widget.tick
                  ? const Icon(
                      Icons.done,
                      size: 20,
                    )
                  : const Icon(
                      Icons.close,
                      size: 18,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
