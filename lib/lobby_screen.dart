import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/api/lobby/lobby_api.dart';
import 'package:openup/widgets/notification_banner.dart';
import 'package:openup/widgets/theming.dart';

import 'widgets/home_button.dart';

part 'lobby_screen.freezed.dart';

/// Page on which you wait to be matched with another user.
class LobbyScreen extends StatefulWidget {
  final String lobbyHost;
  final String signalingHost;
  final bool video;
  final void Function({required bool initiator}) onStartCall;

  const LobbyScreen({
    Key? key,
    required this.lobbyHost,
    required this.signalingHost,
    required this.video,
    required this.onStartCall,
  }) : super(key: key);

  @override
  _LobbyScreenState createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen>
    with SingleTickerProviderStateMixin {
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

    _lobbyApi = LobbyApi(
      host: widget.lobbyHost,
      uid: FirebaseAuth.instance.currentUser!.uid,
      video: widget.video,
      onMakeCall: () => widget.onStartCall(initiator: true),
      onReceiveCall: () => widget.onStartCall(initiator: false),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final colors = LobbyScreenTheme.of(context).backgroundColors;
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
                child: HomeButton(
                  color: LobbyScreenTheme.of(context).homeButtonColor,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class LobbyScreenArguments {
  final bool video;
  LobbyScreenArguments({
    required this.video,
  });
}

class LobbyScreenTheme extends InheritedWidget {
  final LobbyScreenThemeData themeData;

  const LobbyScreenTheme({
    Key? key,
    required Widget child,
    required this.themeData,
  }) : super(key: key, child: child);

  static LobbyScreenThemeData of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<LobbyScreenTheme>()!
        .themeData;
  }

  @override
  bool updateShouldNotify(LobbyScreenTheme oldWidget) =>
      oldWidget.themeData != themeData;
}

@freezed
class LobbyScreenThemeData with _$LobbyScreenThemeData {
  const factory LobbyScreenThemeData({
    required List<Color> backgroundColors,
    Color? homeButtonColor,
  }) = _LobbyScreenThemeData;
}
