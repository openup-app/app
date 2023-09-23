import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';
import 'package:openup/analytics/analytics.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/chat_state.dart';
import 'package:openup/api/in_app_notifications.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/auth/auth_provider.dart';
import 'package:openup/blocked_users_page.dart';
import 'package:openup/calendar_page.dart';
import 'package:openup/chat_page.dart';
import 'package:openup/contact_us_screen.dart';
import 'package:openup/discover_list_page.dart';
import 'package:openup/dynamic_config/dynamic_config.dart';
import 'package:openup/dynamic_config/dynamic_config_service.dart';
import 'package:openup/error_screen.dart';
import 'package:openup/contacts_page.dart';
import 'package:openup/events/event_create_page.dart';
import 'package:openup/events/event_preview_page.dart';
import 'package:openup/events/event_view_page.dart';
import 'package:openup/events/events_page.dart';
import 'package:openup/initial_loading_page.dart';
import 'package:openup/location/location_provider.dart';
import 'package:openup/location/location_search.dart';
import 'package:openup/location/location_service.dart';
import 'package:openup/location/mapbox_location_search_service.dart';
import 'package:openup/my_meetups_page.dart';
import 'package:openup/notifications/notifications.dart';
import 'package:openup/profile_page.dart';
import 'package:openup/conversations_page.dart';
import 'package:openup/report_screen.dart';
import 'package:openup/settings_page.dart';
import 'package:openup/shell_page.dart';
import 'package:openup/signup_permissions.dart';
import 'package:openup/signup_phone.dart';
import 'package:openup/signup_profile.dart';
import 'package:openup/signup_rules.dart';
import 'package:openup/signup_verify.dart';
import 'package:openup/util/key_value_store_service.dart';
import 'package:openup/view_profile_page.dart';
import 'package:openup/widgets/online_users.dart';
import 'package:openup/widgets/restart_app.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stack_trace/stack_trace.dart' as stack_trace;

const host = String.fromEnvironment('HOST');
const webPort = 8080;
const socketPort = 8081;

// TODO: Should be app constant coming from dart defines (to be used in background call handler too)
const urlBase = 'https://$host:$webPort';

void main() async {
  void appRunner() async {
    WidgetsFlutterBinding.ensureInitialized();
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    final bool useTransparentSystemUi;
    if (!kIsWeb && Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;
      useTransparentSystemUi = sdkInt >= 29;
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

    await Firebase.initializeApp();

    final mixpanel = await _initMixpanel();
    mixpanel.setLoggingEnabled(!kReleaseMode);

    final firebaseAnalytics = FirebaseAnalytics.instance;
    if (!kReleaseMode) {
      firebaseAnalytics.setAnalyticsCollectionEnabled(false);
    }

    Animate.restartOnHotReload = kDebugMode;

    final sharedPreferences = await SharedPreferences.getInstance();

    final dynamicConfigService = DynamicConfigService(
      defaults: const DynamicConfig(
        contactInviteMessage:
            'I\'m on Plus One, a new way to meet online. https://bonjourland.com',
        loginRequired: true,
      ),
    );
    dynamicConfigService.init();

    const mapboxAccessToken = String.fromEnvironment('MAPBOX_ACCESS_TOKEN');
    final mapboxLocationSearchService =
        MapboxLocationSearchService(accessToken: mapboxAccessToken);

    runApp(
      RestartApp(
        child: ProviderScope(
          overrides: [
            mixpanelProvider.overrideWithValue(mixpanel),
            firebaseAnalyticsProvider.overrideWithValue(firebaseAnalytics),
            apiProvider.overrideWith((ref) {
              Random().nextInt(1 << 32).toString();
              return Api(
                host: host,
                port: webPort,
              );
            }),
            keyValueStoreProvider.overrideWithValue(sharedPreferences),
            dynamicConfigStateProvider.overrideWith((ref) {
              final notifier =
                  DynamicConfigStateStateNotifier(dynamicConfigService);
              ref.onDispose(() => notifier.onDispose());
              return notifier;
            }),
            dynamicConfigProvider.overrideWith(
                (ref) => DynamicConfigStateNotifier(dynamicConfigService)),
            locationProvider.overrideWith((ref) {
              const austinLatLong = LatLong(
                latitude: 30.2672,
                longitude: 97.7431,
              );
              return LocationNotifier(
                service: LocationService(),
                keyValueStore: sharedPreferences,
                fallbackInitialLatLong: austinLatLong,
                overrideLatLong: ref.watch(locationOverrideProvider),
              );
            }),
            locationSearchProvider
                .overrideWith((ref) => mapboxLocationSearchService),
          ],
          child: const ProviderWatcher(
            child: OpenupApp(),
          ),
        ),
      ),
    );

    // Riverpod uses mangled stack trace
    FlutterError.demangleStackTrace = (StackTrace stack) {
      if (stack is stack_trace.Trace) return stack.vmTrace;
      if (stack is stack_trace.Chain) return stack.toTrace().vmTrace;
      return stack;
    };
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

Future<Mixpanel> _initMixpanel() async {
  const mixpanelToken = String.fromEnvironment('MIXPANEL_TOKEN');
  return await Mixpanel.init(
    mixpanelToken,
    optOutTrackingDefault: !kReleaseMode,
    trackAutomaticEvents: true,
  );
}

class OpenupApp extends ConsumerStatefulWidget {
  const OpenupApp({Key? key}) : super(key: key);

  @override
  ConsumerState<OpenupApp> createState() => _OpenupAppState();
}

class _OpenupAppState extends ConsumerState<OpenupApp> {
  late final GoRouter _goRouter;
  final _routeObserver = RouteObserver<PageRoute>();

  final _discoverKey = GlobalKey<NavigatorState>();
  final _conversationsKey = GlobalKey<NavigatorState>();
  final _eventsKey = GlobalKey<NavigatorState>();
  final _profileKey = GlobalKey<NavigatorState>();

  final rootNavigatorKey = GlobalKey<NavigatorState>();

  NotificationManager? _notificationManager;
  InAppNotificationsApi? _inAppNotificationsApi;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    _initNotifications();
    _initInAppNotifications();
    _initDynamicConfig();

    _goRouter = _initGoRouter(
      observers: [_routeObserver],
    );
  }

  void _initNotifications() {
    ref.listenManual<bool>(
      userProvider.select((p) {
        return p.map(
          guest: (_) => false,
          signedIn: (signedIn) => true,
        );
      }),
      (previous, next) {
        _notificationManager?.dispose();
        if (next) {
          _notificationManager = NotificationManager(
            onToken: (token) =>
                ref.read(apiProvider).addNotificationToken(token),
            onDeepLink: _goRouter.go,
          );
          _notificationManager?.requestNotificationPermission();
        }
      },
      fireImmediately: true,
    );
  }

  void _initInAppNotifications() {
    final uidProvider = authProvider.select((p) {
      return p.map(
        guest: (_) => null,
        signedIn: (signedIn) => signedIn.uid,
      );
    });

    ref.listenManual<String?>(uidProvider, (previous, next) {
      _inAppNotificationsApi?.dispose();

      final uid = next;
      if (uid == null) {
        return;
      }
      _inAppNotificationsApi = InAppNotificationsApi(
        host: host,
        port: socketPort,
        uid: uid,
        onCollectionReady: (collectionId) async {
          ref.read(collectionReadyProvider.notifier).collectionId(collectionId);
          final api = ref.read(apiProvider);
          final result = await api.getCollection(collectionId);
          result.fold(
            (l) => null,
            (r) {
              final userState = ref.read(userProvider);
              final collections = userState.map(
                guest: (_) => <Collection>[],
                signedIn: (signedIn) => signedIn.collections ?? [],
              );
              final index =
                  collections.indexWhere((c) => c.collectionId == collectionId);
              if (index != -1) {
                collections[index] = r.collection;
              }
            },
          );
        },
        onUnreadCountUpdated: (count) {
          ref.read(unreadCountProvider.notifier).updateUnreadCount(count);
          ref.read(userProvider.notifier).cacheChatrooms();
        },
      );
    });
  }

  void _initDynamicConfig() {
    ref.listenManual(
      dynamicConfigProvider,
      (previous, next) {
        // Listening just to force it to be created
      },
      fireImmediately: true,
    );
  }

  @override
  void reassemble() {
    super.reassemble();
    FocusScope.of(context).unfocus();
  }

  @override
  void dispose() {
    _notificationManager?.dispose();
    _inAppNotificationsApi?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = ThemeData().textTheme;
    return ProviderScope(
      child: MaterialApp.router(
        routerConfig: _goRouter,
        theme: ThemeData(
          primaryColor: const Color.fromRGBO(0xFF, 0x3E, 0x3E, 1.0),
          colorScheme: const ColorScheme.dark(
            primary: Colors.white,
            secondary: Colors.white,
          ),
          scaffoldBackgroundColor: Colors.black,
          fontFamily: 'SF Pro',
          textTheme: textTheme.copyWith(
            bodyMedium: textTheme.bodyMedium!.copyWith(
              fontFamily: 'SF Pro',
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
          ),
          iconTheme: const IconThemeData(
            color: Colors.white,
          ),
        ),
        builder: (context, child) {
          return CupertinoTheme(
            data: const CupertinoThemeData(
              brightness: Brightness.dark,
              primaryColor: Colors.white,
            ),
            child: child!,
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
      redirect: _redirectGuestsToSignUp,
      errorBuilder: (context, state) => const ErrorScreen(),
      routes: [
        GoRoute(
          path: '/',
          name: 'initial_loading',
          builder: (context, state) => const InitialLoadingPage(),
        ),
        GoRoute(
          path: '/signup',
          name: 'signup',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const SignupPhone(),
          routes: [
            GoRoute(
              path: 'verify',
              name: 'signup_verify',
              parentNavigatorKey: rootNavigatorKey,
              builder: (context, state) {
                final verificationId = state.queryParams['verificationId'];
                if (verificationId == null) {
                  throw 'Missing verification ID';
                }
                return SignupVerify(
                  verificationId: verificationId,
                );
              },
            ),
          ],
        ),
        GoRoute(
          path: '/signup_permissions',
          name: 'signup_permissions',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const SignupPermissionsScreen(),
          routes: [
            GoRoute(
              path: 'profile',
              name: 'signup_profile',
              builder: (context, state) => const SignupProfile(),
            ),
          ],
        ),
        GoRoute(
          path: '/signup_rules',
          name: 'signup_rules',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const SignupRules(),
        ),
        StatefulShellRoute(
          builder: (builder) {
            return builder.buildShell(
              (context, state, navigatorContainer) {
                return TabShell(
                  index: StatefulShellRouteState.of(context).currentIndex,
                  onNavigateToTab: (index) =>
                      StatefulShellRouteState.of(context)
                          .goBranch(index: index),
                  children: navigatorContainer.children,
                );
              },
            );
          },
          branches: [
            StatefulShellBranch(
              navigatorKey: _discoverKey,
              preload: true,
              routes: [
                GoRoute(
                  path: '/discover',
                  name: 'discover',
                  builder: (context, state) => const DiscoverListPage(),
                ),
              ],
            ),
            StatefulShellBranch(
              navigatorKey: _conversationsKey,
              preload: true,
              routes: [
                GoRoute(
                  path: '/chats',
                  name: 'chats',
                  builder: (context, state) => const ConversationsPage(),
                  routes: [
                    GoRoute(
                      path: ':uid',
                      name: 'chat',
                      parentNavigatorKey: rootNavigatorKey,
                      builder: (context, state) {
                        final otherUid = state.params['uid']!;
                        final args = state.extra as ChatPageArguments?;
                        return ChatPage(
                          host: host,
                          webPort: webPort,
                          socketPort: socketPort,
                          otherUid: otherUid,
                          chatroom: args?.chatroom,
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
            StatefulShellBranch(
              navigatorKey: _eventsKey,
              preload: true,
              routes: [
                GoRoute(
                  path: '/meetups',
                  name: 'meetups',
                  builder: (context, state) {
                    final viewMap = state.queryParams['view_map'] == 'true';
                    return EventsPage(
                      viewMap: viewMap,
                    );
                  },
                  routes: [
                    GoRoute(
                      path: 'create',
                      name: 'meetups_create',
                      parentNavigatorKey: rootNavigatorKey,
                      builder: (context, state) {
                        final args = state.extra as EventCreateArgs?;
                        final editEvent = args?.editEvent;
                        return EventCreatePage(
                          editEvent: editEvent,
                        );
                      },
                      routes: [
                        GoRoute(
                          path: 'preview',
                          name: 'event_preview',
                          parentNavigatorKey: rootNavigatorKey,
                          builder: (context, state) {
                            final args = state.extra as EventPreviewPageArgs;
                            return EventPreviewPage(
                              event: args.event,
                              submission: args.submission,
                            );
                          },
                        ),
                      ],
                    ),
                    GoRoute(
                      path: ':id',
                      name: 'event_view',
                      parentNavigatorKey: rootNavigatorKey,
                      builder: (context, state) {
                        final args = state.extra as EventViewPageArgs;
                        return EventViewPage(
                          event: args.event,
                        );
                      },
                    ),
                    GoRoute(
                      path: 'view',
                      name: 'view_profile',
                      builder: (context, state) {
                        final uid = state.queryParams['uid'];
                        final args = state.extra as ViewProfilePageArguments?;
                        if (args != null) {
                          return ViewProfilePage(args: args);
                        } else if (uid != null) {
                          return ViewProfilePage(
                            args: ViewProfilePageArguments.uid(uid: uid),
                          );
                        } else {
                          throw 'Missing page arguments';
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
            StatefulShellBranch(
              navigatorKey: _profileKey,
              preload: true,
              routes: [
                GoRoute(
                  path: '/account',
                  name: 'account',
                  builder: (context, state) {
                    return const ProfilePage();
                  },
                  routes: [
                    GoRoute(
                      path: 'meetups',
                      name: 'my_meetups',
                      parentNavigatorKey: rootNavigatorKey,
                      builder: (context, state) {
                        return const MyMeetupsPage();
                      },
                    ),
                    GoRoute(
                      path: 'calendar',
                      name: 'calendar',
                      parentNavigatorKey: rootNavigatorKey,
                      builder: (context, state) {
                        return const CalendarPage();
                      },
                    ),
                    GoRoute(
                      path: 'settings',
                      name: 'settings',
                      parentNavigatorKey: rootNavigatorKey,
                      builder: (context, state) {
                        return const SettingsPage();
                      },
                      routes: [
                        GoRoute(
                          path: 'contacts',
                          name: 'contacts',
                          parentNavigatorKey: rootNavigatorKey,
                          builder: (context, state) {
                            return const ContactsPage();
                          },
                        ),
                        GoRoute(
                          path: 'blocked',
                          name: 'blocked',
                          parentNavigatorKey: rootNavigatorKey,
                          builder: (context, state) {
                            return const BlockedUsersPage();
                          },
                        ),
                        GoRoute(
                          path: 'contact_us',
                          name: 'contact_us',
                          parentNavigatorKey: rootNavigatorKey,
                          builder: (context, state) {
                            return const ContactUsScreen();
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
        GoRoute(
          path: '/report',
          name: 'report',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) {
            final args = state.extra as ReportScreenArguments;
            return ReportScreen(
              uid: args.uid,
            );
          },
        ),
      ],
    );
  }

  FutureOr<String>? _redirectGuestsToSignUp(
    BuildContext context,
    GoRouterState state,
  ) {
    // Initial loading page redirects by itself
    if (state.location == '/') {
      return null;
    }

    // No need to redirect away from signup
    if (state.location.startsWith('/signup')) {
      return null;
    }

    final userState = ref.read(userProvider);
    return userState.map(
      guest: (guest) {
        // TODO: Pass along the redirect location to initial loading page
        if (guest.byDefault) {
          return '/';
        }
        return '/signup';
      },
      signedIn: (_) => null,
    );
  }
}
