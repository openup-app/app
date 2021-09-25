import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/api/lobby/lobby_api.dart';
import 'package:openup/video_call_screen.dart';
import 'package:openup/widgets/notification_banner.dart';
import 'package:openup/widgets/theming.dart';

import 'widgets/home_button.dart';

/// Page on which you wait to be matched with another user.
class LobbyScreen extends StatefulWidget {
  final String lobbyHost;
  final String signalingHost;
  final bool video;

  const LobbyScreen({
    Key? key,
    required this.lobbyHost,
    required this.signalingHost,
    required this.video,
  }) : super(key: key);

  @override
  _LobbyScreenState createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen>
    with SingleTickerProviderStateMixin {
  late final String _uid;
  late final LobbyApi _lobbyApi;

  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    );
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController.forward(from: 0.0);
      }
    });
    _animationController.forward();

    _uid = Random().nextInt(1000000).toString().padLeft(7, '0');
    _lobbyApi = LobbyApi(
      host: widget.lobbyHost,
      uid: _uid,
      video: widget.video,
      onMakeCall: () => _startCall(initiator: true),
      onReceiveCall: () => _startCall(initiator: false),
      onConnectionError: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to connect to server'),
          ),
        );
        Navigator.of(context).pop();
      },
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _lobbyApi.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const colors = [
      Color.fromARGB(0xFF, 0xB3, 0xE3, 0xFB),
      Color.fromARGB(0xFF, 0x6C, 0xBA, 0xDC),
      Color.fromARGB(0xFF, 0x0B, 0x92, 0xD2),
      Color.fromARGB(0xFF, 0x18, 0x76, 0xA4),
      Color.fromARGB(0xFF, 0x37, 0x98, 0xD8),
      Color.fromARGB(0xFF, 0x0B, 0x92, 0xD2),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  final maxFractionalDuration = 1.0 / colors.length;
                  final value =
                      (_animationController.value % maxFractionalDuration) /
                          maxFractionalDuration;
                  final index =
                      _animationController.value ~/ maxFractionalDuration;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: constraints.maxWidth *
                            (index.isEven ? value : 1 - value),
                        color: colors[(2 * (index ~/ 2) + 1) % colors.length],
                      ),
                      Container(
                        width: constraints.maxWidth *
                            (index.isOdd ? value : 1 - value),
                        color: colors[(2 * ((index + 1) ~/ 2)) % colors.length],
                      ),
                    ],
                  );
                },
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/title.png',
                    width: 150,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'please wait while we find\nsomeone new...',
                    textAlign: TextAlign.center,
                    style: Theming.of(context).text.body.copyWith(fontSize: 16),
                  ),
                ],
              ),
              const Positioned(
                right: 0,
                bottom: 100,
                child: NotificationBanner(
                  contents:
                      'Helpful Tip: Adjust preferences to find your perfect match',
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                left: MediaQuery.of(context).padding.left + 16,
                child: Button(
                  onPressed: Navigator.of(context).pop,
                  child: const Icon(Icons.close),
                ),
              ),
              Positioned(
                right: MediaQuery.of(context).padding.right + 16,
                bottom: MediaQuery.of(context).padding.bottom + 16,
                child: const HomeButton(),
              ),
            ],
          ),
        );
      },
    );
  }

  void _startCall({required bool initiator}) {
    final route = widget.video ? 'friends-video-call' : 'friends-voice-call';
    Navigator.of(context).pushNamed(
      route,
      arguments: CallPageArguments(
        uid: _uid,
        initiator: initiator,
      ),
    );
  }
}

class LobbyScreenArguments {
  final bool video;
  LobbyScreenArguments({
    required this.video,
  });
}
