import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:openup/widgets/profile_button.dart';
import 'package:openup/widgets/scaffold.dart';
import 'package:openup/widgets/app_lifecycle.dart';
import 'package:openup/widgets/button.dart';

final _pageNotifierProvider =
    StateNotifierProvider<_PageNotifier, int>((ref) => _PageNotifier());

class _PageNotifier extends StateNotifier<int> {
  _PageNotifier() : super(0);

  void changePage(int index) => state = index;
}

class TabShell extends ConsumerStatefulWidget {
  final int index;
  final void Function(int index) onNavigateToTab;
  final List<Widget> children;

  const TabShell({
    super.key,
    required this.index,
    required this.onNavigateToTab,
    required this.children,
  });

  @override
  ConsumerState<TabShell> createState() => _TabShellState();
}

class _TabShellState extends ConsumerState<TabShell> {
  @override
  void initState() {
    super.initState();
    ref.listenManual<int>(
      _pageNotifierProvider,
      (previous, next) {
        if (next != widget.index) {
          widget.onNavigateToTab(next);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQueryData = MediaQuery.of(context);
    final bottomBarHeight =
        OpenupBottomBar.kBaseHeight + MediaQuery.of(context).padding.bottom;
    return Stack(
      fit: StackFit.expand,
      children: [
        MediaQuery(
          data: mediaQueryData.copyWith(
            padding: mediaQueryData.padding.copyWith(bottom: bottomBarHeight),
          ),
          child: IndexedStack(
            index: widget.index,
            children: [
              for (var i = 0; i < widget.children.length; i++)
                _BranchIndex(
                  index: i,
                  child: widget.children[i],
                ),
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: OpenupBottomBar(
            child: _Tabs(
              index: widget.index,
              onTabPressed: widget.onNavigateToTab,
            ),
          ),
        ),
      ],
    );
  }
}

class _Tabs extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTabPressed;

  const _Tabs({
    super.key,
    required this.index,
    required this.onTabPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: _NavButton(
                icon: SvgPicture.asset('assets/images/nav_icon_people.svg'),
                label: const Text('People'),
                selected: index == 0,
                onPressed: () => onTabPressed(0),
              ),
            ),
            Expanded(
              child: _NavButton(
                icon: SvgPicture.asset('assets/images/nav_icon_messages.svg'),
                label: const Text('Messages'),
                selected: index == 1,
                onPressed: () => onTabPressed(1),
              ),
            ),
            Expanded(
              child: _NavButton(
                enableFilterOnIcon: false,
                icon: Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color.fromRGBO(0xEE, 0xEE, 0xEE, 1.0),
                  ),
                  child: const Icon(
                    Icons.add,
                    size: 20,
                    color: Colors.black,
                  ),
                ),
                label: const Text('Create'),
                selected: false,
                onPressed: () => context.pushNamed('meetups_create'),
              ),
            ),
            Expanded(
              child: _NavButton(
                icon: const Icon(
                  Icons.location_on_sharp,
                  size: 28,
                ),
                label: const Text('Events'),
                selected: index == 2,
                onPressed: () => onTabPressed(2),
              ),
            ),
            Expanded(
              child: _NavButton(
                icon: const ProfileButton(
                  width: 28,
                  height: 28,
                ),
                label: const Text('Profile'),
                selected: index == 3,
                enableFilterOnIcon: false,
                onPressed: () => onTabPressed(3),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final Widget icon;
  final Widget label;
  final bool selected;
  final bool enableFilterOnIcon;
  final VoidCallback onPressed;
  const _NavButton({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    this.enableFilterOnIcon = true,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Button(
      onPressed: onPressed,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 28,
            child: Center(
              child: enableFilterOnIcon
                  ? ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        selected
                            ? Colors.white
                            : const Color.fromRGBO(0x8F, 0x8C, 0x8C, 1.0),
                        BlendMode.srcIn,
                      ),
                      child: icon,
                    )
                  : icon,
            ),
          ),
          const SizedBox(height: 8),
          DefaultTextStyle.merge(
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: selected
                  ? Colors.white
                  : const Color.fromRGBO(0x8F, 0x8C, 0x8C, 1.0),
            ),
            child: label,
          ),
        ],
      ),
    );
  }
}

class _BranchIndex extends InheritedWidget {
  final int index;

  const _BranchIndex({
    super.key,
    required this.index,
    required super.child,
  });

  @override
  bool updateShouldNotify(covariant _BranchIndex oldWidget) =>
      index != oldWidget.index;

  static int? of(BuildContext context) {
    final widget = context.dependOnInheritedWidgetOfExactType<_BranchIndex>();
    return widget?.index;
  }
}

class ActivePage extends ConsumerStatefulWidget {
  final VoidCallback onActivate;
  final VoidCallback onDeactivate;
  final Widget child;
  const ActivePage({
    super.key,
    required this.onActivate,
    required this.onDeactivate,
    required this.child,
  });

  @override
  ConsumerState<ActivePage> createState() => _ActivePageState();
}

class _ActivePageState extends ConsumerState<ActivePage> {
  int? _myBranchIndex;
  int? _currentIndex;
  bool _active = false;
  bool _appResumed = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _myBranchIndex ??= _BranchIndex.of(context);
    final oldIndex = _currentIndex;
    try {
      _currentIndex = StatefulShellRouteState.of(context).currentIndex;
      if (oldIndex != _currentIndex) {
        _updateActivation();
      }
    } catch (e) {
      // Not a branch route
    }
  }

  void _updateActivation() {
    final isBranchRoute = _myBranchIndex != null;
    final onCurrentBranch = _currentIndex == _myBranchIndex;
    final routeCurrent = ModalRoute.of(context)?.isCurrent == true;
    final visible = isBranchRoute ? onCurrentBranch : routeCurrent;
    final shouldBeActive = visible && _appResumed;

    if (!_active && shouldBeActive) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onActivate();
          setState(() => _active = true);
        }
      });
    } else if (_active && !shouldBeActive) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onDeactivate();
          setState(() => _active = false);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppLifecycle(
      onResumed: () {
        setState(() => _appResumed = true);
        _updateActivation();
      },
      onPaused: () {
        setState(() => _appResumed = false);
        _updateActivation();
      },
      child: widget.child,
    );
  }
}
