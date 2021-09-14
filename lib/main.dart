import 'package:flutter/material.dart';
import 'package:openup/page_transition.dart';
import 'package:openup/voice_call_screen.dart';
import 'package:openup/friends_home_screen.dart';
import 'package:openup/friends_lobby_screen.dart';
import 'package:openup/home_screen.dart';
import 'package:openup/lobby_page.dart';
import 'package:openup/forgot_password_screen.dart';
import 'package:openup/phone_verification_screen.dart';
import 'package:openup/sign_up/sign_up_screen.dart';
import 'package:openup/solo_friends_screen.dart';
import 'package:openup/theming.dart';

const _tempApplicationHost = '192.168.1.118:8080';
const _tempSignalingHost = '192.168.1.118:8081';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return Theming(
      child: Builder(
        builder: (context) {
          return MaterialApp(
            theme: ThemeData(
              fontFamily: 'Myriad',
              iconTheme: const IconThemeData(
                color: Colors.white,
              ),
            ),
            initialRoute: 'sign-up',
            onGenerateRoute: (settings) {
              switch (settings.name) {
                case 'sign-up':
                  return _buildPageRoute(
                    settings: settings,
                    child: const SignUpScreen(),
                  );
                case 'phone-verification':
                  return _buildPageRoute(
                    settings: settings,
                    child: const PhoneVerificationScreen(),
                  );
                case 'forgot-password':
                  return _buildPageRoute(
                    settings: settings,
                    child: const ForgotPasswordScreen(),
                  );
                case '/':
                  return _buildPageRoute(
                    settings: settings,
                    transitionsBuilder: topToBottomPageTransition,
                    child: const HomeScreen(),
                  );
                case 'friends':
                  return _buildPageRoute(
                    settings: settings,
                    child: const FriendsHomeScreen(),
                  );
                case 'friends-solo':
                  return _buildPageRoute(
                    settings: settings,
                    child: const SoloFriends(),
                  );
                case 'friends-lobby':
                  return _buildPageRoute(
                    settings: settings,
                    child: const FriendsLobbyScreen(),
                  );
                case 'friends-voice-call':
                  return _buildPageRoute(
                    settings: settings,
                    transitionsBuilder: fadePageTransition,
                    child: const VoiceCallScreen(),
                  );
                default:
                  return _buildPageRoute(
                    settings: settings,
                    child: const SignUpScreen(),
                  );
              }
            },
          );
        },
      ),
    );
  }

  PageRoute _buildPageRoute({
    required RouteSettings settings,
    PageTransitionBuilder? transitionsBuilder,
    required Widget child,
  }) {
    return PageRouteBuilder(
      settings: settings,
      transitionsBuilder: transitionsBuilder ?? sideAnticipatePageTransition,
      transitionDuration: const Duration(milliseconds: 750),
      reverseTransitionDuration: const Duration(milliseconds: 650),
      pageBuilder: (_, __, ___) => Scaffold(body: child),
    );
  }
}

class MenuPage extends StatelessWidget {
  const MenuPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meet people'),
      ),
      body: Center(
        child: OutlinedButton.icon(
          label: const Text('Talk to someone new'),
          icon: const Icon(Icons.call),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) {
                  return const LobbyPage(
                    applicationHost: _tempApplicationHost,
                    signalingHost: _tempSignalingHost,
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
