import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/gradient_mask.dart';
import 'package:openup/widgets/scaffold.dart';
import 'package:qr_flutter/qr_flutter.dart';

class TicketPage extends StatelessWidget {
  final String uid;
  final String email;
  final String _qrContent;

  const TicketPage({
    super.key,
    required this.uid,
    required this.email,
  }) : _qrContent = email;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const OpenupAppBar(
        blurBackground: false,
        body: OpenupAppBarBody(
          leading: OpenupAppBarBackButtonOutlined(
            padding: EdgeInsets.only(left: 16),
          ),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Lottie.asset(
            'assets/images/river_background.json',
            fit: BoxFit.cover,
          ),
          Center(
            child: Lottie.asset(
              'assets/images/lightning.json',
              fit: BoxFit.cover,
            ),
          ),
          Column(
            children: [
              SizedBox(height: MediaQuery.of(context).padding.top),
              const SizedBox(height: 70),
              SizedBox(
                height: 110,
                child: Stack(
                  children: [
                    const Positioned.fill(
                      child: Padding(
                        padding: EdgeInsets.only(left: 27.0),
                        child: GradientMask(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white,
                              Color.fromRGBO(0xFF, 0xDE, 0xDE, 1.0),
                              Color.fromRGBO(0xAB, 0x00, 0x00, 1.0),
                            ],
                          ),
                          child: Text(
                            'Your ticket to the\nDelta House\nHalloween party',
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Lottie.asset(
                        'assets/images/skull.json',
                        width: 90,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 147,
                height: 147,
                child: AspectRatio(
                  aspectRatio: 1 / 1,
                  child: _QrCodeDisplay(
                    content: _qrContent,
                  ),
                ),
              ),
              const SizedBox(height: 46),
              const Text(
                'See you on October 28th, 2023!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              SizedBox(
                height: 100,
                child: Lottie.asset('assets/images/bat.json'),
              ),
              const Text(
                'This is a part of your receipt to get into the\nDelta House party on October 28th, 2023.\nPlease do not delete the app, you will need this\nto get into the party and to use your gift.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  height: 1.3,
                  fontSize: 14,
                  fontWeight: FontWeight.w300,
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
              color: Color.fromRGBO(0x00, 0x00, 0x00, 0.5),
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
