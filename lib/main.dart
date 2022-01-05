import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openup/api/lobby/lobby_api.dart';
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
import 'package:openup/util/page_transition.dart';
import 'package:openup/solo_double_screen.dart';
import 'package:openup/lobby_screen.dart';
import 'package:openup/home_screen.dart';
import 'package:openup/forgot_password_screen.dart';
import 'package:openup/phone_verification_screen.dart';
import 'package:openup/sign_up_screen.dart';
import 'package:openup/menu_screen.dart';
import 'package:openup/widgets/connections_list.dart';
import 'package:openup/widgets/male_female_connection_image.dart';
import 'package:openup/widgets/profile_drawer.dart';
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
  @override
  void initState() {
    super.initState();
    initUsersApi(
      host: host,
      port: webPort,
    );

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
            initialRoute: '/',
            onGenerateRoute: (settings) {
              switch (settings.name) {
                case '/':
                  return _buildPageRoute(
                    settings: settings,
                    transitionsBuilder: fadePageTransition,
                    builder: (_) => const InitialLoadingScreen(),
                  );
                case 'error':
                  return _buildPageRoute(
                    settings: settings,
                    transitionsBuilder: fadePageTransition,
                    builder: (_) => const ErrorScreen(),
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
                case 'home':
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
                              'assets/images/friends_with_friends.gif',
                              fit: BoxFit.fitHeight,
                            ),
                          ),
                          onPressedUpper: () =>
                              Navigator.of(context).pushNamed('friends-solo'),
                          onPressedLower: () =>
                              Navigator.of(context).pushNamed('friends-double'),
                        ),
                      );
                    },
                  );
                case 'friends-solo':
                  return _buildPageRoute(
                    settings: settings,
                    builder: (context) {
                      return MenuScreenTheme(
                        themeData: const MenuScreenThemeData(
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
                        child: MenuScreen(
                          label: 'meet people',
                          image: const SizedBox(
                            height: 90,
                            child: MaleFemaleConnectionImage(
                              offset: Offset(0.0, 13.0),
                            ),
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
                          onPressedPreferences: () =>
                              _navigateToPreferences(context, Purpose.friends),
                        ),
                      );
                    },
                  );
                case 'friends-double':
                  return _buildPageRoute(
                    settings: settings,
                    builder: (context) {
                      return MenuScreenTheme(
                        themeData: const MenuScreenThemeData(
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
                          onPressedVoiceCall: () =>
                              _displayConnections(context, video: false),
                          onPressedVideoCall: () =>
                              _displayConnections(context, video: true),
                          onPressedPreferences: () =>
                              _navigateToPreferences(context, Purpose.friends),
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
                            height: 60,
                            child: MaleFemaleConnectionImage(
                              offset: Offset(0.0, 6.0),
                            ),
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
                          host: host,
                          socketPort: socketPort,
                          video: args.video,
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
                      return CallScreen(
                        rid: args.rid,
                        host: host,
                        socketPort: socketPort,
                        video: false,
                        profiles: args.profiles,
                        rekindles: args.rekindles,
                      );
                    },
                  );
                case 'friends-video-call':
                  final args = settings.arguments as CallPageArguments;
                  return _buildPageRoute(
                    settings: settings,
                    transitionsBuilder: fadePageTransition,
                    builder: (_) {
                      return CallScreen(
                        rid: args.rid,
                        host: host,
                        socketPort: socketPort,
                        video: true,
                        profiles: args.profiles,
                        rekindles: args.rekindles,
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
                          onPressedLower: () =>
                              Navigator.of(context).pushNamed('dating-double'),
                        ),
                      );
                    },
                  );
                case 'dating-solo':
                  return _buildPageRoute(
                    settings: settings,
                    builder: (context) {
                      return MenuScreenTheme(
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
                          label: 'blind date',
                          image: SizedBox(
                            height: 120,
                            child: Image.asset(
                              'assets/images/heart.gif',
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
                          onPressedPreferences: () =>
                              _navigateToPreferences(context, Purpose.dating),
                        ),
                      );
                    },
                  );
                case 'dating-double':
                  return _buildPageRoute(
                    settings: settings,
                    builder: (context) {
                      return MenuScreenTheme(
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
                          onPressedVoiceCall: () =>
                              _displayConnections(context, video: false),
                          onPressedVideoCall: () =>
                              _displayConnections(context, video: true),
                          onPressedPreferences: () =>
                              _navigateToPreferences(context, Purpose.dating),
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
                            child: Image.asset('assets/images/heart.gif'),
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
                          host: host,
                          socketPort: socketPort,
                          video: args.video,
                          purpose: Purpose.dating,
                          onJoinCall: ({
                            required String rid,
                            required List<PublicProfile> profiles,
                            required List<Rekindle> rekindles,
                          }) {
                            // TOOD: Proper routes
                            final route = args.video
                                ? 'friends-video-call'
                                : 'friends-voice-call';
                            Navigator.of(context).pushNamed(
                              route,
                              arguments: CallPageArguments(
                                rid: rid,
                                profiles: profiles,
                                rekindles: rekindles,
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                case 'rekindle':
                  return _buildPageRoute(
                    settings: settings,
                    builder: (context) => const RekindleScreen(),
                  );
                case 'precached-rekindle':
                  final args =
                      settings.arguments as PrecachedRekindleScreenArguments;
                  return _buildPageRoute(
                    settings: settings,
                    builder: (context) {
                      return RekindleScreenPrecached(
                        rekindles: args.rekindles,
                        index: args.index,
                        title: args.title,
                        countdown: args.countdown,
                      );
                    },
                  );
                case 'public-profile':
                  final args = settings.arguments as PublicProfileArguments;
                  return _buildPageRoute(
                    settings: settings,
                    builder: (_) {
                      return PublicProfileScreen(
                        publicProfile: args.publicProfile,
                        editable: args.editable,
                      );
                    },
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
                case 'connections':
                  return _buildPageRoute(
                    settings: settings,
                    builder: (_) => const ConnectionsScreen(),
                  );
                case 'chat':
                  final args = settings.arguments as ChatArguments;
                  return _buildPageRoute(
                    settings: settings,
                    builder: (_) {
                      return ChatScreen(
                        host: host,
                        webPort: webPort,
                        socketPort: socketPort,
                        profile: args.profile,
                        chatroomId: args.chatroomId,
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
