import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import 'package:openup/widgets/app_lifecycle.dart';
import 'package:openup/widgets/button.dart';

final _menuKey = GlobalKey<_KeyedMenuPageState>();

final _menuOpenNotifier = ValueNotifier<bool>(false);

class MenuPage extends StatefulWidget {
  final int currentIndex;
  final void Function(int index) onItemPressed;
  final List<Widget> children;

  const MenuPage({
    super.key,
    required this.currentIndex,
    required this.onItemPressed,
    required this.children,
  });

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  @override
  Widget build(BuildContext context) {
    return _KeyedMenuPage(
      key: _menuKey,
      currentIndex: widget.currentIndex,
      onItemPressed: widget.onItemPressed,
      children: [
        for (var i = 0; i < widget.children.length; i++)
          _BranchIndex(
            index: i,
            child: widget.children[i],
          ),
      ],
    );
  }
}

class _KeyedMenuPage extends StatefulWidget {
  final int currentIndex;
  final void Function(int index) onItemPressed;
  final List<Widget> children;

  const _KeyedMenuPage({
    super.key,
    required this.currentIndex,
    required this.onItemPressed,
    required this.children,
  }) : assert(children.length == 4, 'Must have four menu pages');

  @override
  State<_KeyedMenuPage> createState() => _KeyedMenuPageState();
}

class _KeyedMenuPageState extends State<_KeyedMenuPage>
    with SingleTickerProviderStateMixin {
  late final _animationController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
  );

  @override
  void initState() {
    super.initState();
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _menuOpenNotifier.value = true;
      } else if (status == AnimationStatus.dismissed) {
        _menuOpenNotifier.value = false;
      }
    });
  }

  @override
  void didUpdateWidget(covariant _KeyedMenuPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != oldWidget.currentIndex) {
      _animationController.reverse();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final previews = [
      _PageDisplay(
        key: const ValueKey('0'),
        alignment: Alignment.topLeft,
        animation: _animationController,
        selected: widget.currentIndex == 0,
        onPressed: () => widget.onItemPressed(0),
        child: widget.children[0],
      ),
      _PageDisplay(
        key: const ValueKey('1'),
        alignment: Alignment.topRight,
        animation: _animationController,
        selected: widget.currentIndex == 1,
        onPressed: () => widget.onItemPressed(1),
        child: widget.children[1],
      ),
      _PageDisplay(
        key: const ValueKey('2'),
        alignment: Alignment.bottomLeft,
        animation: _animationController,
        selected: widget.currentIndex == 2,
        onPressed: () => widget.onItemPressed(2),
        child: widget.children[2],
      ),
      _PageDisplay(
        key: const ValueKey('3'),
        alignment: Alignment.bottomRight,
        animation: _animationController,
        selected: widget.currentIndex == 3,
        onPressed: () => widget.onItemPressed(3),
        child: widget.children[3],
      ),
    ];

    // Display on top of other pages in case its full screen
    final selectedPage = previews.removeAt(widget.currentIndex);
    previews.add(selectedPage);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/menu_background.png'),
            fit: BoxFit.fill,
          ),
        ),
        child: Stack(
          children: [
            ...previews,
          ],
        ),
      ),
    );
  }

  void showMenu() => _animationController.forward();
}

class MenuButton extends StatelessWidget {
  final Color color;
  final VoidCallback? onShowMenu;
  const MenuButton({
    super.key,
    this.color = const Color.fromRGBO(0x5A, 0x5A, 0x5A, 0.5),
    this.onShowMenu,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Button(
          onPressed: () {
            _menuKey.currentState?.showMenu();
            onShowMenu?.call();
          },
          child: Image.asset(
            'assets/images/menu_button.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

class _PageDisplay extends StatefulWidget {
  final Alignment alignment;
  final AnimationController animation;
  final bool selected;
  final VoidCallback? onPressed;
  final Widget child;

  const _PageDisplay({
    super.key,
    required this.alignment,
    required this.animation,
    required this.selected,
    required this.onPressed,
    required this.child,
  });

  @override
  State<_PageDisplay> createState() => _PageDisplayState();
}

class _PageDisplayState extends State<_PageDisplay> {
  @override
  Widget build(BuildContext context) {
    final curvedAnimation = CurvedAnimation(
      parent: widget.animation,
      curve: widget.animation.status == AnimationStatus.forward
          ? Curves.easeOut
          : Curves.easeIn,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final alignment = widget.alignment - widget.alignment * 0.25;
        return AnimatedBuilder(
          animation: curvedAnimation,
          builder: (context, child) {
            final scale = widget.selected
                ? Tween(begin: 1.0, end: 0.4).evaluate(curvedAnimation)
                : 0.4;
            final offset = constraints.biggest.center(Offset.zero) +
                Offset(
                  constraints.biggest.width / 2 * alignment.x,
                  constraints.biggest.height / 2 * alignment.y,
                );
            return Transform(
              transform: Matrix4.identity()
                ..translate(offset.dx, offset.dy)
                ..scale(scale)
                ..translate(-offset.dx, -offset.dy),
              child: ClipRRect(
                borderRadius: widget.selected
                    ? Tween<BorderRadius>(
                        begin: BorderRadius.zero,
                        end: const BorderRadius.all(Radius.circular(64)),
                      ).evaluate(curvedAnimation)
                    : const BorderRadius.all(Radius.circular(64)),
                child: ColoredBox(
                  color: Colors.black,
                  child: Builder(
                    builder: (context) {
                      if (widget.selected && widget.animation.value == 0.0) {
                        return _buildChild(context);
                      }
                      return Button(
                        onPressed: () {
                          if (widget.animation.value == 0.0 ||
                              widget.animation.value == 1.0) {
                            if (widget.selected) {
                              widget.animation.reverse();
                            } else {
                              widget.onPressed?.call();
                            }
                          }
                        },
                        child: _buildChild(context),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildChild(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.animation,
      builder: (context, child) {
        return IgnorePointer(
          ignoring: widget.animation.value != 0.0,
          child: widget.child,
        );
      },
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
    with AutomaticKeepAliveClientMixin<_KeepAlive> {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
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

class ActivePage extends StatefulWidget {
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
  State<ActivePage> createState() => _ActivePageState();
}

class _ActivePageState extends State<ActivePage> {
  int? _myBranchIndex;
  int? _currentIndex;
  bool _menuOpen = false;
  bool _active = false;
  bool _appResumed = true;

  @override
  void initState() {
    super.initState();
    _menuOpenNotifier.addListener(_onMenuOpen);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _myBranchIndex = _BranchIndex.of(context) ?? _myBranchIndex;
    final oldCurrentIndex = _currentIndex;
    try {
      _currentIndex = StatefulShellRouteState.of(context).currentIndex;
      if (oldCurrentIndex != _currentIndex) {
        _updateActivation();
      }
    } catch (e) {
      // Not a branch route
    }
  }

  @override
  void dispose() {
    _menuOpenNotifier.removeListener(_onMenuOpen);
    super.dispose();
  }

  void _onMenuOpen() {
    _menuOpen = _menuOpenNotifier.value;
    _updateActivation();
  }

  void _updateActivation() {
    final isBranchRoute = _myBranchIndex != null;
    final onCurrentBranch = _currentIndex == _myBranchIndex;
    final routeActive = ModalRoute.of(context)?.isActive == true;
    final visible = isBranchRoute ? onCurrentBranch : routeActive;
    final shouldBeActive = visible && !_menuOpen && _appResumed;
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
