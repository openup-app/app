import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import 'package:openup/widgets/app_lifecycle.dart';
import 'package:openup/widgets/button.dart';

final _menuOpenNotifier = ValueNotifier<bool>(false);

class MenuPage extends StatefulWidget {
  final int currentIndex;
  final WidgetBuilder menuBuilder;
  final WidgetBuilder? pageTitleBuilder;
  final List<Widget> children;

  const MenuPage({
    super.key,
    required this.currentIndex,
    required this.menuBuilder,
    this.pageTitleBuilder,
    required this.children,
  });

  @override
  State<MenuPage> createState() => MenuPageState();
}

class MenuPageState extends State<MenuPage> {
  final _keys = <GlobalKey>[];
  final _draggableScrollableController = DraggableScrollableController();

  @override
  void initState() {
    super.initState();
    _draggableScrollableController.addListener(() {
      final fullyOpen = _draggableScrollableController.size >= 1.0;
      if (fullyOpen) {
        _menuOpenNotifier.value = true;
      } else {
        _menuOpenNotifier.value = false;
        FocusScope.of(context).unfocus();
      }
    });

    _keys.addAll(List.generate(widget.children.length, (_) => GlobalKey()));
  }

  @override
  void didUpdateWidget(covariant MenuPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      open();
    }
  }

  void open() {
    if (_draggableScrollableController.isAttached) {
      _draggableScrollableController.jumpTo(1.0);
    } else {
      print('DraggableScrollableSheetController is not attached');
    }
  }

  @override
  void dispose() {
    _draggableScrollableController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          color: Color.fromRGBO(0xF2, 0xF2, 0xF6, 1.0),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxHeight = constraints.maxHeight;
            final maxContentHeight = constraints.maxHeight;
            final maxContentRatio = maxContentHeight / maxHeight;
            return Stack(
              children: [
                WillPopScope(
                  onWillPop: () {
                    if (_draggableScrollableController.size == 0) {
                      return Future.value(true);
                    }
                    _draggableScrollableController.animateTo(
                      0,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                    );
                    return Future.value(false);
                  },
                  child: widget.menuBuilder(context),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: DraggableScrollableSheet(
                    controller: _draggableScrollableController,
                    minChildSize: 0.0,
                    maxChildSize: maxContentRatio,
                    initialChildSize: maxContentRatio,
                    snap: true,
                    builder: (context, controller) {
                      return ValueListenableBuilder<bool>(
                        valueListenable: _menuOpenNotifier,
                        builder: (context, open, child) {
                          return AnimatedContainer(
                            curve: Curves.easeOut,
                            duration: const Duration(milliseconds: 200),
                            height: maxContentHeight,
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              color:
                                  const Color.fromRGBO(0xF2, 0xF2, 0xF6, 1.0),
                              borderRadius: open
                                  ? BorderRadius.zero
                                  : const BorderRadius.only(
                                      topLeft: Radius.circular(48),
                                      topRight: Radius.circular(48),
                                    ),
                            ),
                            child: child,
                          );
                        },
                        child: Stack(
                          fit: StackFit.expand,
                          alignment: Alignment.topCenter,
                          children: [
                            Align(
                              alignment: Alignment.topCenter,
                              child: OverflowBox(
                                minHeight: maxContentHeight,
                                maxHeight: maxContentHeight,
                                alignment: Alignment.topCenter,
                                child: IndexedStack(
                                  index: widget.currentIndex,
                                  children: [
                                    for (var i = 0; i < _keys.length; i++)
                                      KeyedSubtree(
                                        key: _keys[i],
                                        child: widget.children[i],
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.topCenter,
                              child: Padding(
                                padding: EdgeInsets.only(
                                    top: MediaQuery.of(context).padding.top),
                                child: SingleChildScrollView(
                                  controller: controller,
                                  physics: const NeverScrollableScrollPhysics(),
                                  child: SizedBox(
                                    height: 48,
                                    child: Stack(
                                      children: [
                                        const Align(
                                          alignment: Alignment.topCenter,
                                          child: Padding(
                                            padding: EdgeInsets.only(top: 9.0),
                                            child: _DragHandle(),
                                          ),
                                        ),
                                        if (widget.pageTitleBuilder != null)
                                          Align(
                                            alignment: Alignment.topLeft,
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                left: 32,
                                                top: 7,
                                              ),
                                              child: widget
                                                  .pageTitleBuilder!(context),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void showMenu() {
    _draggableScrollableController.animateTo(
      0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 37,
      height: 6,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(2.5)),
          color: Color.fromRGBO(0x71, 0x71, 0x71, 1.0),
          boxShadow: [
            BoxShadow(
              offset: Offset(0, 1),
              blurRadius: 4,
              color: Color.fromRGBO(0x00, 0x00, 0x00, 0.25),
            ),
          ],
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
    final shouldBeActive = visible && _menuOpen && _appResumed;
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
