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
import 'package:go_router/go_router.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';
import 'package:openup/account_settings_screen.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/call_manager.dart';
import 'package:openup/api/online_users_api.dart';
import 'package:openup/api/online_users_api_util.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/call_page.dart';
import 'package:openup/chat_page.dart';
import 'package:openup/contact_us_screen.dart';
import 'package:openup/discover_page.dart';
import 'package:openup/error_screen.dart';
import 'package:openup/friendships_page.dart';
import 'package:openup/home_screen.dart';
import 'package:openup/initial_loading_screen.dart';
import 'package:openup/profile_page.dart';
import 'package:openup/report_screen.dart';
import 'package:openup/sign_up_audio_screen.dart';
import 'package:openup/sign_up_name_screen.dart';
import 'package:openup/sign_up_photos_screen.dart';
import 'package:openup/sign_up_start_animation.dart';
import 'package:openup/sign_up_topic_screen.dart';
import 'package:openup/util/page_transition.dart';
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

/// Notifications don't update the conversations list. This noifier lets us
/// force a refresh programmatically when tapping the Friendships button.
class TempFriendshipsRefresh extends ValueNotifier<void> {
  TempFriendshipsRefresh() : super(null);

  void refresh() => notifyListeners();
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

  late final GoRouter _goRouter;
  final _routeObserver = RouteObserver<PageRoute>();

  final _discoverKey = GlobalKey<NavigatorState>();
  final _friendshipsKey = GlobalKey<NavigatorState>();
  final _profileKey = GlobalKey<NavigatorState>();

  final _tempFriendshipsRefresh = TempFriendshipsRefresh();

  final _scrollToDiscoverTopNotifier = ScrollToDiscoverTopNotifier();

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

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    _goRouter = _initGoRouter(
      observers: [_routeObserver],
    );

    Api.seed = Random().nextInt(1 << 32).toString();
    final api = Api(
      host: host,
      port: webPort,
    );
    GetIt.instance.registerSingleton<Api>(api);

    GetIt.instance.registerSingleton<CallManager>(CallManager());

    Firebase.initializeApp().then((_) {
      _idTokenChangesSubscription =
          FirebaseAuth.instance.idTokenChanges().listen((user) async {
        final loggedIn = user != null;
        if (_loggedIn != loggedIn) {
          setState(() => _loggedIn = loggedIn);
          if (loggedIn) {
            if (GetIt.instance.isRegistered<OnlineUsersApi>()) {
              GetIt.instance.unregister<OnlineUsersApi>();
            }
            _onlineUsersApi?.dispose();
            _onlineUsersApi = OnlineUsersApi(
              host: host,
              port: socketPort,
              uid: user.uid,
              onConnectionError: () {},
              onOnlineStatusChanged: (uid, online) {
                ref
                    .read(onlineUsersProvider.notifier)
                    .onlineChanged(uid, online);
              },
            );
            GetIt.instance.registerSingleton<OnlineUsersApi>(_onlineUsersApi!);
          }
        }

        // Firebase ID token refresh
        if (user != null) {
          try {
            final token = await user.getIdToken();
            if (mounted) {
              ref.read(userProvider.notifier).uid(user.uid);
              api.authToken = token;
            }
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
    _tempFriendshipsRefresh.dispose();
    _scrollToDiscoverTopNotifier.dispose();
    _onlineUsersApi?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = ThemeData().textTheme;
    return ProviderScope(
      child: MaterialApp.router(
        routerConfig: _goRouter,
        theme: ThemeData(
          colorScheme: const ColorScheme.light(
            primary: Color.fromARGB(255, 27, 14, 14),
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
        builder: (context, child) {
          return Stack(
            children: [
              if (child != null) Positioned.fill(child: child),
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: StreamBuilder<bool>(
                  stream:
                      GetIt.instance.get<CallManager>().callPageActiveStream,
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
                              onPressed: () => context.pushNamed('call'),
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
      ),
    );
  }

  GoRouter _initGoRouter({
    List<NavigatorObserver>? observers,
  }) {
    return GoRouter(
      observers: observers,
      debugLogDiagnostics: !kReleaseMode,
      navigatorKey: rootNavigatorKey,
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          name: 'initialLoading',
          builder: (context, state) {
            final args = state.extra as InitialLoadingScreenArguments?;
            return CurrentRouteSystemUiStyling.light(
              child: InitialLoadingScreen(
                navigatorKey: rootNavigatorKey,
                needsOnboarding: args?.needsOnboarding ?? false,
              ),
            );
          },
        ),
        GoRoute(
          path: '/404',
          name: 'error',
          builder: (context, state) {
            final args = state.extra as InitialLoadingScreenArguments?;
            return CurrentRouteSystemUiStyling.dark(
              child: ErrorScreen(
                needsOnboarding: args?.needsOnboarding ?? false,
              ),
            );
          },
        ),
        GoRoute(
          path: '/signup',
          name: 'signup',
          builder: (context, state) {
            return const CurrentRouteSystemUiStyling.light(
              child: SignUpScreen(),
            );
          },
          // TODO: Add PhoneVerificationScreen here instead of using imperative navigation
        ),
        GoRoute(
          path: '/onboarding',
          name: 'onboarding',
          builder: (context, state) {
            return const CurrentRouteSystemUiStyling.light(
              child: SignUpOverviewPage(),
            );
          },
          routes: [
            GoRoute(
              path: 'name',
              name: 'onboarding-name',
              builder: (context, state) {
                return const CurrentRouteSystemUiStyling.light(
                  child: SignUpNameScreen(),
                );
              },
              routes: [
                GoRoute(
                  path: 'topic',
                  name: 'onboarding-topic',
                  builder: (context, state) {
                    return const CurrentRouteSystemUiStyling.light(
                      child: SignUpTopicScreen(),
                    );
                  },
                  routes: [
                    GoRoute(
                      path: 'photos',
                      name: 'onboarding-photos',
                      builder: (context, state) {
                        return const CurrentRouteSystemUiStyling.light(
                          child: SignUpPhotosScreen(),
                        );
                      },
                      routes: [
                        GoRoute(
                          path: 'audio',
                          name: 'onboarding-audio',
                          builder: (context, state) {
                            return const CurrentRouteSystemUiStyling.light(
                              child: SignUpAudioScreen(),
                            );
                          },
                          routes: [
                            GoRoute(
                              path: 'welcome',
                              name: 'onboarding-welcome',
                              builder: (context, state) {
                                return const CurrentRouteSystemUiStyling.light(
                                  child: SignUpStartAnimationScreen(),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        PartitionedShellRoute.stackedNavigation(
          stackItems: [
            StackedNavigationItem(
              rootRoutePath: '/discover',
              navigatorKey: _discoverKey,
            ),
            StackedNavigationItem(
              rootRoutePath: '/friendships',
              navigatorKey: _friendshipsKey,
            ),
            StackedNavigationItem(
              rootRoutePath: '/profile',
              navigatorKey: _profileKey,
            ),
          ],
          scaffoldBuilder: (context, currentIndex, itemsState, child) {
            return CurrentRouteSystemUiStyling.light(
              child: HomeShell(
                tabIndex: currentIndex,
                tempFriendshipsRefresh: _tempFriendshipsRefresh,
                scrollToDiscoverTopNotifier: _scrollToDiscoverTopNotifier,
                child: child,
              ),
            );
          },
          routes: [
            GoRoute(
              path: '/discover',
              name: 'discover',
              parentNavigatorKey: _discoverKey,
              builder: (context, state) {
                return DiscoverPage(
                  scrollToTopNotifier: _scrollToDiscoverTopNotifier,
                );
              },
            ),
            GoRoute(
              path: '/friendships',
              name: 'friendships',
              parentNavigatorKey: _friendshipsKey,
              builder: (context, state) => FriendshipsPage(
                tempRefresh: _tempFriendshipsRefresh,
              ),
              routes: [
                GoRoute(
                  path: ':uid',
                  name: 'chat',
                  builder: (context, state) {
                    final uid = state.params['uid']!;
                    final args = state.extra as ChatPageArguments?;
                    return CurrentRouteSystemUiStyling.light(
                      child: ChatPage(
                        host: host,
                        webPort: webPort,
                        socketPort: socketPort,
                        otherUid: uid,
                        otherProfile: args?.otherProfile,
                        endTime: args?.endTime,
                      ),
                    );
                  },
                  routes: [
                    GoRoute(
                      path: 'call',
                      name: 'call',
                      parentNavigatorKey: rootNavigatorKey,
                      builder: (context, state) {
                        return const CurrentRouteSystemUiStyling.light(
                          child: CallPage(),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
            GoRoute(
              path: '/profile',
              name: 'profile',
              parentNavigatorKey: _profileKey,
              builder: (context, state) => const ProfilePage(),
              routes: [
                GoRoute(
                  path: 'settings',
                  name: 'settings',
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (context, state) {
                    return const CurrentRouteSystemUiStyling.light(
                      child: AccountSettingsScreen(),
                    );
                  },
                  routes: [
                    // TODO: Add SettingsPhoneVerificationScreen here instead of using imperative navigation
                    GoRoute(
                      path: 'contact_us',
                      name: 'contact-us',
                      builder: (context, state) {
                        return const CurrentRouteSystemUiStyling.light(
                          child: ContactUsScreen(),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/report',
          name: 'report',
          builder: (context, state) {
            final args = state.extra as ReportScreenArguments;
            return CurrentRouteSystemUiStyling.light(
              child: ReportScreen(
                uid: args.uid,
              ),
            );
          },
        ),
      ],
    );
  }
}
