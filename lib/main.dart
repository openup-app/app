import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openup/api/users/users_api.dart';
import 'package:openup/initial_loading.dart';
import 'package:openup/preferences.dart';
import 'package:openup/preferences_screen.dart';
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

const _tempLobbyHost = 'ec2-54-81-84-156.compute-1.amazonaws.com:8080';
const _tempSignalingHost = 'ec2-54-81-84-156.compute-1.amazonaws.com:8081';
const _tempUsersHost = 'ec2-54-81-84-156.compute-1.amazonaws.com:8082';

void main() {
  runApp(
    const ProviderScope(
      child: OpenupApp(),
    ),
  );
}

class OpenupApp extends StatefulWidget {
  const OpenupApp({Key? key}) : super(key: key);

  @override
  State<OpenupApp> createState() => _OpenupAppState();
}

class _OpenupAppState extends State<OpenupApp> {
  @override
  void initState() {
    super.initState();
    initUsersApi(host: _tempUsersHost);

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

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
            initialRoute: 'initial-loading',
            onGenerateRoute: (settings) {
              switch (settings.name) {
                case 'initial-loading':
                  return _buildPageRoute(
                    settings: settings,
                    transitionsBuilder: fadePageTransition,
                    child: const InitialLoading(),
                  );
                case 'sign-up':
                  return _buildPageRoute(
                    settings: settings,
                    child: const SignUpScreen(),
                  );
                case 'phone-verification':
                  final args = settings.arguments as CredentialVerification;
                  return _buildPageRoute<bool>(
                    settings: settings,
                    child: PhoneVerificationScreen(
                      credentialVerification: args,
                    ),
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
                case 'friends-preferences':
                  final args = settings.arguments as Preferences;
                  return _buildPageRoute(
                    settings: settings,
                    transitionsBuilder: bottomToTopPageTransition,
                    child: PreferencesScreen(
                      initialPreferences: args,
                    ),
                  );
                case 'friends-lobby':
                  final args = settings.arguments as LobbyScreenArguments;
                  return _buildPageRoute(
                    settings: settings,
                    child: LobbyScreen(
                      lobbyHost: _tempLobbyHost,
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

  PageRoute _buildPageRoute<T>({
    required RouteSettings settings,
    PageTransitionBuilder? transitionsBuilder,
    required Widget child,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionsBuilder: transitionsBuilder ?? sideAnticipatePageTransition,
      transitionDuration: const Duration(milliseconds: 750),
      reverseTransitionDuration: const Duration(milliseconds: 650),
      pageBuilder: (_, __, ___) => Scaffold(body: child),
    );
  }
}
