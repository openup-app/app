import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:openup/chat_page.dart';
import 'package:openup/contact_us_screen.dart';
import 'package:openup/discover_page.dart';
import 'package:openup/dynamic_config/dynamic_config.dart';
import 'package:openup/error_screen.dart';
import 'package:openup/contacts_page.dart';
import 'package:openup/notifications/notifications.dart';
import 'package:openup/profile_page.dart';
import 'package:openup/conversations_page.dart';
import 'package:openup/report_screen.dart';
import 'package:openup/shell_page.dart';
import 'package:openup/signup_age.dart';
import 'package:openup/signup_gender.dart';
import 'package:openup/signup_name.dart';
import 'package:openup/signup_permissions.dart';
import 'package:openup/signup_phone.dart';
import 'package:openup/signup_verify.dart';
import 'package:openup/signup_audio.dart';
import 'package:openup/signup_photos.dart';
import 'package:openup/signup_friends.dart';
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

final _pageNotifierProvider =
    StateNotifierProvider<_PageNotifier, int>((ref) => _PageNotifier());

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

    final sharedPreferences = await SharedPreferences.getInstance();

    runApp(
      RestartApp(
        child: ProviderScope(
          overrides: [
            mixpanelProvider.overrideWithValue(mixpanel),
            apiProvider.overrideWith((ref) {
              Random().nextInt(1 << 32).toString();
              return Api(
                host: host,
                port: webPort,
              );
            }),
            keyValueStoreProvider.overrideWithValue(sharedPreferences),
          ],
          child: const OnlineUsersWatcher(
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
  final _settingsKey = GlobalKey<NavigatorState>();

  final rootNavigatorKey = GlobalKey<NavigatorState>();

  NotificationManager? _notificationManager;
  InAppNotificationsApi? _inAppNotificationsApi;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

    _initNotifications();
    _initInAppNotifications();
    _initDynamicConfig();

    _goRouter = _initGoRouter(
      observers: [_routeObserver],
    );
  }

  void _initNotifications() {
    ref.listenManual<bool>(
      userProvider2.select((p) {
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
              final userState = ref.read(userProvider2);
              final collections = userState.map(
                guest: (_) => <Collection>[],
                signedIn: (signedIn) => signedIn.collections ?? [],
              );
              final index =
                  collections.indexWhere((c) => c.collectionId == collectionId);
              if (index != -1) {
                collections[index] = r.collection;
              }
              ref.read(userProvider.notifier).collections(collections);
            },
          );
        },
        onUnreadCountUpdated: (count) {
          ref.read(unreadCountProvider.notifier).updateUnreadCount(count);
          ref.read(userProvider2.notifier).cacheChatrooms();
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
          colorScheme: const ColorScheme.light(
            primary: Color.fromRGBO(0xFF, 0x3E, 0x3E, 1.0),
            secondary: Color.fromARGB(0xAA, 0xFF, 0x71, 0x71),
          ),
          fontFamily: 'Neue Haas Unica',
          textTheme: textTheme.copyWith(
            bodyMedium: textTheme.bodyMedium!.copyWith(
              fontFamily: 'Neue Haas Unica',
              color: Colors.black,
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
          ),
          iconTheme: const IconThemeData(
            color: Colors.black,
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
      initialLocation: '/discover',
      redirect: (context, state) {
        return null;
      },
      errorBuilder: (context, state) => const ErrorScreen(),
      routes: [
        GoRoute(
          path: '/signup',
          name: 'signup',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) {
            final verified = state.queryParams['verified'] == 'true';
            return SignupPhone(
              verified: verified,
            );
          },
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
            GoRoute(
              path: 'age',
              name: 'signup_age',
              parentNavigatorKey: rootNavigatorKey,
              builder: (context, state) => const SignupAge(),
              routes: [
                GoRoute(
                  path: 'permissions',
                  name: 'signup_permissions',
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (context, state) => const SignupPermissionsScreen(),
                  routes: [
                    GoRoute(
                      path: 'name',
                      name: 'signup_name',
                      builder: (context, state) => const SignupName(),
                      routes: [
                        GoRoute(
                          path: 'gender',
                          name: 'signup_gender',
                          builder: (context, state) => const SignupGender(),
                          routes: [
                            GoRoute(
                              path: 'photos',
                              name: 'signup_photos',
                              builder: (context, state) => const SignupPhotos(),
                              routes: [
                                GoRoute(
                                  path: 'audio',
                                  name: 'signup_audio',
                                  builder: (context, state) =>
                                      const SignupAudio(),
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
          ],
        ),
        GoRoute(
          path: '/signup_friends',
          name: 'signup_friends',
          builder: (context, state) => const SignUpFriends(),
        ),
        StatefulShellRoute(
          builder: (builder) {
            return builder.buildShell(
              (context, state, child) {
                return _Shell(
                  children: child.children,
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
                  builder: (context, state) {
                    return DiscoverPage(
                      onShowConversations: () => ref
                          .read(_pageNotifierProvider.notifier)
                          .changePage(1),
                      onShowSettings: () => ref
                          .read(_pageNotifierProvider.notifier)
                          .changePage(2),
                    );
                  },
                  routes: [
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
              navigatorKey: _settingsKey,
              preload: true,
              routes: [
                GoRoute(
                  path: '/settings',
                  name: 'settings',
                  builder: (context, state) {
                    return const ProfilePage();
                  },
                  routes: [
                    GoRoute(
                      path: 'contacts',
                      name: 'contacts',
                      builder: (context, state) {
                        return const ContactsPage();
                      },
                    ),
                    GoRoute(
                      path: 'blocked',
                      name: 'blocked',
                      builder: (context, state) {
                        return const BlockedUsersPage();
                      },
                    ),
                    GoRoute(
                      path: 'contact_us',
                      name: 'contact_us',
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
}

class _Shell extends ConsumerStatefulWidget {
  final List<Widget> children;

  const _Shell({
    super.key,
    required this.children,
  });

  @override
  ConsumerState<_Shell> createState() => _ShellState();
}

class _ShellState extends ConsumerState<_Shell> {
  int _index = 0;
  final _shellPageKey = GlobalKey<ShellPageState>();

  @override
  void initState() {
    super.initState();
    ref.listenManual<int>(
      _pageNotifierProvider,
      (previous, next) {
        if (next != _index) {
          setState(() => _index = next);
          StatefulShellRouteState.of(context).goBranch(index: _index);
          if (_index != 0) {
            _shellPageKey.currentState?.showSheet();
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ShellPage(
      key: _shellPageKey,
      currentIndex: _index == 0 ? null : (_index - 1),
      shellBuilder: (context) => widget.children[0],
      onClosePage: () => ref.read(_pageNotifierProvider.notifier).changePage(0),
      children: widget.children.sublist(1),
    );
  }
}

class _PageNotifier extends StateNotifier<int> {
  _PageNotifier() : super(0);

  void changePage(int index) => state = index;
}
