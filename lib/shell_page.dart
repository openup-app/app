import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:openup/discover_page.dart';
import 'package:openup/widgets/app_lifecycle.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/drag_handle.dart';

final _sheetSize = StateProvider<double>((ref) => 0.0);
final _sheetOpenProvider = StateProvider<bool>((ref) => false);

final _pageNotifierProvider =
    StateNotifierProvider<_PageNotifier, int>((ref) => _PageNotifier());

class _PageNotifier extends StateNotifier<int> {
  _PageNotifier() : super(0);

  void changePage(int index) => state = index;
}

class TabShell extends ConsumerStatefulWidget {
  final List<Widget> children;

  const TabShell({
    super.key,
    required this.children,
  });

  @override
  ConsumerState<TabShell> createState() => _TabShellState();
}

class _TabShellState extends ConsumerState<TabShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    ref.listenManual<int>(
      _pageNotifierProvider,
      (previous, next) {
        if (next != _index) {
          setState(() => _index = next);
          StatefulShellRouteState.of(context).goBranch(index: _index);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _index,
              children: [
                for (var i = 0; i < widget.children.length; i++)
                  ColoredBox(
                    color: Colors.white,
                    child: _BranchIndex(
                      index: i,
                      child: widget.children[i],
                    ),
                  ),
              ],
            ),
          ),
          DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.fromRGBO(0xD9, 0xD9, 0xD9, 0.05),
                  Color.fromRGBO(0x3D, 0x3D, 0x3D, 0.05),
                ],
              ),
            ),
            child: SizedBox(
              height: 86 + MediaQuery.of(context).padding.bottom,
              child: Column(
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _NavButton(
                            icon: SvgPicture.asset(
                                'assets/images/nav_icon_people.svg'),
                            label: const Text('People'),
                            selected: _index == 0,
                            onPressed: () => ref
                                .read(_pageNotifierProvider.notifier)
                                .changePage(0),
                          ),
                        ),
                        Expanded(
                          child: _NavButton(
                            icon: SvgPicture.asset(
                                'assets/images/nav_icon_messages.svg'),
                            label: const Text('Messages'),
                            selected: _index == 1,
                            onPressed: () => ref
                                .read(_pageNotifierProvider.notifier)
                                .changePage(1),
                          ),
                        ),
                        Expanded(
                          child: _NavButton(
                            icon: const Icon(
                              Icons.location_on_sharp,
                              size: 28,
                            ),
                            label: const Text('Events'),
                            selected: _index == 2,
                            onPressed: () => ref
                                .read(_pageNotifierProvider.notifier)
                                .changePage(2),
                          ),
                        ),
                        Expanded(
                          child: _NavButton(
                            icon: const ProfileButton(
                              width: 28,
                              height: 28,
                            ),
                            label: const Text('Profile'),
                            selected: _index == 3,
                            enableFilterOnIcon: false,
                            onPressed: () => ref
                                .read(_pageNotifierProvider.notifier)
                                .changePage(3),
                          ),
                        )
                      ],
                    ),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).padding.bottom,
                  ),
                ],
              ),
            ),
          ),
        ],
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
          DefaultTextStyle(
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

class ShellPage extends ConsumerStatefulWidget {
  final int? currentIndex;
  final int indexOffset;
  final WidgetBuilder shellBuilder;
  final VoidCallback onClosePage;
  final List<Widget> children;

  const ShellPage({
    super.key,
    required this.currentIndex,
    this.indexOffset = 0,
    required this.shellBuilder,
    required this.onClosePage,
    required this.children,
  });

  @override
  ConsumerState<ShellPage> createState() => ShellPageState();
}

class ShellPageState extends ConsumerState<ShellPage> {
  final _shellBuilderKey = GlobalKey();
  final _keys = <GlobalKey>[];
  final _draggableScrollableController = DraggableScrollableController();

  @override
  void initState() {
    super.initState();
    _draggableScrollableController.addListener(_onSheetUpdate);
    _keys.addAll(List.generate(widget.children.length, (_) => GlobalKey()));
    ref.read(_sheetOpenProvider.notifier).state = false;
  }

  @override
  void didUpdateWidget(covariant ShellPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex &&
        widget.currentIndex != null) {
      showSheet();
    }
  }

  void _onSheetUpdate() {
    const epsilon = 0.0001;

    ref.read(_sheetSize.notifier).state = _draggableScrollableController.size;
    final fullyOpen = _draggableScrollableController.size >= 1.0;
    ref.read(_sheetOpenProvider.notifier).state = fullyOpen;

    final fullyClosed = _draggableScrollableController.size <= epsilon;
    if (fullyClosed) {
      FocusScope.of(context).unfocus();
      final currentIndex = widget.currentIndex;
      if (currentIndex != null) {
        StatefulShellRouteState.of(context)
            .resetBranch(index: currentIndex + widget.indexOffset);
        widget.onClosePage();
      }
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
      body: SheetControl(
        onAction: _onSheetAction,
        child: LayoutBuilder(
          builder: (context, constraints) {
            const panelTopMargin = 0.0;
            final maxContentHeight = constraints.maxHeight - panelTopMargin;
            return Stack(
              children: [
                WillPopScope(
                  onWillPop: () {
                    if (_draggableScrollableController.size == 0) {
                      return Future.value(true);
                    }
                    hideSheet();
                    return Future.value(false);
                  },
                  child: KeyedSubtree(
                    key: _shellBuilderKey,
                    child: _BranchIndex(
                      index: 0,
                      child: widget.shellBuilder(context),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: Builder(
                      builder: (context) {
                        final opacity = ref.watch(_sheetSize) * 0.35;
                        return ColoredBox(
                          color: Color.fromRGBO(0x00, 0x00, 0x00, opacity),
                        );
                      },
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: DraggableScrollableSheet(
                    controller: _draggableScrollableController,
                    minChildSize: 0.0,
                    maxChildSize: 1.0,
                    initialChildSize: 0,
                    snap: true,
                    builder: (context, controller) {
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          AnimatedContainer(
                            curve: Curves.easeOut,
                            duration: const Duration(milliseconds: 200),
                            height: constraints.maxHeight,
                            clipBehavior: Clip.antiAlias,
                            margin: const EdgeInsets.only(top: panelTopMargin),
                            alignment: Alignment.topCenter,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: ref.watch(_sheetOpenProvider)
                                  ? BorderRadius.zero
                                  : const BorderRadius.only(
                                      topLeft: Radius.circular(20),
                                      topRight: Radius.circular(20),
                                    ),
                            ),
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
                                      child: _BranchIndex(
                                        index: i + widget.indexOffset,
                                        child: widget.children[i],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topCenter,
                            child: SingleChildScrollView(
                              controller: controller,
                              physics: const ClampingScrollPhysics(),
                              child: SizedBox(
                                height: 44 + MediaQuery.of(context).padding.top,
                                child: Padding(
                                  padding: EdgeInsets.only(
                                      top: MediaQuery.of(context).padding.top),
                                  child: const Align(
                                    alignment: Alignment.topCenter,
                                    child: Padding(
                                      padding: EdgeInsets.only(top: 8),
                                      child: DragHandle(),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
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

  void _onSheetAction(_SheetAction action) {
    switch (action) {
      case _SheetAction.close:
        hideSheet();
        break;
    }
  }

  void showSheet() {
    if (_draggableScrollableController.isAttached) {
      _draggableScrollableController.animateTo(
        1.0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutQuart,
      );
    } else {
      debugPrint('DraggableScrollableSheetController is not attached');
    }
  }

  void hideSheet() {
    if (_draggableScrollableController.isAttached) {
      _draggableScrollableController.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } else {
      debugPrint('DraggableScrollableSheetController is not attached');
    }
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
  final bool activeOnSheetOpen;
  final VoidCallback onActivate;
  final VoidCallback onDeactivate;
  final Widget child;
  const ActivePage({
    super.key,
    this.activeOnSheetOpen = true,
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
  bool _pageOpen = false;
  bool _active = false;
  bool _appResumed = true;

  @override
  void initState() {
    super.initState();
    ref.listenManual<bool>(
      _sheetOpenProvider,
      (previous, next) => _onPageOpenChanged(next),
    );
  }

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

  void _onPageOpenChanged(bool open) {
    _pageOpen = open;
    _updateActivation();
  }

  void _updateActivation() {
    final isBranchRoute = _myBranchIndex != null;
    final onCurrentBranch = _currentIndex == _myBranchIndex;
    final routeCurrent = ModalRoute.of(context)?.isCurrent == true;
    final visible = isBranchRoute ? onCurrentBranch : routeCurrent;
    final shouldBeActive = visible &&
        (widget.activeOnSheetOpen && _pageOpen ||
            !widget.activeOnSheetOpen && !_pageOpen) &&
        _appResumed;

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

class SheetControl extends InheritedWidget {
  final void Function(_SheetAction action) _onAction;

  const SheetControl({
    required super.child,
    required void Function(_SheetAction action) onAction,
  }) : _onAction = onAction;

  @override
  bool updateShouldNotify(covariant SheetControl oldWidget) {
    return oldWidget._onAction != _onAction;
  }

  static SheetControl of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SheetControl>()!;

  void close() => _onAction(_SheetAction.close);
}

enum _SheetAction {
  close;
}
