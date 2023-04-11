import 'dart:ui';

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
  final Widget child;

  const MenuPage({
    super.key,
    required this.currentIndex,
    required this.menuBuilder,
    this.pageTitleBuilder,
    required this.child,
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
      // Never reports a size beyond 0.9625 for some reason, treat this as open
      final fullyOpen = _draggableScrollableController.size >= 0.95;
      if (fullyOpen) {
        _menuOpenNotifier.value = true;
      } else {
        _menuOpenNotifier.value = false;
      }
    });

    _keys.addAll(List.generate(1, (_) => GlobalKey()));
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
          image: DecorationImage(
            image: AssetImage('assets/images/menu_background.png'),
            fit: BoxFit.fill,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxHeight = constraints.maxHeight;
            final maxContentHeight =
                constraints.maxHeight - MediaQuery.of(context).padding.top;
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
                      return PrimaryScrollControllerTemp(
                        controller: controller,
                        child: Container(
                          height: maxContentHeight,
                          clipBehavior: Clip.antiAlias,
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(32),
                              topRight: Radius.circular(32),
                            ),
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            alignment: Alignment.topCenter,
                            children: [
                              Container(
                                color: Colors.white,
                                alignment: Alignment.topCenter,
                                child: OverflowBox(
                                  minHeight: maxContentHeight,
                                  maxHeight: maxContentHeight,
                                  alignment: Alignment.topCenter,
                                  child: widget.child,
                                ),
                              ),
                              const Align(
                                alignment: Alignment.topCenter,
                                child: Padding(
                                  padding: EdgeInsets.only(top: 23.0),
                                  child: SizedBox(
                                    width: 37,
                                    height: 6,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(2.5)),
                                        color: Colors.white,
                                        boxShadow: [
                                          BoxShadow(
                                            offset: Offset(0, 1),
                                            blurRadius: 4,
                                            color: Color.fromRGBO(
                                                0x00, 0x00, 0x00, 0.25),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              if (widget.pageTitleBuilder != null)
                                Positioned(
                                  left: 32,
                                  top: 18,
                                  child: widget.pageTitleBuilder!(context),
                                ),
                            ],
                          ),
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

class MenuButton extends StatefulWidget {
  final Color color;
  final VoidCallback? onShowMenu;
  const MenuButton({
    super.key,
    this.color = const Color.fromRGBO(0x5A, 0x5A, 0x5A, 0.5),
    this.onShowMenu,
  });

  @override
  State<MenuButton> createState() => _MenuButtonState();
}

class _MenuButtonState extends State<MenuButton> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58,
      height: 56,
      child: ActivePage(
        onActivate: () => setState(() => _visible = true),
        onDeactivate: () => setState(() => _visible = false),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInExpo,
          opacity: _visible ? 1.0 : 0.0,
          child: Stack(
            alignment: Alignment.center,
            children: [
              ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: widget.color,
                        shape: BoxShape.circle,
                      ),
                      child: Button(
                        onPressed: () {
                          widget.onShowMenu?.call();
                        },
                        child: Image.asset(
                          'assets/images/menu_button.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 2,
                right: 6,
                child: Button(
                  onPressed: () {},
                  child: Container(
                    width: 18,
                    height: 18,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Color.fromRGBO(0xC6, 0x0A, 0x0A, 1.0),
                          Color.fromRGBO(0xFA, 0x4F, 0x4F, 1.0),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '2',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium!
                          .copyWith(fontSize: 14),
                    ),
                  ),
                ),
              ),
            ],
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

class PrimaryScrollControllerTemp extends InheritedWidget {
  final ScrollController controller;

  const PrimaryScrollControllerTemp({
    super.key,
    required this.controller,
    required super.child,
  });

  @override
  bool updateShouldNotify(covariant PrimaryScrollControllerTemp oldWidget) {
    return oldWidget.controller != controller;
  }

  static ScrollController? of(BuildContext context) {
    final primaryScrollControllerTemp = context
        .dependOnInheritedWidgetOfExactType<PrimaryScrollControllerTemp>();
    return primaryScrollControllerTemp?.controller;
  }
}
