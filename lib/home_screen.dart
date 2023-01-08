import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:openup/discover_page.dart';
import 'package:openup/main.dart';

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
      body: widget.child,
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
