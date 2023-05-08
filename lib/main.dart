import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';
import 'package:openup/account_settings_screen.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/call_manager.dart';
import 'package:openup/api/in_app_notifications.dart';
import 'package:openup/api/online_users_api.dart';
import 'package:openup/api/online_users_api_util.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/chat_page.dart';
import 'package:openup/discover_page.dart';
import 'package:openup/error_screen.dart';
import 'package:openup/initial_loading_screen.dart';
import 'package:openup/notifications/ios_voip_handlers.dart' as ios_voip;
import 'package:openup/notifications/notifications.dart';
import 'package:openup/people_page.dart';
import 'package:openup/profile_page.dart';
import 'package:openup/conversations_page.dart';
import 'package:openup/report_screen.dart';
import 'package:openup/sign_up_gender.dart';
import 'package:openup/sign_up_name.dart';
import 'package:openup/sign_up_permissions.dart';
import 'package:openup/sign_up_phone.dart';
import 'package:openup/sign_up_verify.dart';
import 'package:openup/signup_collection_audio.dart';
import 'package:openup/signup_collection_photos.dart';
import 'package:openup/signup_collection_photos_preview.dart';
import 'package:openup/signup_friends.dart';
import 'package:openup/signup_tutorial.dart';
import 'package:openup/util/page_transition.dart';
import 'package:openup/sign_up_age.dart';
import 'package:openup/view_collection_page.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/menu_page.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/system_ui_styling.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

const host = String.fromEnvironment('HOST');
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
    GetIt.instance.registerSingleton<Mixpanel>(mixpanel);
    mixpanel.setLoggingEnabled(!kReleaseMode);

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
  bool _loggedIn = false;
  StreamSubscription? _idTokenChangesSubscription;
  StreamSubscription? _notificationTokenSubscription;

  late final GoRouter _goRouter;
  final _routeObserver = RouteObserver<PageRoute>();

  final _discoverKey = GlobalKey<NavigatorState>();
  final _conversationsKey = GlobalKey<NavigatorState>();
  final _profileKey = GlobalKey<NavigatorState>();
  final _peopleKey = GlobalKey<NavigatorState>();
  final _settingsKey = GlobalKey<NavigatorState>();

  final _scrollToDiscoverTopNotifier = ScrollToDiscoverTopNotifier();

  InAppNotificationsApi? _inAppNotificationsApi;

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

    GetIt.instance.registerSingleton<OnlineUsersApi>(
      OnlineUsersApi(
        host: host,
        port: socketPort,
        onConnectionError: () {},
        onOnlineStatusChanged: (uid, online) {
          ref.read(onlineUsersProvider.notifier).onlineChanged(uid, online);
        },
      ),
    );

    // Logging in/out triggers
    _idTokenChangesSubscription =
        FirebaseAuth.instance.idTokenChanges().listen((user) async {
      final loggedIn = user != null;
      if (_loggedIn != loggedIn) {
        setState(() => _loggedIn = loggedIn);

        // Mixpanel
        final mixpanel = GetIt.instance.get<Mixpanel>();
        if (user != null) {
          mixpanel.identify(user.uid);
          Sentry.configureScope(
              (scope) => scope.setUser(SentryUser(id: user.uid)));
        } else {
          mixpanel.reset();
          Sentry.configureScope((scope) => scope.setUser(null));
        }

        if (loggedIn) {
          _inAppNotificationsApi = InAppNotificationsApi(
            host: host,
            port: socketPort,
            uid: user.uid,
            onCollectionReady: (collectionId) async {
              ref
                  .read(collectionReadyProvider.notifier)
                  .collectionId(collectionId);
              final result = await api.getCollection(collectionId);
              result.fold(
                (l) => null,
                (r) {
                  final userState = ref.read(userProvider2);
                  final collections = userState.map(
                    guest: (_) => <Collection>[],
                    signedIn: (signedIn) => signedIn.collections ?? [],
                  );
                  final index = collections
                      .indexWhere((c) => c.collectionId == collectionId);
                  if (index != -1) {
                    collections[index] = r.collection;
                  }
                  ref.read(userProvider.notifier).collections(collections);
                },
              );
            },
          );
        } else {
          _inAppNotificationsApi?.dispose();
        }
      }

      // Firebase ID token refresh
      if (user != null) {
        try {
          final token = await user.getIdToken();
          if (mounted) {
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

      // Online indicator
      final onlineUsersApi = GetIt.instance.get<OnlineUsersApi>();
      if (_loggedIn) {
        onlineUsersApi.setOnline(ref.read(userProvider).uid, true);
      } else {
        onlineUsersApi.setOnline(ref.read(userProvider).uid, false);
      }

      // Notifications (subsequent messaging tokens)
      if (_loggedIn) {
        final isIOS = Platform.isIOS;
        await initializeNotifications();
        _notificationTokenSubscription =
            onNotificationMessagingToken.listen((token) async {
          debugPrint('On notification token: $token');
          final uid = ref.read(userProvider).uid;
          if (token != null && uid.isNotEmpty) {
            api.addNotificationTokens(
              ref.read(userProvider).uid,
              fcmMessagingAndVoipToken: isIOS ? null : token,
              apnMessagingToken: isIOS ? token : null,
              // Voip token not sending in InitialLoadingScreen, so tries here
              apnVoipToken:
                  isIOS ? await ios_voip.getVoipPushNotificationToken() : null,
            );
          }
        });
      } else {
        _notificationTokenSubscription?.cancel();
        disposeNotifications();
      }
    });
  }

  @override
  void dispose() {
    _idTokenChangesSubscription?.cancel();
    _notificationTokenSubscription?.cancel();
    disposeNotifications();

    _scrollToDiscoverTopNotifier.dispose();

    final onlineUsersApi = GetIt.instance.get<OnlineUsersApi>();
    GetIt.instance.unregister<OnlineUsersApi>();
    onlineUsersApi.dispose();

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
            child: Stack(
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
                                  height:
                                      40 + MediaQuery.of(context).padding.top,
                                  color: const Color.fromRGBO(
                                      0x03, 0xCB, 0x17, 1.0),
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
            ),
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
      redirect: (context, state) {
        return null;
      },
      errorBuilder: (context, state) {
        final args = state.extra as InitialLoadingScreenArguments?;
        return CurrentRouteSystemUiStyling.dark(
          child: ErrorScreen(
            needsOnboarding: args?.needsOnboarding ?? false,
          ),
        );
      },
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
          path: '/signup',
          name: 'signup',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) {
            return const CurrentRouteSystemUiStyling.light(
              child: SignUpAge(),
            );
          },
          routes: [
            GoRoute(
              path: 'permissions',
              name: 'signup_permissions',
              parentNavigatorKey: rootNavigatorKey,
              builder: (context, state) {
                return const CurrentRouteSystemUiStyling.light(
                  child: SignUpPermissionsScreen(),
                );
              },
            ),
            GoRoute(
              path: 'phone',
              name: 'signup_phone',
              parentNavigatorKey: rootNavigatorKey,
              builder: (context, state) {
                final verifiedUid = state.queryParams['verifiedUid'];
                return CurrentRouteSystemUiStyling.light(
                  child: SignUpPhone(
                    verifiedUid: verifiedUid,
                  ),
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
                    return CurrentRouteSystemUiStyling.light(
                      child: SignUpVerify(
                        verificationId: verificationId,
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/signup_name',
          name: 'signup_name',
          builder: (context, state) {
            return const CurrentRouteSystemUiStyling.light(
              child: SignUpName(),
            );
          },
          routes: [
            GoRoute(
              path: 'gender',
              name: 'signup_gender',
              builder: (context, state) {
                return const CurrentRouteSystemUiStyling.light(
                  child: SignUpGender(),
                );
              },
              routes: [
                GoRoute(
                  path: 'tutorial',
                  name: 'signup_tutorial',
                  builder: (context, state) {
                    return const CurrentRouteSystemUiStyling.light(
                      child: SignUpTutorial(),
                    );
                  },
                  routes: [
                    GoRoute(
                      path: 'photos',
                      name: 'signup_collection_photos',
                      builder: (context, state) {
                        return const CurrentRouteSystemUiStyling.light(
                          child: SignupCollectionPhotos(),
                        );
                      },
                      routes: [
                        GoRoute(
                          path: 'preview',
                          name: 'signup_collection_photos_preview',
                          builder: (context, state) {
                            final args = state.extra
                                as SignupCollectionPhotosPreviewArgs;
                            return CurrentRouteSystemUiStyling.light(
                              child: SignupCollectionPhotosPreview(
                                photos: args.photos,
                              ),
                            );
                          },
                          routes: [
                            GoRoute(
                              path: 'audio',
                              name: 'signup_collection_audio',
                              builder: (context, state) {
                                final args =
                                    state.extra as SignupCollectionAudioArgs;
                                return CurrentRouteSystemUiStyling.light(
                                  child: SignupCollectionAudio(
                                    photos: args.photos,
                                  ),
                                );
                              },
                              routes: [
                                GoRoute(
                                  path: 'friends',
                                  name: 'signup_friends',
                                  builder: (context, state) {
                                    return const CurrentRouteSystemUiStyling
                                        .light(
                                      child: SignUpFriends(),
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
          ],
        ),
        StatefulShellRoute(
          builder: (builder) {
            return builder.buildShell(
              (context, state, child) {
                return _MenuPageShell(
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
                    final showWelcome = state.queryParams['welcome'] == 'true';
                    return DiscoverPage(
                      scrollToTopNotifier: _scrollToDiscoverTopNotifier,
                      showWelcome: showWelcome,
                    );
                  },
                  routes: [
                    GoRoute(
                      path: 'collections',
                      name: 'view_collection',
                      builder: (context, state) {
                        final collectionId = state.queryParams['collection_id'];
                        final uid = state.queryParams['uid'];
                        final args =
                            state.extra as ViewCollectionPageArguments?;
                        if (args != null) {
                          return ViewCollectionPage(args: args);
                        } else if (uid != null) {
                          return ViewCollectionPage(
                            args: ViewCollectionPageArguments.uid(uid: uid),
                          );
                        } else if (collectionId != null) {
                          return ViewCollectionPage(
                            args: ViewCollectionPageArguments.collectionId(
                              collectionId: collectionId,
                            ),
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
              navigatorKey: _profileKey,
              preload: true,
              routes: [
                GoRoute(
                  path: '/profile',
                  name: 'profile',
                  builder: (context, state) => const ProfilePage(),
                ),
              ],
            ),
            StatefulShellBranch(
              navigatorKey: _peopleKey,
              preload: true,
              routes: [
                GoRoute(
                  path: '/people',
                  name: 'people',
                  builder: (context, state) {
                    return const PeoplePage();
                  },
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
                    return const CurrentRouteSystemUiStyling.light(
                      child: AccountSettingsScreen(),
                    );
                  },
                ),
              ],
            )
          ],
        ),
        GoRoute(
          path: '/report',
          name: 'report',
          parentNavigatorKey: rootNavigatorKey,
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

class _MenuPageShell extends StatefulWidget {
  final List<Widget> children;

  const _MenuPageShell({
    super.key,
    required this.children,
  });

  @override
  State<_MenuPageShell> createState() => _MenuPageShellState();
}

class _MenuPageShellState extends State<_MenuPageShell> {
  final _menuPageKey = GlobalKey<MenuPageState>();
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return MenuPage(
      key: _menuPageKey,
      currentIndex: _currentIndex,
      menuBuilder: (context) {
        return _MenuTiles(
          onDiscoverPressed: () {
            setState(() => _currentIndex = 0);
            StatefulShellRouteState.of(context).goBranch(index: _currentIndex);
            _menuPageKey.currentState?.open();
          },
          onConversationsPressed: () {
            setState(() => _currentIndex = 1);
            StatefulShellRouteState.of(context).goBranch(index: _currentIndex);
            _menuPageKey.currentState?.open();
          },
          onProfilePressed: () {
            setState(() => _currentIndex = 2);
            StatefulShellRouteState.of(context).goBranch(index: _currentIndex);
            _menuPageKey.currentState?.open();
          },
          onContactsPressed: () {
            setState(() => _currentIndex = 3);
            StatefulShellRouteState.of(context).goBranch(index: _currentIndex);
            _menuPageKey.currentState?.open();
          },
          onSettingsPressed: () {
            setState(() => _currentIndex = 4);
            StatefulShellRouteState.of(context).goBranch(index: _currentIndex);
            _menuPageKey.currentState?.open();
          },
          onContactUsPressed: () {},
        );
      },
      pageTitleBuilder: (context) {
        final style = Theme.of(context).textTheme.bodyMedium!.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: const Color.fromRGBO(0x72, 0x72, 0x72, 1.0));
        if (_currentIndex == 0) {
          return Text(
            'Discovery',
            style: style,
          );
        } else if (_currentIndex == 1) {
          return const SizedBox.shrink();
        } else if (_currentIndex == 2) {
          return Text(
            'Profile',
            style: style,
          );
        } else if (_currentIndex == 3) {
          return Text(
            'Contacts',
            style: style,
          );
        } else if (_currentIndex == 4) {
          return Text(
            'Settings',
            style: style,
          );
        }
        return const SizedBox.shrink();
      },
      children: widget.children,
    );
  }
}

class _MenuTiles extends StatelessWidget {
  final VoidCallback onDiscoverPressed;
  final VoidCallback onConversationsPressed;
  final VoidCallback onProfilePressed;
  final VoidCallback onContactsPressed;
  final VoidCallback onSettingsPressed;
  final VoidCallback onContactUsPressed;

  const _MenuTiles({
    super.key,
    required this.onDiscoverPressed,
    required this.onConversationsPressed,
    required this.onProfilePressed,
    required this.onContactsPressed,
    required this.onSettingsPressed,
    required this.onContactUsPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        bottom: MediaQuery.of(context).padding.bottom,
      ),
      children: [
        const SizedBox(height: 11),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5.5, horizontal: 16),
          child: _MenuTileBorder(
            child: Consumer(
              builder: (context, ref, child) {
                final userState = ref.watch(userProvider2);
                return userState.map(
                  guest: (_) => const SizedBox.shrink(),
                  signedIn: (signedIn) {
                    final profile = signedIn.profile;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 21),
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage(
                              'assets/images/welcome_tile_background.png'),
                          fit: BoxFit.fill,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 7),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Welcome',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium!
                                      .copyWith(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.white),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  '21 days remaining',
                                  textAlign: TextAlign.right,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium!
                                      .copyWith(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            '${profile.name}!',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                    fontSize: 40,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'We want to thank you for joining Openup, please let us know how we can improve your experience of meeting new people! Any feedback is welcome, just tap the “send message” button.',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    height: 1.3,
                                    color: Colors.white),
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Button(
                              onPressed: onContactUsPressed,
                              child: Container(
                                width: 121,
                                height: 37,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(18.5),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      offset: Offset(0, 2),
                                      blurRadius: 10,
                                      color: Color.fromRGBO(
                                          0x00, 0x00, 0x00, 0.25),
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Subscribe now',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium!
                                      .copyWith(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.black),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5.5, horizontal: 16),
          child: _MenuTileBorder(
            child: _MenuTile(
              title: 'Discovery',
              subtitle: 'meet new people',
              icon: LottieBuilder.asset(
                'assets/images/friends.json',
                height: 42,
              ),
              onPressed: onDiscoverPressed,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5.5, horizontal: 16),
          child: _MenuTileBorder(
            child: _MenuTile(
              title: 'Conversations',
              subtitle: 'talk to your new connects',
              icon: const Icon(Icons.chat_bubble, size: 42),
              badge: Consumer(
                builder: (context, ref, child) {
                  return UnreadIndicator(
                    count: ref.watch(
                      userProvider2.select((p) => p.unreadCount),
                    ),
                  );
                },
              ),
              onPressed: onConversationsPressed,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5.5, horizontal: 16),
          child: _MenuTileBorder(
            child: _MenuTile(
              title: 'Profile',
              subtitle: 'update your photos and bio',
              icon: const Icon(Icons.face, size: 42),
              onPressed: onProfilePressed,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5.5, horizontal: 16),
          child: _MenuTileBorder(
            child: _MenuTile(
              title: 'Contacts',
              subtitle: 'add people you know',
              icon: const Icon(Icons.person_add, size: 42),
              onPressed: onContactsPressed,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5.5, horizontal: 16),
          child: _MenuTileBorder(
            child: _MenuTile(
              title: 'Settings',
              subtitle: 'account information',
              icon: const Icon(Icons.settings, size: 42),
              onPressed: onSettingsPressed,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 24.0, bottom: 4),
          child: Center(
            child: FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox.shrink();
                }
                return Text(
                  'Version: ${snapshot.requireData.version}',
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: const Color.fromRGBO(0xAD, 0xAD, 0xAD, 1.0),
                      ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget icon;
  final Widget? badge;
  final VoidCallback onPressed;

  const _MenuTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.badge,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Button(
      onPressed: onPressed,
      child: SizedBox(
        height: 77,
        child: Row(
          children: [
            const SizedBox(width: 31),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Colors.black),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: const Color.fromRGBO(0x94, 0x94, 0x94, 1.0)),
                  ),
                ],
              ),
            ),
            ColorFiltered(
              colorFilter: const ColorFilter.mode(
                Color.fromRGBO(0x66, 0x66, 0x66, 1.0),
                BlendMode.srcIn,
              ),
              child: icon,
            ),
            if (badge != null)
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: badge,
                ),
              )
            else
              const SizedBox(width: 23),
            const SizedBox(width: 23),
          ],
        ),
      ),
    );
  }
}

class _MenuTileBorder extends StatelessWidget {
  final Widget child;

  const _MenuTileBorder({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            offset: Offset(0.0, 0.0),
            blurRadius: 26,
            color: Color.fromRGBO(0x00, 0x00, 0x00, 0.05),
          )
        ],
      ),
      child: child,
    );
  }
}
