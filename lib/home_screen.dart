import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/discover_page.dart';
import 'package:openup/friendships_page.dart';
import 'package:openup/main.dart';
import 'package:openup/profile_page.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/system_ui_styling.dart';
import 'package:openup/widgets/theming.dart';

import 'chat_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final _friendshipsNavigatorKey = GlobalKey<NavigatorState>();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBody: true,
      bottomNavigationBar: SizedBox(
        height: 72.0 + MediaQuery.of(context).padding.bottom,
        child: BlurredSurface(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Button(
                child: Text(
                  'Discover',
                  style: Theming.of(context).text.body.copyWith(
                      fontWeight:
                          _tabController.index != 0 ? FontWeight.w300 : null),
                ),
                onPressed: () {
                  _tabController.index = 0;
                  setState(() {});
                },
              ),
              Button(
                child: Text(
                  'Friendships',
                  style: Theming.of(context).text.body.copyWith(
                      fontWeight:
                          _tabController.index != 1 ? FontWeight.w300 : null),
                ),
                onPressed: () {
                  _tabController.index = 1;
                  setState(() {});
                },
              ),
              Button(
                child: Text(
                  'Profile',
                  style: Theming.of(context).text.body.copyWith(
                      fontWeight:
                          _tabController.index != 2 ? FontWeight.w300 : null),
                ),
                onPressed: () {
                  _tabController.index = 2;
                  setState(() {});
                },
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          const DiscoverPage(),
          WillPopScope(
            onWillPop: () {
              print('will pop scope');
              return _friendshipsNavigatorKey.currentState?.maybePop() ??
                  Future.value(false);
            },
            child: Navigator(
              key: _friendshipsNavigatorKey,
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
                }
                return MaterialPageRoute(
                  settings: settings,
                  builder: (context) {
                    return Scaffold(
                      body: Center(
                        child: Text('Route ${settings.name} not found'),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Consumer(
            builder: (context, ref, _) {
              final profile = ref.watch(userProvider.select((p) => p.profile))!;
              return ProfilePage(profile: profile);
            },
          ),
        ],
      ),
    );
  }
}
