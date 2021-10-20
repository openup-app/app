import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openup/api/lobby/lobby_api.dart';
import 'package:openup/api/users/preferences.dart';
import 'package:openup/api/users/profile.dart';
import 'package:openup/api/users/users_api.dart';
import 'package:openup/initial_loading_screen.dart';
import 'package:openup/preferences_screen.dart';
import 'package:openup/private_profile_screen.dart';
import 'package:openup/public_profile_edit_screen.dart';
import 'package:openup/public_profile_screen.dart';
import 'package:openup/rekindle_screen.dart';
import 'package:openup/video_call_screen.dart';
import 'package:openup/util/page_transition.dart';
import 'package:openup/voice_call_screen.dart';
import 'package:openup/solo_double_screen.dart';
import 'package:openup/lobby_screen.dart';
import 'package:openup/home_screen.dart';
import 'package:openup/forgot_password_screen.dart';
import 'package:openup/phone_verification_screen.dart';
import 'package:openup/sign_up_screen.dart';
import 'package:openup/solo_screen.dart';
import 'package:openup/widgets/male_female_connection_image.dart';
import 'package:openup/widgets/profile_drawer.dart';
import 'package:openup/widgets/theming.dart';

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
              colorScheme: const ColorScheme.light(
                primary: Color.fromARGB(0xFF, 0xFF, 0x71, 0x71),
                secondary: Color.fromARGB(0xAA, 0xFF, 0x71, 0x71),
              ),
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
                    builder: (_) => const InitialLoadingScreen(),
                  );
                case 'sign-up':
                  return _buildPageRoute(
                    settings: settings,
                    builder: (_) => const SignUpScreen(),
                  );
                case 'phone-verification':
                  final args = settings.arguments as CredentialVerification;
                  return _buildPageRoute<bool>(
                    settings: settings,
                    builder: (_) => PhoneVerificationScreen(
                      credentialVerification: args,
                    ),
                  );
                case 'forgot-password':
                  return _buildPageRoute(
                    settings: settings,
                    builder: (_) => const ForgotPasswordScreen(),
                  );
                case '/':
                  return _buildPageRoute(
                    settings: settings,
                    transitionsBuilder: topToBottomPageTransition,
                    builder: (_) => const HomeScreen(),
                  );
                case 'friends-solo-double':
                  return _buildPageRoute(
                    settings: settings,
                    builder: (context) {
                      return SoloDoubleScreenTheme(
                        themeData: const SoloDoubleScreenThemeData(
                          upperGradientInner:
                              Color.fromARGB(0xFF, 0xCE, 0xF6, 0xFF),
                          upperGradientOuter:
                              Color.fromARGB(0xFF, 0x1C, 0xC1, 0xE4),
                          lowerGradientInner:
                              Color.fromARGB(0xFF, 0xCE, 0xF6, 0xFF),
                          lowerGradientOuter:
                              Color.fromARGB(0xFF, 0x01, 0xAF, 0xD5),
                          profileButtonColor:
                              Color.fromARGB(0xFF, 0x11, 0x8E, 0xDD),
                        ),
                        child: SoloDoubleScreen(
                          labelUpper: 'meet\npeople',
                          labelLower: 'meet people\nwith friends',
                          imageUpper: const SizedBox(
                            height: 115,
                            child: MaleFemaleConnectionImage(),
                          ),
                          imageLower: SizedBox(
                            height: 100,
                            child: Image.asset(
                              'assets/images/friends_with_friends.png',
                              fit: BoxFit.fitHeight,
                            ),
                          ),
                          onPressedUpper: () =>
                              Navigator.of(context).pushNamed('friends-solo'),
                          onPressedLower: () {},
                        ),
                      );
                    },
                  );
                case 'friends-solo':
                  return _buildPageRoute(
                    settings: settings,
                    builder: (context) {
                      return SoloScreenTheme(
                        themeData: const SoloScreenThemeData(
                          backgroundGradientBottom:
                              Color.fromARGB(0xFF, 0xDD, 0xFB, 0xFF),
                          titleColor: Color.fromARGB(0xFF, 0x00, 0xD1, 0xFF),
                          titleShadowColor:
                              Color.fromARGB(0xAA, 0x00, 0xD1, 0xFF),
                          buttonColorTop:
                              Color.fromARGB(0xFF, 0x00, 0xB0, 0xD7),
                          buttonColorMiddle:
                              Color.fromARGB(0xFF, 0x5A, 0xC9, 0xEC),
                          buttonColorBottom:
                              Color.fromARGB(0xFF, 0x8C, 0xDD, 0xF6),
                          profileButtonColor:
                              Color.fromARGB(0xFF, 0x1C, 0xC1, 0xE4),
                        ),
                        child: SoloScreen(
                          label: 'meet people',
                          image: const SizedBox(
                            height: 115,
                            child: MaleFemaleConnectionImage(),
                          ),
                          onPressedVoiceCall: () =>
                              Navigator.of(context).pushNamed(
                            'friends-lobby',
                            arguments: LobbyScreenArguments(video: false),
                          ),
                          onPressedVideoCall: () =>
                              Navigator.of(context).pushNamed(
                            'friends-lobby',
                            arguments: LobbyScreenArguments(video: true),
                          ),
                          onPressedPreferences: () async {
                            final container =
                                ProviderScope.containerOf(context);
                            final usersApi = container.read(usersApiProvider);
                            final uid = FirebaseAuth.instance.currentUser?.uid;
                            if (uid != null) {
                              final preferences =
                                  await usersApi.getFriendsPreferences(uid);
                              Navigator.of(context).pushNamed(
                                'friends-preferences',
                                arguments: preferences,
                              );
                            }
                          },
                        ),
                      );
                    },
                  );
                case 'friends-preferences':
                  final args = settings.arguments as Preferences;
                  return _buildPageRoute(
                    settings: settings,
                    transitionsBuilder: bottomToTopPageTransition,
                    builder: (context) {
                      return PreferencesScreenTheme(
                        themeData: const PreferencesScreenThemeData(
                          backgroundGradientBottom:
                              Color.fromARGB(0xFF, 0x9E, 0xD5, 0xE2),
                          titleColor: Color.fromARGB(0xFF, 0x00, 0xD1, 0xFF),
                          titleShadowColor:
                              Color.fromARGB(0xAA, 0x00, 0xD1, 0xFF),
                          backArrowColor:
                              Color.fromARGB(0xFF, 0x89, 0xDE, 0xFF),
                          profileButtonColor:
                              Color.fromARGB(0xFF, 0x89, 0xDE, 0xFF),
                        ),
                        child: PreferencesScreen(
                          initialPreferences: args,
                          title: 'meet people',
                          image: const SizedBox(
                            width: 125,
                            height: 40,
                            child: MaleFemaleConnectionImageApart(),
                          ),
                          updatePreferences: (usersApi, uid, preferences) =>
                              usersApi.updateFriendsPreferences(
                                  uid, preferences),
                        ),
                      );
                    },
                  );
                case 'friends-lobby':
                  final args = settings.arguments as LobbyScreenArguments;
                  return _buildPageRoute(
                    settings: settings,
                    builder: (context) {
                      return LobbyScreenTheme(
                        themeData: const LobbyScreenThemeData(
                          backgroundColors: [
                            Color.fromARGB(0xFF, 0xB3, 0xE3, 0xFB),
                            Color.fromARGB(0xFF, 0x6C, 0xBA, 0xDC),
                            Color.fromARGB(0xFF, 0x0B, 0x92, 0xD2),
                            Color.fromARGB(0xFF, 0x18, 0x76, 0xA4),
                            Color.fromARGB(0xFF, 0x37, 0x98, 0xD8),
                            Color.fromARGB(0xFF, 0x0B, 0x92, 0xD2),
                          ],
                        ),
                        child: LobbyScreen(
                          lobbyHost: _tempLobbyHost,
                          signalingHost: _tempSignalingHost,
                          video: args.video,
                          purpose: Purpose.friends,
                          onStartCall: ({
                            required bool initiator,
                            required List<PublicProfile> profiles,
                          }) {
                            final route = args.video
                                ? 'friends-video-call'
                                : 'friends-voice-call';
                            Navigator.of(context).pushNamed(
                              route,
                              arguments: CallPageArguments(
                                uid: FirebaseAuth.instance.currentUser!.uid,
                                initiator: initiator,
                                profiles: profiles,
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                case 'friends-voice-call':
                  final args = settings.arguments as CallPageArguments;
                  return _buildPageRoute(
                    settings: settings,
                    transitionsBuilder: fadePageTransition,
                    builder: (_) {
                      return VoiceCallScreen(
                        uid: args.uid,
                        signalingHost: _tempSignalingHost,
                        initiator: args.initiator,
                        profiles: args.profiles,
                      );
                    },
                  );
                case 'friends-video-call':
                  final args = settings.arguments as CallPageArguments;
                  return _buildPageRoute(
                    settings: settings,
                    transitionsBuilder: fadePageTransition,
                    builder: (_) {
                      return VideoCallScreen(
                        uid: args.uid,
                        signalingHost: _tempSignalingHost,
                        initiator: args.initiator,
                        profiles: args.profiles,
                      );
                    },
                  );
                case 'dating-solo-double':
                  return _buildPageRoute(
                    settings: settings,
                    builder: (context) {
                      return SoloDoubleScreenTheme(
                        themeData: const SoloDoubleScreenThemeData(
                          upperGradientInner:
                              Color.fromARGB(0xFF, 0xFF, 0xE8, 0xE8),
                          upperGradientOuter:
                              Color.fromARGB(0xFF, 0xFF, 0xB2, 0xB2),
                          lowerGradientInner:
                              Color.fromARGB(0xFF, 0xFF, 0xE6, 0xE6),
                          lowerGradientOuter:
                              Color.fromARGB(0xFF, 0xEE, 0x87, 0x87),
                          profileButtonColor:
                              Color.fromARGB(0xFF, 0xFF, 0x8A, 0x8A),
                          homeButtonColor:
                              Color.fromARGB(0xFF, 0xDD, 0x0F, 0x0F),
                        ),
                        child: SoloDoubleScreen(
                          labelUpper: 'blind\ndate',
                          labelLower: 'double\ndate',
                          imageUpper: SizedBox(
                            height: 120,
                            child: Image.asset(
                              'assets/images/heart.png',
                              fit: BoxFit.fitHeight,
                            ),
                          ),
                          imageLower: SizedBox(
                            height: 160,
                            child: Image.asset(
                              'assets/images/double_hearts.png',
                              fit: BoxFit.fitHeight,
                            ),
                          ),
                          onPressedUpper: () =>
                              Navigator.of(context).pushNamed('dating-solo'),
                          onPressedLower: () {},
                        ),
                      );
                    },
                  );
                case 'dating-solo':
                  return _buildPageRoute(
                    settings: settings,
                    builder: (context) {
                      return SoloScreenTheme(
                        themeData: const SoloScreenThemeData(
                          backgroundGradientBottom:
                              Color.fromARGB(0xFF, 0xFF, 0xE2, 0xE2),
                          titleColor: Color.fromARGB(0xFF, 0xFD, 0x65, 0x65),
                          titleShadowColor:
                              Color.fromARGB(0xAA, 0xF0, 0x59, 0x59),
                          buttonColorTop:
                              Color.fromARGB(0xFF, 0xFF, 0x77, 0x77),
                          buttonColorMiddle:
                              Color.fromARGB(0xFF, 0xFF, 0x88, 0x88),
                          buttonColorBottom:
                              Color.fromARGB(0xFF, 0xF6, 0x9E, 0x9E),
                          profileButtonColor:
                              Color.fromARGB(0xFF, 0xFF, 0x8A, 0x8A),
                          homeButtonColor:
                              Color.fromARGB(0xFF, 0xDD, 0x0F, 0x0F),
                        ),
                        child: SoloScreen(
                          label: 'blind date',
                          image: SizedBox(
                            height: 120,
                            child: Image.asset(
                              'assets/images/heart.png',
                              fit: BoxFit.fitHeight,
                            ),
                          ),
                          onPressedVoiceCall: () =>
                              Navigator.of(context).pushNamed(
                            'dating-lobby',
                            arguments: LobbyScreenArguments(video: false),
                          ),
                          onPressedVideoCall: () =>
                              Navigator.of(context).pushNamed(
                            'dating-lobby',
                            arguments: LobbyScreenArguments(video: true),
                          ),
                          onPressedPreferences: () async {
                            final container =
                                ProviderScope.containerOf(context);
                            final usersApi = container.read(usersApiProvider);
                            final uid = FirebaseAuth.instance.currentUser?.uid;
                            if (uid != null) {
                              final preferences =
                                  await usersApi.getDatingPreferences(uid);
                              Navigator.of(context).pushNamed(
                                'dating-preferences',
                                arguments: preferences,
                              );
                            }
                          },
                        ),
                      );
                    },
                  );
                case 'dating-preferences':
                  final args = settings.arguments as Preferences;
                  return _buildPageRoute(
                    settings: settings,
                    transitionsBuilder: bottomToTopPageTransition,
                    builder: (context) {
                      return PreferencesScreenTheme(
                        themeData: const PreferencesScreenThemeData(
                          backgroundGradientBottom:
                              Color.fromARGB(0xFF, 0xFF, 0xDD, 0xDD),
                          titleColor: Color.fromARGB(0xFF, 0xFF, 0x7A, 0x7A),
                          titleShadowColor:
                              Color.fromARGB(0xAA, 0xF0, 0x59, 0x59),
                          backArrowColor:
                              Color.fromARGB(0xFF, 0xFD, 0x89, 0x89),
                          profileButtonColor:
                              Color.fromARGB(0xFF, 0xFF, 0x8A, 0x8A),
                        ),
                        child: PreferencesScreen(
                          initialPreferences: args,
                          title: 'blind date',
                          image: SizedBox(
                            width: 125,
                            height: 40,
                            child: Image.asset('assets/images/heart.png'),
                          ),
                          updatePreferences: (usersApi, uid, preferences) =>
                              usersApi.updateDatingPreferences(
                                  uid, preferences),
                        ),
                      );
                    },
                  );
                case 'dating-lobby':
                  final args = settings.arguments as LobbyScreenArguments;
                  return _buildPageRoute(
                    settings: settings,
                    builder: (context) {
                      return LobbyScreenTheme(
                        themeData: const LobbyScreenThemeData(
                          backgroundColors: [
                            Color.fromARGB(0xFF, 0xFB, 0x8B, 0x8B),
                            Color.fromARGB(0xFF, 0xFB, 0x6B, 0x6B),
                            Color.fromARGB(0xFF, 0xFB, 0x43, 0x43),
                            Color.fromARGB(0xFF, 0xFA, 0x3B, 0x3B),
                            Color.fromARGB(0xFF, 0xFB, 0x23, 0x23),
                            Color.fromARGB(0xFF, 0xB3, 0x03, 0x03),
                          ],
                          homeButtonColor: Colors.white,
                        ),
                        child: LobbyScreen(
                          lobbyHost: _tempLobbyHost,
                          signalingHost: _tempSignalingHost,
                          video: args.video,
                          purpose: Purpose.dating,
                          onStartCall: ({
                            required bool initiator,
                            required List<PublicProfile> profiles,
                          }) {
                            // TOOD: Proper routes
                            final route = args.video
                                ? 'friends-video-call'
                                : 'friends-voice-call';
                            Navigator.of(context).pushNamed(
                              route,
                              arguments: CallPageArguments(
                                uid: FirebaseAuth.instance.currentUser!.uid,
                                initiator: initiator,
                                profiles: profiles,
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                case 'rekindle':
                  final args = settings.arguments as RekindleScreenArguments;
                  return _buildPageRoute(
                    settings: settings,
                    builder: (context) {
                      return RekindleScreen(
                        profiles: args.profiles,
                        index: args.index,
                      );
                    },
                  );
                case 'public-profile':
                  return _buildPageRoute(
                    settings: settings,
                    builder: (_) => const PublicProfileScreen(),
                  );
                case 'public-profile-edit':
                  return _buildPageRoute(
                    settings: settings,
                    builder: (_) => const PublicProfileEditScreen(),
                  );
                case 'private-profile':
                  final args = settings.arguments as PrivateProfile;
                  return _buildPageRoute(
                    settings: settings,
                    builder: (_) {
                      return PrivateProfileScreen(
                        initialProfile: args,
                      );
                    },
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
    required WidgetBuilder builder,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionsBuilder: transitionsBuilder ?? sideAnticipatePageTransition,
      transitionDuration: const Duration(milliseconds: 500),
      reverseTransitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (_, __, ___) {
        return Scaffold(
          body: Builder(builder: builder),
          endDrawerEnableOpenDragGesture: false,
          endDrawer: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 6.0,
              sigmaY: 6.0,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 32,
                  ),
                ],
              ),
              child: Container(
                color: Colors.white.withOpacity(0.6),
                child: const ProfileDrawer(),
              ),
            ),
          ),
        );
      },
    );
  }
}
