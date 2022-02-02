import 'dart:async';
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openup/api/lobby/lobby_api.dart';
import 'package:openup/api/online_users/online_users_api.dart';
import 'package:openup/api/users/preferences.dart';
import 'package:openup/api/users/profile.dart';
import 'package:openup/api/users/rekindle.dart';
import 'package:openup/api/users/users_api.dart';
import 'package:openup/call_screen.dart';
import 'package:openup/chat_screen.dart';
import 'package:openup/connections_screen.dart';
import 'package:openup/error_screen.dart';
import 'package:openup/initial_loading_screen.dart';
import 'package:openup/preferences_screen.dart';
import 'package:openup/private_profile_screen.dart';
import 'package:openup/public_profile_edit_screen.dart';
import 'package:openup/public_profile_screen.dart';
import 'package:openup/rekindle_screen.dart';
import 'package:openup/report_screen.dart';
import 'package:openup/sign_up_audio_bio_screen.dart';
import 'package:openup/sign_up_info_screen.dart';
import 'package:openup/sign_up_photos_screen.dart';
import 'package:openup/sign_up_private_profile_screen.dart';
import 'package:openup/sign_up_welcome_info.dart';
import 'package:openup/util/page_transition.dart';
import 'package:openup/solo_double_screen.dart';
import 'package:openup/lobby_screen.dart';
import 'package:openup/home_screen.dart';
import 'package:openup/forgot_password_screen.dart';
import 'package:openup/phone_verification_screen.dart';
import 'package:openup/sign_up_screen.dart';
import 'package:openup/menu_screen.dart';
import 'package:openup/voice_call_screen_content.dart';
import 'package:openup/widgets/account_settings_screen.dart';
import 'package:openup/widgets/connections_list.dart';
import 'package:openup/widgets/contact_us_screen.dart';
import 'package:openup/widgets/male_female_connection_image.dart';
import 'package:openup/widgets/profile_drawer.dart';
import 'package:openup/widgets/system_ui_styling.dart';
import 'package:openup/widgets/theming.dart';

const host = 'ec2-54-156-60-224.compute-1.amazonaws.com';
const webPort = 8080;
const socketPort = 8081;

final navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(
    const ProviderScope(
      child: OpenupApp(),
    ),
  );
}

class OpenupApp extends ConsumerStatefulWidget {
  const OpenupApp({Key? key}) : super(key: key);

  @override
  _OpenupAppState createState() => _OpenupAppState();
}

class _OpenupAppState extends ConsumerState<OpenupApp> {
  bool _loggedIn = false;
  StreamSubscription? _authStateSubscription;
  OnlineUsersApi? _onlineUsersApi;
  final _routeObserver = RouteObserver<PageRoute>();

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    Firebase.initializeApp().whenComplete(() {
      _authStateSubscription =
          FirebaseAuth.instance.authStateChanges().listen((user) {
        final loggedIn = user != null;
        if (_loggedIn != loggedIn) {
          setState(() => _loggedIn = loggedIn);
          if (loggedIn && user != null) {
            _onlineUsersApi?.dispose();
            _onlineUsersApi = OnlineUsersApi(
              host: host,
              port: socketPort,
              uid: user.uid,
              onConnectionError: () {},
            );
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    _onlineUsersApi?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theming(
      child: Builder(
        builder: (context) {
          return MaterialApp(
            navigatorKey: navigatorKey,
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
            navigatorObservers: [_routeObserver],
            initialRoute: '/',
            onGenerateRoute: (settings) {
              switch (settings.name) {
                case '/':
                  return _buildPageRoute(
                    settings: settings,
                    transitionsBuilder: fadePageTransition,
                    builder: (_) {
                      return const CurrentRouteSystemUiStyling.dark(
                        child: InitialLoadingScreen(),
                      );
                    },
                  );
                case 'error':
                  return _buildPageRoute(
                    settings: settings,
                    transitionsBuilder: fadePageTransition,
                    builder: (_) {
                      return const CurrentRouteSystemUiStyling.dark(
                        child: ErrorScreen(),
                      );
                    },
                  );
                case 'sign-up':
                  return _buildPageRoute(
                    settings: settings,
                    builder: (_) {
                      return const CurrentRouteSystemUiStyling.dark(
                        child: SignUpScreen(),
                      );
                    },
                  );
                case 'phone-verification':
                  final args = settings.arguments as CredentialVerification;
                  return _buildPageRoute<bool>(
                    settings: settings,
                    builder: (_) {
                      return CurrentRouteSystemUiStyling.dark(
                        child: PhoneVerificationScreen(
                          credentialVerification: args,
                        ),
                      );
                    },
                  );
                case 'forgot-password':
                  return _buildPageRoute(
                    settings: settings,
                    builder: (_) {
                      return const CurrentRouteSystemUiStyling.dark(
                        child: ForgotPasswordScreen(),
                      );
                    },
                  );
                case 'sign-up-info':
                  return _buildPageRoute(
                    settings: settings,
                    builder: (_) {
                      return const CurrentRouteSystemUiStyling.dark(
                        child: SignUpInfoScreen(),
                      );
                    },
                  );
                case 'sign-up-private-profile':
                  return _buildPageRoute(
                    settings: settings,
                    builder: (_) {
                      return const CurrentRouteSystemUiStyling.dark(
                        child: SignUpPrivateProfileScreen(),
                      );
                    },
                  );
                case 'sign-up-photos':
                  return _buildPageRoute(
                    settings: settings,
                    builder: (_) {
                      return const CurrentRouteSystemUiStyling.dark(
                        child: SignUpPhotosScreen(),
                      );
                    },
                  );
                case 'sign-up-audio-bio':
                  return _buildPageRoute(
                    settings: settings,
                    builder: (_) {
                      return const CurrentRouteSystemUiStyling.dark(
                        child: SignUpAudioBioScreen(),
                      );
                    },
                  );
                case 'sign-up-welcome-info':
                  return _buildPageRoute(
                    settings: settings,
                    builder: (_) {
                      return const CurrentRouteSystemUiStyling.light(
                        child: SignUpWelcomeInfoScreen(),
                      );
                    },
                  );
                case 'home':
                  return _buildPageRoute(
                    settings: settings,
                    transitionsBuilder: fadePageTransition,
                    builder: (_) => const CurrentRouteSystemUiStyling.light(
                      child: HomeScreen(),
                    ),
                  );
                case 'friends-solo-double':
                  return _buildPageRoute(
                    settings: settings,
                    builder: (context) {
                      return CurrentRouteSystemUiStyling.light(
                        child: SoloDoubleScreenTheme(
                          themeData: const SoloDoubleScreenThemeData(
                            upperGradients: [
                              RadialGradient(
                                colors: [
                                  Color.fromRGBO(0xB1, 0xEF, 0xFD, 1.0),
                                  Color.fromRGBO(0xCA, 0xF5, 0xFF, 0.0),
                                ],
                              ),
                              RadialGradient(
                                colors: [
                                  Color.fromRGBO(0x14, 0xCE, 0xFF, 0.5),
                                  Color.fromRGBO(0x00, 0xB3, 0xDA, 0.5),
                                ],
                              ),
                              // Solid color
                              LinearGradient(
                                colors: [
                                  Color.fromRGBO(0x81, 0xE8, 0xFF, 1.0),
                                  Color.fromRGBO(0x81, 0xE8, 0xFF, 1.0),
                                ],
                              ),
                            ],
                            lowerGradients: [
                              RadialGradient(
                                colors: [
                                  Color.fromRGBO(0xA6, 0xEF, 0xFF, 1.0),
                                  Color.fromRGBO(0xCA, 0xF5, 0xFF, 0.0),
                                ],
                              ),
                              RadialGradient(
                                colors: [
                                  Color.fromRGBO(0x34, 0xD5, 0xFF, 0.5),
                                  Color.fromRGBO(0x00, 0xB3, 0xDA, 0.5),
                                ],
                              ),
                              // Solid color
                              LinearGradient(
                                colors: [
                                  Color.fromRGBO(0x02, 0xAB, 0xD0, 1.0),
                                  Color.fromRGBO(0x02, 0xAB, 0xD0, 1.0),
                                ],
                              ),
                            ],
                            profileButtonColor:
                                Color.fromARGB(0xFF, 0x11, 0x8E, 0xDD),
                          ),
                          child: SoloDoubleScreen(
                            labelUpper: 'meet\npeople',
                            labelLower: 'meet people\nwith friends',
                            imageUpper: Image.asset(
                              'assets/images/friends.gif',
                              height: 115,
                            ),
                            imageLower: SizedBox(
                              height: 100,
                              child: Image.asset(
                                'assets/images/friends_with_friends.gif',
                                fit: BoxFit.fitHeight,
                              ),
                            ),
                            onPressedUpper: () =>
                                Navigator.of(context).pushNamed('friends-solo'),
                            onPressedLower: () => Navigator.of(context)
                                .pushNamed('friends-double'),
                          ),
                        ),
                      );
                    },
                  );
                case 'friends-solo':
                  return _buildPageRoute(
                    settings: settings,
                    builder: (context) {
                      return CurrentRouteSystemUiStyling.dark(
                        child: MenuScreenTheme(
                          themeData: const MenuScreenThemeData(
                            backgroundGradientBottom:
                                Color.fromRGBO(0xAA, 0xF0, 0xFF, 0.12),
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
                          child: MenuScreen(
                            label: 'meet people',
                            image: Transform.translate(
                              offset: const Offset(0.0, 12.0),
                              child: Image.asset(
                                'assets/images/friends.gif',
                                height: 90,
                              ),
                            ),
                            onPressedVoiceCall: (serious) {
                              Navigator.of(context).pushNamed(
                                'friends-lobby',
                                arguments: LobbyScreenArguments(
                                  video: false,
                                  serious: serious,
                                ),
                              );
                            },
                            onPressedVideoCall: (serious) {
                              Navigator.of(context).pushNamed(
                                'friends-lobby',
                                arguments: LobbyScreenArguments(
                                  video: true,
                                  serious: serious,
                                ),
                              );
                            },
                            onPressedPreferences: () => _navigateToPreferences(
                                context, Purpose.friends),
                          ),
                        ),
                      );
                    },
                  );
                case 'friends-double':
                  return _buildPageRoute(
                    settings: settings,
                    builder: (context) {
                      return CurrentRouteSystemUiStyling.dark(
                        child: MenuScreenTheme(
                          themeData: const MenuScreenThemeData(
                            backgroundGradientBottom:
                                Color.fromRGBO(0xAA, 0xF0, 0xFF, 0.12),
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
                          child: MenuScreen(
                            label: 'meet people\nwith friends',
                            image: SizedBox(
                              height: 120,
                              child: Image.asset(
                                'assets/images/friends_with_friends.gif',
                                fit: BoxFit.fitHeight,
                              ),
                            ),
                            groupCalling: true,
                            onPressedVoiceCall: (_) =>
                                _displayConnections(context, video: false),
                            onPressedVideoCall: (_) =>
                                _displayConnections(context, video: true),
                            onPressedPreferences: () => _navigateToPreferences(
                                context, Purpose.friends),
                          ),
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
                      return CurrentRouteSystemUiStyling.dark(
                        child: PreferencesScreenTheme(
                          themeData: const PreferencesScreenThemeData(
                            backgroundGradientBottom:
                                Color.fromRGBO(0xFF, 0xFF, 0xFF, 1.0),
                            titleColor: Color.fromRGBO(0x63, 0xCD, 0xE3, 1.0),
                            expansionButtonGradient: LinearGradient(
                              colors: [
                                Color.fromRGBO(0x26, 0xC4, 0xE6, 1.0),
                                Color.fromRGBO(0x7B, 0xDC, 0xF1, 1.0),
                              ],
                            ),
                            doneButtonGradient: LinearGradient(
                              colors: [
                                Color.fromRGBO(0xFF, 0xA5, 0xA5, 1.0),
                                Color.fromRGBO(0xFF, 0xC9, 0xC9, 1.0),
                              ],
                            ),
                            backArrowColor:
                                Color.fromARGB(0xFF, 0x89, 0xDE, 0xFF),
                            profileButtonColor:
                                Color.fromARGB(0xFF, 0x89, 0xDE, 0xFF),
                          ),
                          child: PreferencesScreen(
                            initialPreferences: args,
                            title: 'Meet People',
                            image: const MaleFemaleConnectionImageApart(),
                            updatePreferences: (usersApi, uid, preferences) =>
                                usersApi.updateFriendsPreferences(
                                    uid, preferences),
                          ),
                        ),
                      );
                    },
                  );
                case 'friends-lobby':
                  final args = settings.arguments as LobbyScreenArguments;
                  return _buildPageRoute(
                    settings: settings,
                    builder: (context) {
                      return CurrentRouteSystemUiStyling.light(
                        child: LobbyScreenTheme(
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
                            host: host,
                            socketPort: socketPort,
                            video: args.video,
                            serious: args.serious,
                            purpose: Purpose.friends,
                            onJoinCall: ({
                              required String rid,
                              required List<PublicProfile> profiles,
                              required List<Rekindle> rekindles,
                            }) {
                              final route = args.video
                                  ? 'friends-video-call'
                                  : 'friends-voice-call';
                              Navigator.of(context).pushNamed(
                                route,
                                arguments: CallPageArguments(
                                  rid: rid,
                                  profiles: profiles,
                                  rekindles: rekindles,
                                  serious: args.serious,
                                ),
                              );
                            },
                          ),
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
                      return CurrentRouteSystemUiStyling.light(
                        child: VoiceCallScreenTheme(
                          themeData: const VoiceCallScreenThemeData(
                            backgroundGradient: LinearGradient(
                              colors: [
                                Color.fromRGBO(0x02, 0x4A, 0x5A, 0.4),
                                Color.fromRGBO(0x01, 0x43, 0x52, 0.9),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            panelGradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color.fromRGBO(0xFF, 0xFF, 0xFF, 0.5),
                                Color.fromRGBO(0x00, 0xAA, 0xCF, 0.5),
                              ],
                            ),
                            endCallGradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color.fromRGBO(0xFF, 0xFF, 0xFF, 0.5),
                                Color.fromRGBO(0x00, 0x92, 0xB2, 0.5),
                              ],
                            ),
                            endCallSymbolColor:
                                Color.fromRGBO(0x00, 0x6C, 0xA1, 1.0),
                          ),
                          child: CallScreen(
                            rid: args.rid,
                            host: host,
                            socketPort: socketPort,
                            video: false,
                            serious: args.serious,
                            profiles: args.profiles,
                            rekindles: args.rekindles,
                            groupLobby: args.groupLobby,
                          ),
                        ),
                      );
                    },
                  );
                case 'friends-video-call':
                  final args = settings.arguments as CallPageArguments;
                  return _buildPageRoute(
                    settings: settings,
                    transitionsBuilder: fadePageTransition,
                    builder: (_) {
                      return CurrentRouteSystemUiStyling.light(
                        child: CallScreen(
                          rid: args.rid,
                          host: host,
                          socketPort: socketPort,
                          video: true,
                          serious: args.serious,
                          profiles: args.profiles,
                          rekindles: args.rekindles,
                          groupLobby: args.groupLobby,
                        ),
                      );
                    },
                  );
                case 'dating-solo-double':
                  return _buildPageRoute(
                    settings: settings,
                    builder: (context) {
                      return CurrentRouteSystemUiStyling.light(
                        child: SoloDoubleScreenTheme(
                          themeData: const SoloDoubleScreenThemeData(
                            upperGradients: [
                              RadialGradient(
                                colors: [
                                  Color.fromRGBO(0xFF, 0xE8, 0xE8, 1.0),
                                  Color.fromRGBO(0xFF, 0xB0, 0xB0, 0.0),
                                ],
                              ),
                              RadialGradient(
                                colors: [
                                  Color.fromRGBO(0xFF, 0xC7, 0xC7, 0.5),
                                  Color.fromRGBO(0xFF, 0xB4, 0xB4, 0.25),
                                  Color.fromRGBO(0xFF, 0xD4, 0xD4, 0.125),
                                  Color.fromRGBO(0xFD, 0xEF, 0xEF, 0.0),
                                ],
                              ),
                              // Solid color
                              LinearGradient(
                                colors: [
                                  Color.fromRGBO(0xFF, 0xB2, 0xB2, 1.0),
                                  Color.fromRGBO(0xFF, 0xB2, 0xB2, 1.0),
                                ],
                              ),
                            ],
                            lowerGradients: [
                              RadialGradient(
                                colors: [
                                  Color.fromRGBO(0xFF, 0xED, 0xED, 1.0),
                                  Color.fromRGBO(0xFF, 0xB0, 0xB0, 0.0),
                                ],
                              ),
                              RadialGradient(
                                colors: [
                                  Color.fromRGBO(0xFF, 0xA8, 0xA8, 0.50),
                                  Color.fromRGBO(0xFF, 0xB4, 0xB4, 0.25),
                                  Color.fromRGBO(0xFF, 0xA5, 0xA5, 0.125),
                                  Color.fromRGBO(0xFF, 0x90, 0x90, 0.0),
                                ],
                              ),
                              // Solid color
                              LinearGradient(
                                colors: [
                                  Color.fromRGBO(0xEE, 0x87, 0x87, 1.0),
                                  Color.fromRGBO(0xEE, 0x87, 0x87, 1.0),
                                ],
                              ),
                            ],
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
                                'assets/images/heart.gif',
                                fit: BoxFit.fitHeight,
                              ),
                            ),
                            imageLower: SizedBox(
                              height: 160,
                              child: Image.asset(
                                'assets/images/double_dating.gif',
                                fit: BoxFit.fitHeight,
                              ),
                            ),
                            onPressedUpper: () =>
                                Navigator.of(context).pushNamed('dating-solo'),
                            onPressedLower: () => Navigator.of(context)
                                .pushNamed('dating-double'),
                          ),
                        ),
                      );
                    },
                  );
                case 'dating-solo':
                  return _buildPageRoute(
                    settings: settings,
                    builder: (context) {
                      return CurrentRouteSystemUiStyling.dark(
                        child: MenuScreenTheme(
                          themeData: const MenuScreenThemeData(
                            backgroundGradientBottom:
                                Color.fromRGBO(0xFF, 0xD2, 0xD2, 1.0),
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
                          child: MenuScreen(
                            label: 'blind date',
                            image: SizedBox(
                              height: 120,
                              child: Image.asset(
                                'assets/images/heart.gif',
                                fit: BoxFit.fitHeight,
                              ),
                            ),
                            onPressedVoiceCall: (serious) {
                              Navigator.of(context).pushNamed(
                                'dating-lobby',
                                arguments: LobbyScreenArguments(
                                  video: false,
                                  serious: serious,
                                ),
                              );
                            },
                            onPressedVideoCall: (serious) {
                              Navigator.of(context).pushNamed(
                                'dating-lobby',
                                arguments: LobbyScreenArguments(
                                  video: true,
                                  serious: serious,
                                ),
                              );
                            },
                            onPressedPreferences: () =>
                                _navigateToPreferences(context, Purpose.dating),
                          ),
                        ),
                      );
                    },
                  );
                case 'dating-double':
                  return _buildPageRoute(
                    settings: settings,
                    builder: (context) {
                      return CurrentRouteSystemUiStyling.dark(
                        child: MenuScreenTheme(
                          themeData: const MenuScreenThemeData(
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
                          child: MenuScreen(
                            label: 'double dating',
                            image: SizedBox(
                              height: 120,
                              child: Image.asset(
                                'assets/images/double_dating.gif',
                                fit: BoxFit.fitHeight,
                              ),
                            ),
                            groupCalling: true,
                            onPressedVoiceCall: (_) =>
                                _displayConnections(context, video: false),
                            onPressedVideoCall: (_) =>
                                _displayConnections(context, video: true),
                            onPressedPreferences: () =>
                                _navigateToPreferences(context, Purpose.dating),
                          ),
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
                      return CurrentRouteSystemUiStyling.dark(
                        child: PreferencesScreenTheme(
                          themeData: const PreferencesScreenThemeData(
                            backgroundGradientBottom:
                                Color.fromARGB(0xFF, 0xFF, 0xDD, 0xDD),
                            titleColor: Color.fromARGB(0xFF, 0xFF, 0x7A, 0x7A),
                            expansionButtonGradient: LinearGradient(
                              colors: [
                                Color.fromRGBO(0xF3, 0x94, 0x94, 1.0),
                                Color.fromRGBO(0xFF, 0x63, 0x63, 1.0),
                              ],
                            ),
                            doneButtonGradient: LinearGradient(
                              colors: [
                                Color.fromRGBO(0xF3, 0x94, 0x94, 1.0),
                                Color.fromRGBO(0xFF, 0x63, 0x63, 1.0),
                              ],
                            ),
                            backArrowColor:
                                Color.fromARGB(0xFF, 0xFD, 0x89, 0x89),
                            profileButtonColor:
                                Color.fromARGB(0xFF, 0xFF, 0x8A, 0x8A),
                          ),
                          child: PreferencesScreen(
                            initialPreferences: args,
                            title: 'Blind Dating',
                            image: Image.asset(
                              'assets/images/double_dating.gif',
                              height: 197,
                            ),
                            updatePreferences: (usersApi, uid, preferences) =>
                                usersApi.updateDatingPreferences(
                                    uid, preferences),
                          ),
                        ),
                      );
                    },
                  );
                case 'dating-lobby':
                  final args = settings.arguments as LobbyScreenArguments;
                  return _buildPageRoute(
                    settings: settings,
                    builder: (context) {
                      return CurrentRouteSystemUiStyling.light(
                        child: LobbyScreenTheme(
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
                            host: host,
                            socketPort: socketPort,
                            video: args.video,
                            serious: args.serious,
                            purpose: Purpose.dating,
                            onJoinCall: ({
                              required String rid,
                              required List<PublicProfile> profiles,
                              required List<Rekindle> rekindles,
                            }) {
                              final route = args.video
                                  ? 'dating-video-call'
                                  : 'dating-voice-call';
                              Navigator.of(context).pushNamed(
                                route,
                                arguments: CallPageArguments(
                                  rid: rid,
                                  profiles: profiles,
                                  rekindles: rekindles,
                                  serious: args.serious,
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  );
                case 'dating-voice-call':
                  final args = settings.arguments as CallPageArguments;
                  return _buildPageRoute(
                    settings: settings,
                    transitionsBuilder: fadePageTransition,
                    builder: (_) {
                      return CurrentRouteSystemUiStyling.light(
                        child: VoiceCallScreenTheme(
                          themeData: const VoiceCallScreenThemeData(
                            backgroundGradient: LinearGradient(
                              colors: [
                                Color.fromRGBO(0x53, 0x01, 0x01, 0.4),
                                Color.fromRGBO(0x25, 0x00, 0x01, 0.9),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            panelGradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color.fromRGBO(0xFF, 0xFF, 0xFF, 0.5),
                                Color.fromRGBO(0xFF, 0x00, 0x00, 0.5),
                              ],
                            ),
                            endCallGradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color.fromRGBO(0xFF, 0xFF, 0xFF, 0.5),
                                Color.fromRGBO(0xFF, 0x4A, 0x4A, 0.5),
                              ],
                            ),
                            endCallSymbolColor:
                                Color.fromRGBO(0x9E, 0x00, 0x00, 1.0),
                          ),
                          child: CallScreen(
                            rid: args.rid,
                            host: host,
                            socketPort: socketPort,
                            video: false,
                            serious: args.serious,
                            profiles: args.profiles,
                            rekindles: args.rekindles,
                            groupLobby: args.groupLobby,
                          ),
                        ),
                      );
                    },
                  );
                case 'dating-video-call':
                  final args = settings.arguments as CallPageArguments;
                  return _buildPageRoute(
                    settings: settings,
                    transitionsBuilder: fadePageTransition,
                    builder: (_) {
                      return CurrentRouteSystemUiStyling.light(
                        child: CallScreen(
                          rid: args.rid,
                          host: host,
                          socketPort: socketPort,
                          video: true,
                          serious: args.serious,
                          profiles: args.profiles,
                          rekindles: args.rekindles,
                          groupLobby: args.groupLobby,
                        ),
                      );
                    },
                  );
                case 'rekindle':
                  return _buildPageRoute(
                    settings: settings,
                    builder: (context) {
                      return const CurrentRouteSystemUiStyling.light(
                        child: RekindleScreen(),
                      );
                    },
                  );
                case 'precached-rekindle':
                  final args =
                      settings.arguments as PrecachedRekindleScreenArguments;
                  return _buildPageRoute(
                    settings: settings,
                    builder: (context) {
                      return CurrentRouteSystemUiStyling.light(
                        child: RekindleScreenPrecached(
                          rekindles: args.rekindles,
                          index: args.index,
                          title: args.title,
                          countdown: args.countdown,
                        ),
                      );
                    },
                  );
                case 'call-report':
                  final args = settings.arguments as ReportScreenArguments;
                  return _buildPageRoute(
                    settings: settings,
                    transitionsBuilder: fadePageTransition,
                    builder: (_) {
                      return CurrentRouteSystemUiStyling.light(
                        child: ReportScreenTheme(
                          themeData: const ReportScreenThemeData(
                            backgroundGradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color.fromRGBO(0xFF, 0x8E, 0x8E, 0.9),
                                Color.fromRGBO(0xBD, 0x20, 0x20, 0.74),
                              ],
                            ),
                          ),
                          child: ReportScreen(
                            uid: args.uid,
                          ),
                        ),
                      );
                    },
                  );
                case 'public-profile':
                  final args = settings.arguments as PublicProfileArguments;
                  return _buildPageRoute(
                    settings: settings,
                    builder: (_) {
                      return CurrentRouteSystemUiStyling.light(
                        child: PublicProfileScreen(
                          publicProfile: args.publicProfile,
                          editable: args.editable,
                        ),
                      );
                    },
                  );
                case 'public-profile-edit':
                  return _buildPageRoute(
                    settings: settings,
                    builder: (_) {
                      return const CurrentRouteSystemUiStyling.light(
                        child: PublicProfileEditScreen(),
                      );
                    },
                  );
                case 'private-profile':
                  final args = settings.arguments as PrivateProfile;
                  return _buildPageRoute(
                    settings: settings,
                    builder: (_) {
                      return CurrentRouteSystemUiStyling.dark(
                        child: PrivateProfileScreen(
                          initialProfile: args,
                        ),
                      );
                    },
                  );
                case 'connections':
                  return _buildPageRoute(
                    settings: settings,
                    builder: (_) {
                      return const CurrentRouteSystemUiStyling.light(
                        child: ConnectionsScreen(),
                      );
                    },
                  );
                case 'chat':
                  final args = settings.arguments as ChatArguments;
                  return _buildPageRoute(
                    settings: settings,
                    builder: (_) {
                      return CurrentRouteSystemUiStyling.light(
                        child: ChatScreen(
                          host: host,
                          webPort: webPort,
                          socketPort: socketPort,
                          profile: args.profile,
                          chatroomId: args.chatroomId,
                        ),
                      );
                    },
                  );
                case 'account-settings':
                  return _buildPageRoute(
                    settings: settings,
                    builder: (_) {
                      return const CurrentRouteSystemUiStyling.light(
                        child: AccountSettingsScreen(),
                      );
                    },
                  );
                case 'contact-us':
                  return _buildPageRoute(
                    settings: settings,
                    builder: (_) {
                      return const CurrentRouteSystemUiStyling.light(
                        child: ContactUsScreen(),
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
          body: InheritedRouteObserver(
            routeObserver: _routeObserver,
            child: Builder(builder: builder),
          ),
          resizeToAvoidBottomInset: false,
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

  void _navigateToPreferences(BuildContext context, Purpose purpose) async {
    final usersApi = ref.read(usersApiProvider);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final preferences = purpose == Purpose.friends
          ? await usersApi.getFriendsPreferences(uid)
          : await usersApi.getDatingPreferences(uid);
      final route = purpose == Purpose.friends ? 'friends' : 'dating';
      Navigator.of(context).pushNamed(
        '$route-preferences',
        arguments: preferences,
      );
    }
  }

  void _displayConnections(BuildContext context, {required bool video}) async {
    showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      builder: (context) {
        return ConnectionsBottomSheet(
          onSelected: (profile) async {
            final usersApi = ref.read(usersApiProvider);
            final uid = FirebaseAuth.instance.currentUser?.uid;
            if (uid != null) {
              final rid = await usersApi.call(
                uid,
                profile.uid,
                video,
                group: true,
              );
              if (mounted) {
                final route =
                    video ? 'friends-video-call' : 'friends-voice-call';
                Navigator.of(context).pushNamed(
                  route,
                  arguments: CallPageArguments(
                    rid: rid,
                    profiles: [profile],
                    rekindles: [],
                    serious: false,
                    groupLobby: true,
                  ),
                );
              }
            }
          },
        );
      },
    );
  }
}
