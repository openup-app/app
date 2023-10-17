import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/gradient_mask.dart';

class WaitlistPage extends ConsumerStatefulWidget {
  final String uid;
  final String email;

  const WaitlistPage({
    super.key,
    required this.uid,
    required this.email,
  });

  @override
  ConsumerState<WaitlistPage> createState() => _WaitlistPageState();
}

class _WaitlistPageState extends ConsumerState<WaitlistPage> {
  bool _giftOpened = false;

  @override
  void initState() {
    super.initState();
    _updateWaitlist();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Lottie.asset(
            'assets/images/stars_background.json',
            fit: BoxFit.cover,
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Lottie.asset(
              'assets/images/lightning.json',
              fit: BoxFit.cover,
            ),
          ),
          Column(
            children: [
              SizedBox(height: MediaQuery.of(context).padding.top),
              const SizedBox(height: 40),
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
              const SizedBox(height: 12),
              const Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(left: 27),
                  child: Text(
                    'See you on October 28th, 2023!',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              RichText(
                textAlign: TextAlign.center,
                text: const TextSpan(
                  style: TextStyle(
                    height: 1.4,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                  children: [
                    TextSpan(
                        text: 'We will be giving you access to this app\n'),
                    TextSpan(
                      text: 'Plus One',
                      style: TextStyle(
                        color: Color.fromRGBO(0xFF, 0x00, 0x00, 1.0),
                      ),
                    ),
                    TextSpan(
                        text:
                            ' very soon! In the meantime\nenjoy your Plus One entry gift!'),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                height: 219,
                child: Button(
                  onPressed: _goToGiftPage,
                  child: Column(
                    children: [
                      Expanded(
                        child: !_giftOpened
                            ? Transform.scale(
                                scale: 1.6,
                                child: Lottie.asset(
                                  'assets/images/present.json',
                                ),
                              )
                            : Transform.scale(
                                scale: 1.0,
                                child: Lottie.asset(
                                  'assets/images/photo_session.json',
                                ),
                              ),
                      ),
                      Container(
                        width: 187,
                        height: 39,
                        margin: const EdgeInsets.all(8),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.all(
                            Radius.circular(6),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              if (!_giftOpened) ...const [
                                Color.fromRGBO(0xCB, 0x00, 0x00, 1.0),
                                Color.fromRGBO(0xF9, 0x68, 0x17, 1.0),
                              ] else ...const [
                                Color.fromRGBO(0xC6, 0x03, 0xB1, 1.0),
                                Color.fromRGBO(0xC0, 0x15, 0xF4, 1.0),
                              ]
                            ],
                          ),
                        ),
                        child: !_giftOpened
                            ? const Text(
                                'My Plus One Welcome Gift',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w300,
                                ),
                              )
                            : const Text(
                                'Glamour Shot Details',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 35.0),
                child: Text(
                  'Plus One will unlock shortly after the  Delta House party on October 28th, 2023. Please do not delete the app, you will need this to get into the party and to use your gift.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
              const SizedBox(height: 44),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        ],
      ),
    );
  }

  void _updateWaitlist() async {
    final api = ref.read(apiProvider);
    await api.updateWaitlist(widget.uid, widget.email, null);
  }

  void _goToGiftPage() {
    setState(() => _giftOpened = true);
    context.pushNamed(
      'gift',
      queryParameters: {
        'uid': widget.uid,
        'email': widget.email,
      },
    );
  }
}
