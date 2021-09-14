import 'package:flutter/material.dart';
import 'package:openup/video_call_screen.dart';
import 'package:openup/page_transition.dart';
import 'package:openup/voice_call_screen.dart';
import 'package:openup/friends_home_screen.dart';
import 'package:openup/lobby_screen.dart';
import 'package:openup/home_screen.dart';
import 'package:openup/forgot_password_screen.dart';
import 'package:openup/phone_verification_screen.dart';
import 'package:openup/sign_up/sign_up_screen.dart';
import 'package:openup/solo_screen.dart';
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
                  final args = settings.arguments as LobbyScreenArguments;
                  return _buildPageRoute(
                    settings: settings,
                    child: LobbyScreen(
                      applicationHost: _tempApplicationHost,
                      signalingHost: _tempSignalingHost,
                      video: args.video,
                    ),
                  );
                case 'friends-voice-call':
                  final args = settings.arguments as CallPageArguments;
                  return _buildPageRoute(
                    settings: settings,
                    transitionsBuilder: fadePageTransition,
                    child: VoiceCallScreen(
                      uid: args.uid,
                      signalingHost: _tempSignalingHost,
                      initiator: args.initiator,
                    ),
                  );
                case 'friends-video-call':
                  final args = settings.arguments as CallPageArguments;
                  return _buildPageRoute(
                    settings: settings,
                    transitionsBuilder: fadePageTransition,
                    child: VideoCallScreen(
                      uid: args.uid,
                      signalingHost: _tempSignalingHost,
                      initiator: args.initiator,
                    ),
                  );
                default:
                  throw 'Route not found ${settings.name}';
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
