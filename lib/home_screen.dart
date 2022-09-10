import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/discover_page.dart';
import 'package:openup/error_screen.dart';
import 'package:openup/friendships_page.dart';
import 'package:openup/main.dart';
import 'package:openup/profile_page.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/system_ui_styling.dart';
import 'package:openup/widgets/theming.dart';

import 'chat_page.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final _navigatorKeys = List.generate(3, (_) => GlobalKey<NavigatorState>());

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: 3,
      initialIndex: 0,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _navigateTabTo(int index) {
    if (_tabController.index != index) {
      _tabController.index = index;
      setState(() {});
      currentTabNotifier.value = HomeTab.values[index];
    }
  }

  @override
  Widget build(BuildContext context) {
    // BottomNavigationBar height is available to pages via MediaQuery bottom padding
    final obscuredTop = 75.0 + MediaQuery.of(context).padding.top;
    final obscuredBottom = 40.0 + MediaQuery.of(context).padding.bottom;
    final obscuredHeight = max(obscuredTop, obscuredBottom);

    return WillPopScope(
      onWillPop: () {
        final key = _navigatorKeys[_tabController.index];
        if (key.currentState?.canPop() == true) {
          key.currentState?.pop(key.currentContext!);
          return Future.value(false);
        }
        return Future.value(true);
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBody: true,
        resizeToAvoidBottomInset: false,
        bottomNavigationBar: SizedBox(
          height: obscuredHeight,
          child: BlurredSurface(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Button(
                    onPressed: () => _navigateTabTo(0),
                    child: Center(
                      child: Text(
                        'Discover',
                        style: Theming.of(context).text.body.copyWith(
                            fontWeight: _tabController.index != 0
                                ? FontWeight.w300
                                : null),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Button(
                    onPressed: () => _navigateTabTo(1),
                    child: Center(
                      child: Text(
                        'Friendships',
                        style: Theming.of(context).text.body.copyWith(
                            fontWeight: _tabController.index != 1
                                ? FontWeight.w300
                                : null),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Button(
                    onPressed: () => _navigateTabTo(2),
                    child: Center(
                      child: Text(
                        'Profile',
                        style: Theming.of(context).text.body.copyWith(
                            fontWeight: _tabController.index != 2
                                ? FontWeight.w300
                                : null),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _KeepAlive(
              child: Navigator(
                key: _navigatorKeys[0],
                initialRoute: '/',
                onGenerateRoute: (settings) {
                  switch (settings.name) {
                    case '/':
                      return MaterialPageRoute(
                        settings: settings,
                        builder: (context) => const DiscoverPage(),
                      );
                    default:
                      return MaterialPageRoute(
                        settings: settings,
                        builder: (context) => const ErrorScreen(),
                      );
                  }
                },
              ),
            ),
            _KeepAlive(
              child: Navigator(
                key: _navigatorKeys[1],
                initialRoute: 'conversations',
                onGenerateRoute: (settings) {
                  switch (settings.name) {
                    case 'conversations':
                      return MaterialPageRoute(
                        settings: settings,
                        builder: (context) => const FriendshipsPage(),
                      );
                    case 'chat':
                      return MaterialPageRoute(
                        settings: settings,
                        builder: (context) {
                          final args = settings.arguments as ChatPageArguments;
                          return CurrentRouteSystemUiStyling.light(
                            child: ChatPage(
                              host: host,
                              webPort: webPort,
                              socketPort: socketPort,
                              otherProfile: args.otherProfile,
                              online: args.online,
                              endTime: args.endTime,
                            ),
                          );
                        },
                      );
                    default:
                      return MaterialPageRoute(
                        settings: settings,
                        builder: (context) => const ErrorScreen(),
                      );
                  }
                },
              ),
            ),
            _KeepAlive(
              child: Navigator(
                key: _navigatorKeys[2],
                initialRoute: 'profile',
                onGenerateRoute: (settings) {
                  switch (settings.name) {
                    case 'profile':
                      return MaterialPageRoute(
                        settings: settings,
                        builder: (context) {
                          return Consumer(
                            builder: (context, ref, _) {
                              final profile = ref.watch(
                                  userProvider.select((p) => p.profile))!;
                              return ProfilePage(profile: profile);
                            },
                          );
                        },
                      );
                    default:
                      return MaterialPageRoute(
                        settings: settings,
                        builder: (context) => const ErrorScreen(),
                      );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KeepAlive extends StatefulWidget {
  final Widget child;
  const _KeepAlive({
    super.key,
    required this.child,
  });

  @override
  State<_KeepAlive> createState() => __KeepAliveState();
}

class __KeepAliveState extends State<_KeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

final currentTabNotifier = ValueNotifier<HomeTab>(HomeTab.discover);

enum HomeTab { discover, friendships, profile }
