import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import 'package:openup/widgets/app_lifecycle.dart';

final _sheetOpenNotifier = ValueNotifier<bool>(false);

class ShellPage extends StatefulWidget {
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
  State<ShellPage> createState() => ShellPageState();
}

class ShellPageState extends State<ShellPage> {
  final _keys = <GlobalKey>[];
  final _draggableScrollableController = DraggableScrollableController();

  @override
  void initState() {
    super.initState();
    _draggableScrollableController.addListener(() {
      final fullyOpen = _draggableScrollableController.size >= 1.0;
      _sheetOpenNotifier.value = fullyOpen;
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
    _sheetOpenNotifier.value = false;
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
      body: DecoratedBox(
        decoration: const BoxDecoration(
          color: Color.fromRGBO(0x44, 0x44, 0x44, 1.0),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxHeight = constraints.maxHeight;
            final maxContentHeight =
                constraints.maxHeight - MediaQuery.of(context).padding.top - 16;
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
                  child: widget.shellBuilder(context),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: DraggableScrollableSheet(
                    controller: _draggableScrollableController,
                    minChildSize: 0.0,
                    maxChildSize: maxContentRatio,
                    initialChildSize: 0,
                    snap: true,
                    builder: (context, controller) {
                      return ValueListenableBuilder<bool>(
                        valueListenable: _sheetOpenNotifier,
                        builder: (context, open, child) {
                          return AnimatedContainer(
                            curve: Curves.easeOut,
                            duration: const Duration(milliseconds: 200),
                            height: maxContentHeight,
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              color:
                                  const Color.fromRGBO(0x44, 0x44, 0x44, 1.0),
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
                                        child: _BranchIndex(
                                          index: i,
                                          child: widget.children[i],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.topCenter,
                              child: Stack(
                                children: [
                                  Positioned(
                                    left: 0,
                                    right: 0,
                                    top: 0,
                                    child: SingleChildScrollView(
                                      controller: controller,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      child: const SizedBox(
                                        height: 48,
                                        child: Align(
                                          alignment: Alignment.topCenter,
                                          child: Padding(
                                            padding: EdgeInsets.only(top: 9.0),
                                            child: _DragHandle(),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
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

  void showSheet() {
    if (_draggableScrollableController.isAttached) {
      _draggableScrollableController.animateTo(
        1.0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } else {
      print('DraggableScrollableSheetController is not attached');
    }
  }

  void hideSheet() {
    if (_draggableScrollableController.isAttached) {
      _draggableScrollableController.animateTo(
        0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    } else {
      print('DraggableScrollableSheetController is not attached');
    }
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
  late bool _pageOpen;
  bool _active = false;
  bool _appResumed = true;

  @override
  void initState() {
    super.initState();
    _sheetOpenNotifier.addListener(_onPageOpen);
    _pageOpen = _sheetOpenNotifier.value;
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

  @override
  void dispose() {
    _sheetOpenNotifier.removeListener(_onPageOpen);
    super.dispose();
  }

  void _onPageOpen() {
    _pageOpen = _sheetOpenNotifier.value;
    _updateActivation();
  }

  void _updateActivation() {
    final isBranchRoute = _myBranchIndex != null;
    final onCurrentBranch = _currentIndex == _myBranchIndex;
    final routeActive = ModalRoute.of(context)?.isActive == true;
    final visible = isBranchRoute ? onCurrentBranch : routeActive;
    final shouldBeActive = visible && _pageOpen && _appResumed;
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
