import 'package:flutter/material.dart';
import 'package:openup/discover_page.dart';
import 'package:openup/friendships_page.dart';
import 'package:openup/profile_page.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/theming.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

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
        children: const [
          DiscoverPage(),
          FriendshipsPage(),
          ProfilePage(),
        ],
      ),
    );
  }
}
