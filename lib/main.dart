import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';
import 'package:openup/account_settings_phone_verification_screen.dart';
import 'package:openup/account_settings_screen.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/call_manager.dart';
import 'package:openup/api/online_users_api.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/call_page.dart';
import 'package:openup/contact_us_screen.dart';
import 'package:openup/error_screen.dart';
import 'package:openup/initial_loading_screen.dart';
import 'package:openup/report_screen.dart';
import 'package:openup/sign_up_audio_screen.dart';
import 'package:openup/sign_up_name_screen.dart';
import 'package:openup/sign_up_photos_hide_screen.dart';
import 'package:openup/sign_up_photos_screen.dart';
import 'package:openup/sign_up_start_animation.dart';
import 'package:openup/sign_up_topic_screen.dart';
import 'package:openup/util/page_transition.dart';
import 'package:openup/home_screen.dart';
import 'package:openup/phone_verification_screen.dart';
import 'package:openup/sign_up_screen.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/sign_up_overview_page.dart';
import 'package:openup/widgets/system_ui_styling.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

const host = 'ec2-54-156-60-224.compute-1.amazonaws.com';
const webPort = 8080;
const socketPort = 8081;

// TODO: Should be app constant coming from dart defines (to be used in background call handler too)
const urlBase = 'https://$host:$webPort';

final _scaffoldKey = GlobalKey();
final rootNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  void appRunner() async {
    WidgetsFlutterBinding.ensureInitialized();
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    final bool useTransparentSystemUi;
    if (!kIsWeb && Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;
      useTransparentSystemUi = sdkInt != null && sdkInt >= 29;
    } else {
      useTransparentSystemUi = true;
    }

    if (useTransparentSystemUi) {
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          systemNavigationBarColor: Color.fromRGBO(0x00, 0x00, 0x00, 0.0),
          systemNavigationBarContrastEnforced: true,
        ),
      );
    }

    runApp(
      const ProviderScope(
        child: OpenupApp(),
      ),
    );
  }

  if (!kReleaseMode) {
    appRunner();
  } else {
    const sentryDsn = String.fromEnvironment('SENTRY_DSN');
    await SentryFlutter.init(
      (options) {
        options.dsn = sentryDsn;
      },
      appRunner: appRunner,
    );
  }
}

class OpenupApp extends ConsumerStatefulWidget {
  const OpenupApp({Key? key}) : super(key: key);

  @override
  ConsumerState<OpenupApp> createState() => _OpenupAppState();
}

class _OpenupAppState extends ConsumerState<OpenupApp> {
  bool _loggedIn = false;
  StreamSubscription? _idTokenChangesSubscription;
  OnlineUsersApi? _onlineUsersApi;
  final _routeObserver = RouteObserver<PageRoute>();

  @override
  void initState() {
    super.initState();

    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    Api.seed = Random().nextInt(1 << 32).toString();
    final api = Api(
      host: host,
      port: webPort,
    );
    GetIt.instance.registerSingleton<Api>(api);

    GetIt.instance.registerSingleton<CallManager>(CallManager());

    Firebase.initializeApp().whenComplete(() {
      _idTokenChangesSubscription =
          FirebaseAuth.instance.idTokenChanges().listen((user) async {
        final loggedIn = user != null;
        if (_loggedIn != loggedIn) {
          setState(() => _loggedIn = loggedIn);
          if (loggedIn) {
            _onlineUsersApi?.dispose();
            _onlineUsersApi = OnlineUsersApi(
              host: host,
              port: socketPort,
              uid: user.uid,
              onConnectionError: () {},
            );
          }
        }

        // Firebase ID token refresh
        if (user != null) {
          try {
            final token = await user.getIdToken();
            ref.read(userProvider.notifier).uid(user.uid);
            api.authToken = token;
          } on FirebaseAuthException catch (e) {
            if (e.code == 'user-not-found') {
              // Is handled during initial loading
            } else {
              rethrow;
            }
          }
        }
      });
    });

    const mixpanelToken = String.fromEnvironment('MIXPANEL_TOKEN');
    Mixpanel.init(
      mixpanelToken,
      optOutTrackingDefault: !kReleaseMode,
      trackAutomaticEvents: true,
    );
  }

  @override
  void dispose() {
    _idTokenChangesSubscription?.cancel();
    _onlineUsersApi?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = ThemeData().textTheme;
    return MaterialApp(
      theme: ThemeData(
        colorScheme: const ColorScheme.light(
          primary: Color.fromARGB(0xFF, 0xFF, 0x71, 0x71),
          secondary: Color.fromARGB(0xAA, 0xFF, 0x71, 0x71),
        ),
        fontFamily: 'Myriad',
        textTheme: textTheme.copyWith(
          bodyMedium: textTheme.bodyMedium!.copyWith(
            fontFamily: 'Myriad',
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      navigatorKey: rootNavigatorKey,
      navigatorObservers: [_routeObserver],
      initialRoute: '/',
      builder: (context, child) {
        return Stack(
          children: [
            if (child != null) Positioned.fill(child: child),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: StreamBuilder<bool>(
                stream: GetIt.instance.get<CallManager>().callPageActiveStream,
                initialData: false,
                builder: (context, snapshot) {
                  final callPageActive = snapshot.requireData;
                  return StreamBuilder<CallState>(
                    stream: GetIt.instance.get<CallManager>().callState,
                    initialData: const CallState.none(),
                    builder: (context, snapshot) {
                      final callState = snapshot.requireData;
                      final display =
                          !(callState is CallStateNone || callPageActive);

                      return IgnorePointer(
                        ignoring: !display,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 150),
                          opacity: display ? 1.0 : 0.0,
                          child: Button(
                            onPressed: () => rootNavigatorKey.currentState
                                ?.pushNamed('call'),
                            child: Container(
                              height: 40 + MediaQuery.of(context).padding.top,
                              color:
                                  const Color.fromRGBO(0x03, 0xCB, 0x17, 1.0),
                              padding: EdgeInsets.only(
                                  top: MediaQuery.of(context).padding.top),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.call, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Tap to return to call',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium!
                                        .copyWith(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w300,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return _buildPageRoute(
              settings: settings,
              transitionsBuilder: fadePageTransition,
              builder: (_) {
                final args =
                    settings.arguments as InitialLoadingScreenArguments?;
                return CurrentRouteSystemUiStyling.light(
                  child: InitialLoadingScreen(
                    key: _scaffoldKey,
                    scaffoldKey: _scaffoldKey,
                    needsOnboarding: args?.needsOnboarding ?? false,
                  ),
                );
              },
            );
          case 'error':
            return _buildPageRoute(
              settings: settings,
              transitionsBuilder: fadePageTransition,
              builder: (_) {
                final args =
                    settings.arguments as InitialLoadingScreenArguments?;
                return CurrentRouteSystemUiStyling.dark(
                  child: ErrorScreen(
                    needsOnboarding: args?.needsOnboarding ?? false,
                  ),
                );
              },
            );
          case 'sign-up':
            return _buildPageRoute(
              settings: settings,
              builder: (_) {
                return const CurrentRouteSystemUiStyling.light(
                  child: SignUpScreen(),
                );
              },
            );
          case 'phone-verification':
            final args = settings.arguments as CredentialVerification;
            return _buildPageRoute<String?>(
              settings: settings,
              builder: (_) {
                return CurrentRouteSystemUiStyling.light(
                  child: PhoneVerificationScreen(
                    credentialVerification: args,
                  ),
                );
              },
            );
          case 'sign-up-overview':
            return _buildPageRoute(
              settings: settings,
              builder: (_) {
                return const CurrentRouteSystemUiStyling.light(
                  child: SignUpOverviewPage(),
                );
              },
            );
          case 'sign-up-name':
            return _buildPageRoute(
              settings: settings,
              builder: (_) {
                return const CurrentRouteSystemUiStyling.light(
                  child: SignUpNameScreen(),
                );
              },
            );
          case 'sign-up-topic':
            return _buildPageRoute(
              settings: settings,
              builder: (_) {
                return const CurrentRouteSystemUiStyling.light(
                  child: SignUpTopicScreen(),
                );
              },
            );
          case 'sign-up-photos':
            return _buildPageRoute(
              settings: settings,
              builder: (_) {
                return const CurrentRouteSystemUiStyling.light(
                  child: SignUpPhotosScreen(),
                );
              },
            );
          case 'sign-up-photos-hide':
            return _buildPageRoute(
              settings: settings,
              builder: (_) {
                return const CurrentRouteSystemUiStyling.light(
                  child: SignUpPhotosHideScreen(),
                );
              },
            );
          case 'sign-up-audio':
            return _buildPageRoute(
              settings: settings,
              builder: (_) {
                return const CurrentRouteSystemUiStyling.light(
                  child: SignUpAudioScreen(),
                );
              },
            );
          case 'sign-up-start-animation':
            return _buildPageRoute(
              settings: settings,
              builder: (_) {
                return const CurrentRouteSystemUiStyling.light(
                  child: SignUpStartAnimationScreen(),
                );
              },
            );
          case 'home':
            return _buildPageRoute(
              settings: settings,
              builder: (_) {
                final deepLinkArgs = settings.arguments as DeepLinkArgs?;
                return CurrentRouteSystemUiStyling.light(
                  key: _scaffoldKey,
                  child: HomeScreen(deepLinkArgs: deepLinkArgs),
                );
              },
            );
          case 'call-report':
            final args = settings.arguments as ReportScreenArguments;
            return _buildPageRoute(
              settings: settings,
              transitionsBuilder: fadePageTransition,
              builder: (context) {
                return CurrentRouteSystemUiStyling.light(
                  child: ReportScreen(
                    uid: args.uid,
                  ),
                );
              },
            );
          case 'call':
            return _buildPageRoute(
              settings: settings,
              builder: (_) {
                return const CurrentRouteSystemUiStyling.light(
                  child: CallPage(),
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
          case 'account-settings-phone-verification':
            final args = settings.arguments as String;
            return _buildPageRoute(
              settings: settings,
              builder: (_) {
                return CurrentRouteSystemUiStyling.light(
                  child: AccountSettingsPhoneVerificationScreen(
                    verificationId: args,
                  ),
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
  }

  PageRoute _buildPageRoute<T>({
    required RouteSettings settings,
    PageTransitionBuilder? transitionsBuilder,
    required WidgetBuilder builder,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionsBuilder: transitionsBuilder ?? slideRightToLeftPageTransition,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, animation, secondaryAnimation) {
        return InheritedRouteObserver(
          routeObserver: _routeObserver,
          child: Builder(builder: builder),
        );
      },
    );
  }
}
