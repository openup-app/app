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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final panelTopMargin = MediaQuery.of(context).padding.top + 24.0;
          final maxContentHeight = constraints.maxHeight - panelTopMargin;
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
                          margin: EdgeInsets.only(top: panelTopMargin),
                          alignment: Alignment.topCenter,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(24),
                              topRight: Radius.circular(24),
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
                          child: SingleChildScrollView(
                            controller: controller,
                            physics: const ClampingScrollPhysics(),
                            child: Container(
                              height: 48,
                              margin: EdgeInsets.only(top: panelTopMargin - 28),
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
    );
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
        duration: const Duration(milliseconds: 200),
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
