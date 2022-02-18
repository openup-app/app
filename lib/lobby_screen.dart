import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:openup/api/users/profile.dart';
import 'package:openup/api/users/rekindle.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/api/lobby/lobby_api.dart';
import 'package:openup/widgets/notification_banner.dart';
import 'package:openup/widgets/theming.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

import 'widgets/home_button.dart';

part 'lobby_screen.freezed.dart';

/// Page on which you wait to be matched with another user.
class LobbyScreen extends StatefulWidget {
  final String host;
  final int socketPort;
  final bool video;
  final bool serious;
  final Purpose purpose;
  final void Function({
    required String rid,
    required List<Profile> profiles,
    required List<Rekindle> rekindles,
  }) onJoinCall;

  const LobbyScreen({
    Key? key,
    required this.host,
    required this.socketPort,
    required this.video,
    required this.serious,
    required this.purpose,
    required this.onJoinCall,
  }) : super(key: key);

  @override
  _LobbyScreenState createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen>
    with SingleTickerProviderStateMixin {
  late final LobbyApi _lobbyApi;

  late final StreamSubscription _subscription;
  late final AnimationController _animationController;
  bool _shouldHandleDisconnection = true;

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
      host: widget.host,
      socketPort: widget.socketPort,
      uid: FirebaseAuth.instance.currentUser!.uid,
      video: widget.video,
      serious: widget.serious,
      purpose: widget.purpose,
    );
    _subscription = _lobbyApi.eventStream.listen(_onLobbyEvent);
    _lobbyApi.connect();
  }

  void _onLobbyEvent(LobbyEvent event) {
    event.when(
      connectionError: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to connect to server'),
          ),
        );
        Navigator.of(context).pop();
      },
      disconnected: () {
        if (_shouldHandleDisconnection) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lost connection to server'),
            ),
          );
          Navigator.of(context).pop();
        }
      },
      penalized: (minutes) {
        setState(() => _shouldHandleDisconnection = false);
        final plural = minutes != 1;
        showTopSnackBar(
          context,
          IgnorePointer(
            child: CustomSnackBar.error(
              message:
                  'You have been penalized from serious mode for $minutes more minute${plural ? 's' : ''}',
              boxShadow: const [],
              textStyle: Theming.of(context).text.body.copyWith(fontSize: 18),
            ),
          ),
        );
        Navigator.of(context).pop();
      },
      joinCall: (rid, profiles, rekindles) {
        widget.onJoinCall(
          rid: rid,
          profiles: profiles,
          rekindles: rekindles,
        );
      },
    );
  }

  @override
  void dispose() {
    _subscription.cancel();
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
  final bool serious;
  LobbyScreenArguments({
    required this.video,
    required this.serious,
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
