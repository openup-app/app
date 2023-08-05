import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openup/widgets/app_lifecycle.dart';
import 'package:openup/widgets/drag_handle.dart';

final _sheetSize = StateProvider<double>((ref) => 0.0);
final _sheetOpenProvider = StateProvider<bool>((ref) => false);

class ShellPage extends ConsumerStatefulWidget {
  final int? currentIndex;
  final WidgetBuilder shellBuilder;
  final VoidCallback onClosePage;
  final List<Widget> children;

  const ShellPage({
    super.key,
    required this.currentIndex,
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
    _draggableScrollableController.addListener(() {
      ref.read(_sheetSize.notifier).state = _draggableScrollableController.size;
      final fullyOpen = _draggableScrollableController.size >= 1.0;
      ref.read(_sheetOpenProvider.notifier).state = fullyOpen;
      if (fullyOpen) {
        FocusScope.of(context).unfocus();
      }

      const epsilon = 0.0001;
      if (_draggableScrollableController.size <= epsilon) {
        if (widget.currentIndex != null) {
          widget.onClosePage();
        }
      }
    });

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
                                        index: i + 1,
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
                                child: const Align(
                                  alignment: Alignment.topCenter,
                                  child: Padding(
                                    padding: EdgeInsets.only(top: 35),
                                    child: DragHandle(),
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
      print('DraggableScrollableSheetController is not attached');
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
      print('DraggableScrollableSheetController is not attached');
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
