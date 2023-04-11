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
import 'package:openup/contact_us_screen.dart';
import 'package:openup/discover_page.dart';
import 'package:openup/error_screen.dart';
import 'package:openup/initial_loading_screen.dart';
import 'package:openup/invite_page.dart';
import 'package:openup/notifications/ios_voip_handlers.dart' as ios_voip;
import 'package:openup/notifications/notifications.dart';
import 'package:openup/people_page.dart';
import 'package:openup/profile_page2.dart';
import 'package:openup/relationships_page.dart';
import 'package:openup/report_screen.dart';
import 'package:openup/sign_up_audio_screen.dart';
import 'package:openup/sign_up_gender.dart';
import 'package:openup/sign_up_name.dart';
import 'package:openup/sign_up_name_screen.dart';
import 'package:openup/sign_up_permissions.dart';
import 'package:openup/sign_up_phone.dart';
import 'package:openup/sign_up_photos_screen.dart';
import 'package:openup/sign_up_start_animation.dart';
import 'package:openup/sign_up_topic_screen.dart';
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
import 'package:openup/sign_up_overview_page.dart';
import 'package:openup/menu_page.dart';
import 'package:openup/widgets/system_ui_styling.dart';
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
  StreamSubscription? _notificationTokenSubscription;

  late final GoRouter _goRouter;
  final _routeObserver = RouteObserver<PageRoute>();

  final _discoverKey = GlobalKey<NavigatorState>();
  final _relationshipsKey = GlobalKey<NavigatorState>();
  final _profileKey = GlobalKey<NavigatorState>();
  final _peopleKey = GlobalKey<NavigatorState>();

  final _tempRelationshipsRefresh = TempFriendshipsRefresh();

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
                  final collections =
                      List.of(ref.read(userProvider).collections);
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

    _tempRelationshipsRefresh.dispose();
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
          fontFamily: 'Neue Haas Unica W1G',
          textTheme: textTheme.copyWith(
            bodyMedium: textTheme.bodyMedium!.copyWith(
              fontFamily: 'Neue Haas Unica W1G',
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
              navigatorKey: _relationshipsKey,
              preload: true,
              routes: [
                GoRoute(
                  path: '/relationships',
                  name: 'relationships',
                  builder: (context, state) {
                    return RelationshipsPage(
                        tempRefresh: _tempRelationshipsRefresh);
                  },
                  routes: [
                    GoRoute(
                      path: 'chat/:uid',
                      name: 'chat',
                      builder: (context, state) {
                        final otherUid = state.params['uid']!;
                        final args = state.extra as ChatPageArguments?;
                        return ChatPage(
                          host: host,
                          webPort: webPort,
                          socketPort: socketPort,
                          otherUid: otherUid,
                          otherProfile: args?.otherProfile,
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
                  builder: (context, state) => const ProfilePage2(),
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
        GoRoute(
          path: '/account',
          name: 'account-settings',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) {
            return const CurrentRouteSystemUiStyling.light(
              child: AccountSettingsScreen(),
            );
          },
        ),
        GoRoute(
          path: '/contact_us',
          name: 'contact-us',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) {
            return const CurrentRouteSystemUiStyling.light(
              child: ContactUsScreen(),
            );
          },
        ),
        GoRoute(
          path: '/invite/:uid',
          name: 'invite',
          builder: (context, state) {
            final uid = state.params['uid']!;
            final args = state.extra as InvitePageArgs?;
            return InvitePage(
              uid: uid,
              profile: args?.profile,
              invitationAudio: args?.invitaitonAudio,
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
          onSettingsPressed: () => context.pushNamed('account-settings'),
          onContactUsPressed: () => context.pushNamed('contact-us'),
        );
      },
      pageTitleBuilder: (context) {
        final style = Theme.of(context).textTheme.bodyMedium!.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          shadows: const [
            Shadow(
              offset: Offset(0, 1),
              blurRadius: 4,
              color: Color.fromRGBO(
                0x00,
                0x00,
                0x00,
                0.25,
              ),
            ),
          ],
        );
        if (_currentIndex == 0) {
          return Text(
            'Discovery',
            style: style,
          );
        } else if (_currentIndex == 1) {
          return Text(
            'Conversations',
            style: style.copyWith(
              color: const Color.fromRGBO(0xFF, 0x71, 0x71, 1.0),
            ),
          );
        } else if (_currentIndex == 2) {
          return Text(
            'My Profile',
            style: style,
          );
        } else if (_currentIndex == 3) {
          return Text(
            'Contacts',
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
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 7.0, horizontal: 14),
          child: _MenuTileBorder(
            child: SizedBox(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 7),
                  Text(
                    'Welcome',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium!
                        .copyWith(fontSize: 16, fontWeight: FontWeight.w300),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Longhorns!',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium!
                        .copyWith(fontSize: 40, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'We want to thank you for joining Openup, please let us know how we can improve your experience of meeting new people! Any feedback is welcome, just tap the “send message” button.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium!
                        .copyWith(fontSize: 16, fontWeight: FontWeight.w300),
                  ),
                  const SizedBox(height: 6),
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
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'send message',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium!
                              .copyWith(fontSize: 14, color: Colors.black),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7.0),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(7),
                  child: _MenuTileBorder(
                    child: _MenuTile(
                      title: 'Discover',
                      subtitle: 'meet new people',
                      icon: LottieBuilder.asset(
                        'assets/images/friends.json',
                        height: 50,
                      ),
                      onPressed: onDiscoverPressed,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(7),
                  child: _MenuTileBorder(
                    child: _MenuTile(
                      title: 'Conversations',
                      subtitle: 'talk to people',
                      icon: const Icon(Icons.chat_bubble, size: 50),
                      badge: Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.red,
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          '1',
                          textAlign: TextAlign.center,
                        ),
                      ),
                      onPressed: onConversationsPressed,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7.0),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(7),
                  child: _MenuTileBorder(
                    child: _MenuTile(
                      title: 'My Profile',
                      subtitle: 'update your pics and bio',
                      icon: const Icon(Icons.face, size: 50),
                      onPressed: onProfilePressed,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(7),
                  child: _MenuTileBorder(
                    child: _MenuTile(
                      title: 'Contacts',
                      subtitle: 'add people u know',
                      icon: const Icon(Icons.person_add, size: 50),
                      onPressed: onContactsPressed,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7.0),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(7),
                  child: _MenuTileBorder(
                    child: _MenuTile(
                      title: 'Settings',
                      subtitle: 'change your account info',
                      icon: const Icon(Icons.settings, size: 50),
                      onPressed: onSettingsPressed,
                    ),
                  ),
                ),
              ),
              const Expanded(
                child: SizedBox.shrink(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
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
        height: 219,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (badge != null)
              Align(
                alignment: Alignment.centerRight,
                child: badge,
              ),
            const Spacer(),
            icon,
            const SizedBox(height: 14),
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium!
                  .copyWith(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 7),
            Text(
              subtitle,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium!
                  .copyWith(fontSize: 12, fontWeight: FontWeight.w300),
            ),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 21),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(24)),
        color: Color.fromRGBO(0x00, 0x00, 0x00, 0.5),
        boxShadow: [
          BoxShadow(
            offset: Offset(0.0, 2.0),
            blurRadius: 7,
            color: Color.fromRGBO(0x00, 0x00, 0x00, 0.25),
          )
        ],
      ),
      child: child,
    );
  }
}
