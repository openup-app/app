import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:openup/widgets/back_button.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';

class SignupTutorial extends StatefulWidget {
  const SignupTutorial({super.key});

  @override
  State<SignupTutorial> createState() => _SignupTutorialState();
}

class _SignupTutorialState extends State<SignupTutorial> {
  int _step = 0;

  static const _duration = Duration(milliseconds: 300);
  final _curve = Curves.easeOut;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/tutorial_photo.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            AnimatedOpacity(
              duration: _duration,
              curve: _curve,
              opacity: _step > 0 ? 1 : 0,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: IgnorePointer(
                  child: Container(
                    width: double.infinity,
                    height: 394 + MediaQuery.of(context).padding.bottom,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.8),
                        ],
                        stops: const [0.0, 0.4],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            AnimatedOpacity(
              duration: _duration,
              curve: _curve,
              opacity: _step == 4 ? 1 : 0,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: IgnorePointer(
                  child: Container(
                    height: 420,
                    color: const Color.fromRGBO(0xFF, 0x00, 0x00, 0.2),
                  ),
                ),
              ),
            ),
            AnimatedOpacity(
              duration: _duration,
              curve: _curve,
              opacity: _step > 0 ? 1 : 0,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: IgnorePointer(
                  child: Container(
                    width: double.infinity,
                    height: 420 + MediaQuery.of(context).padding.bottom,
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        const SizedBox(height: 100),
                        const _ListItem(label: 'Center Framed'),
                        AnimatedOpacity(
                          duration: _duration,
                          curve: _curve,
                          opacity: _step > 1 ? 1 : 0,
                          child:
                              const _ListItem(label: 'Taken in portrait mode'),
                        ),
                        AnimatedOpacity(
                          duration: _duration,
                          curve: _curve,
                          opacity: _step > 2 ? 1 : 0,
                          child: const _ListItem(
                              label: 'A body shot / Not close up'),
                        ),
                        AnimatedOpacity(
                          duration: _duration,
                          curve: _curve,
                          opacity: _step > 3 ? 1 : 0,
                          child: const _ListItem(
                              label: 'Head is not too high or low'),
                        ),
                        AnimatedOpacity(
                          duration: _duration,
                          curve: _curve,
                          opacity: _step > 4 ? 1 : 0,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              'Images on openup are fullscreen and converted into cinematic photos (moving images), so extreme close ups and extremally far photos with no depth might make for a boring image here.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(
                                      height: 1.5,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w300),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Button(
                onPressed: () {
                  setState(() => _step++);
                },
                child: const SizedBox.expand(),
              ),
            ),
            AnimatedOpacity(
              duration: _duration,
              curve: _curve,
              opacity: _step > 4 ? 1 : 0,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).padding.bottom + 16),
                  child: Button(
                    onPressed: () =>
                        context.pushNamed('signup_collection_photos'),
                    child: RoundedRectangleContainer(
                      color: Colors.white.withOpacity(0.2),
                      child: SizedBox(
                        width: 171,
                        height: 24,
                        child: Center(
                          child: Text(
                            'Next',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w300,
                                    color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            AnimatedOpacity(
              duration: _duration,
              curve: _curve,
              opacity: _step == 1 ? 1 : 0,
              child: Align(
                alignment: Alignment.centerLeft,
                child: IgnorePointer(
                  child: Container(
                    width: 97,
                    color: const Color.fromRGBO(0xFF, 0x00, 0x00, 0.2),
                  ),
                ),
              ),
            ),
            AnimatedOpacity(
              duration: _duration,
              curve: _curve,
              opacity: _step == 1 ? 1 : 0,
              child: Align(
                alignment: Alignment.centerRight,
                child: IgnorePointer(
                  child: Container(
                    width: 97,
                    color: const Color.fromRGBO(0xFF, 0x00, 0x00, 0.2),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: 96 + MediaQuery.of(context).padding.top,
              child: Stack(
                children: [
                  AnimatedOpacity(
                    duration: _duration,
                    curve: _curve,
                    opacity: _step != 1 ? 1 : 0,
                    child: ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 13, sigmaY: 13),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                  AnimatedOpacity(
                    duration: _duration,
                    curve: _curve,
                    opacity: _step == 4 ? 1 : 0,
                    child: IgnorePointer(
                      child: Container(
                        color: const Color.fromRGBO(0xFF, 0x00, 0x00, 0.2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top),
                    child: Center(
                      child: Text(
                        'Example of a great profile\non Openup',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            height: 1.5,
                            fontSize: 16,
                            fontWeight: FontWeight.w300),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 24,
              child: const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: BackIconButton(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListItem extends StatelessWidget {
  final String label;

  const _ListItem({
    super.key,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 272,
            child: Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium!
                  .copyWith(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          CustomPaint(
            painter: _CircleCustomPaint(),
          )
        ],
      ),
    );
  }
}

class _CircleCustomPaint extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(
      size.center(Offset.zero),
      9,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _CircleCustomPaint oldDelegate) => false;
}
