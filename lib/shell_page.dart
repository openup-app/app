import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:openup/widgets/profile_button.dart';
import 'package:openup/widgets/scaffold.dart';
import 'package:openup/widgets/app_lifecycle.dart';
import 'package:openup/widgets/button.dart';

class TabShell extends StatelessWidget {
  final int index;
  final Widget child;

  const TabShell({
    super.key,
    required this.index,
    required this.child,
  });

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
          child: child,
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: OpenupBottomBar(
            child: _Tabs(
              index: index,
              onTabPressed: (index) {
                if (index == 0) {
                  context.goNamed('discover');
                } else if (index == 1) {
                  context.goNamed('events');
                } else if (index == 2) {
                  context.goNamed('chats');
                } else if (index == 3) {
                  context.goNamed('account');
                }
              },
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
                icon: Lottie.asset('assets/images/discover.json'),
                label: const Text('Discover'),
                selected: index == 0,
                onPressed: () => onTabPressed(0),
              ),
            ),
            Expanded(
              child: _NavButton(
                icon: Transform.scale(
                  scale: 1.1,
                  child: Lottie.asset('assets/images/hangout.json'),
                ),
                label: const Text('Hangout'),
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
                onPressed: () => context.pushNamed('event_create'),
              ),
            ),
            Expanded(
              child: _NavButton(
                icon: Transform.scale(
                  scale: 1.7,
                  child: Lottie.asset('assets/images/messages.json'),
                ),
                label: const Text('Messages'),
                selected: index == 2,
                onPressed: () => onTabPressed(2),
              ),
            ),
            Expanded(
              child: _NavButton(
                icon: const ProfileButton(
                  width: 32,
                  height: 32,
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
            height: 32,
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
  bool _active = false;
  bool _appResumed = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    try {
      _updateActivation();
    } catch (e) {
      // Not a branch route
    }
  }

  void _updateActivation() {
    final shouldBeActive = _appResumed;

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
