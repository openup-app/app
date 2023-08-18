import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';

/// Executes the given callbacks when that application lifecycle event occurs.
class AppLifecycle extends StatefulWidget {
  final VoidCallback? onDetached;
  final VoidCallback? onInactive;
  final VoidCallback? onPaused;
  final VoidCallback? onResumed;
  final Widget child;

  const AppLifecycle({
    Key? key,
    this.onDetached,
    this.onInactive,
    this.onPaused,
    this.onResumed,
    required this.child,
  }) : super(key: key);

  @override
  State<AppLifecycle> createState() => _AppLifecycleState();
}

class _AppLifecycleState extends State<AppLifecycle>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.detached:
        widget.onDetached?.call();
        break;
      case AppLifecycleState.inactive:
        widget.onInactive?.call();
        break;
      case AppLifecycleState.paused:
        widget.onPaused?.call();
        break;
      case AppLifecycleState.resumed:
        widget.onResumed?.call();
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
