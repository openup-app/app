import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/widgets/button.dart';

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
          Column(
            children: [
              SizedBox(height: MediaQuery.of(context).padding.top),
              const Spacer(),
              const Text(
                'THANK\nYOU',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.w900,
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
                    TextSpan(text: 'We will be giving you access to '),
                    TextSpan(
                      text: 'Plus One',
                      style: TextStyle(
                        color: Color.fromRGBO(0xFF, 0x00, 0x00, 1.0),
                      ),
                    ),
                    TextSpan(
                        text: '\nvery soon! In the meantime enjoy your gift'),
                  ],
                ),
              ),
              SizedBox(
                height: 216,
                child: Row(
                  children: [
                    const SizedBox(width: 23),
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(
                            child: !_giftOpened
                                ? Transform.scale(
                                    scale: 1.2,
                                    child: Lottie.asset(
                                      'assets/images/present.json',
                                    ),
                                  )
                                : Transform.scale(
                                    scale: 1.4,
                                    child: Lottie.asset(
                                      'assets/images/photo_session.json',
                                    ),
                                  ),
                          ),
                          Button(
                            onPressed: _goToGiftPage,
                            child: Container(
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
                                      'My Welcome Gift',
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
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 32),
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(
                            child: Lottie.asset(
                              'assets/images/ticket.json',
                            ),
                          ),
                          Button(
                            onPressed: _goToTicketPage,
                            child: Container(
                              height: 39,
                              margin: const EdgeInsets.all(8),
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.all(
                                  Radius.circular(6),
                                ),
                              ),
                              child: const Text(
                                'Delta House Party Ticket',
                                maxLines: 1,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w300,
                                    color: Colors.black),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 23),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Spacer(),
              const Text(
                'Plus One will unlock shortly after the Delta\nHouse party on October 28th, 2023',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(height: 70),
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

  void _goToTicketPage() {
    context.pushNamed(
      'ticket',
      queryParameters: {
        'uid': widget.uid,
        'email': widget.email,
      },
    );
  }
}
