import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';

import 'package:go_router/go_router.dart';
import 'package:openup/api/online_users_api.dart';
import 'package:openup/api/online_users_api_util.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/discover_page.dart';
import 'package:openup/main.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';

class HomeShell extends ConsumerStatefulWidget {
  final int tabIndex;
  final TempFriendshipsRefresh tempFriendshipsRefresh;
  final ScrollToDiscoverTopNotifier scrollToDiscoverTopNotifier;
  final Widget child;
  const HomeShell({
    Key? key,
    required this.tabIndex,
    required this.tempFriendshipsRefresh,
    required this.scrollToDiscoverTopNotifier,
    required this.child,
  }) : super(key: key);

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell>
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
  void didUpdateWidget(covariant HomeShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tabIndex != widget.tabIndex) {
      currentTabNotifier.value = HomeTab.values[widget.tabIndex];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBody: true,
      resizeToAvoidBottomInset: false,
      bottomNavigationBar: _NavigationBar(
        tabIndex: widget.tabIndex,
        paddingTop: MediaQuery.of(context).padding.top,
        onDiscoverPressed: () {
          if (widget.tabIndex == 0) {
            widget.scrollToDiscoverTopNotifier.scrollToTop();
          }
        },
        // Notifications don't update the UI, this forces it
        onFriendshipsPressed: widget.tempFriendshipsRefresh.refresh,
      ),
      body: widget.child,
    );
  }
}

class _NavigationBar extends StatelessWidget {
  final int tabIndex;
  final double paddingTop;
  final VoidCallback onDiscoverPressed;
  final VoidCallback onFriendshipsPressed;

  const _NavigationBar({
    super.key,
    required this.tabIndex,
    required this.paddingTop,
    required this.onDiscoverPressed,
    required this.onFriendshipsPressed,
  });

  @override
  Widget build(BuildContext context) {
    // BottomNavigationBar height is available to pages via MediaQuery bottom padding
    final obscuredTop = 55.0 + paddingTop;
    final obscuredBottom = 40.0 + MediaQuery.of(context).padding.bottom;
    final obscuredHeight = max(obscuredTop, obscuredBottom);
    return SizedBox(
      height: obscuredHeight,
      child: BlurredSurface(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Button(
                onPressed: () {
                  context.goNamed('discover');
                  onDiscoverPressed();
                },
                child: Center(
                  child: Text(
                    'Discover',
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontSize: 20,
                          fontWeight: tabIndex != 0 ? FontWeight.w300 : null,
                        ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Button(
                onPressed: () {
                  context.goNamed('friendships');
                  onFriendshipsPressed();
                },
                child: Center(
                  child: Text(
                    'Friendships',
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontSize: 20,
                          fontWeight: tabIndex != 1 ? FontWeight.w300 : null,
                        ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Button(
                onPressed: () => context.goNamed('profile'),
                child: Center(
                  child: Text(
                    'Profile',
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontSize: 20,
                          fontWeight: tabIndex != 2 ? FontWeight.w300 : null,
                        ),
                  ),
                ),
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
