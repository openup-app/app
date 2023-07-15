import 'package:flutter/widgets.dart';

/// Enables the app below this widget to be restarted by calling
/// [RestartApp.restartApp].
class RestartApp extends StatefulWidget {
  final Widget child;

  const RestartApp({Key? key, required this.child}) : super(key: key);

  /// Restarts the app below the nearest [RestartApp].
  static void restartApp(BuildContext context) {
    context.findAncestorStateOfType<RestartAppState>()!.restartApp();
  }

  @override
  RestartAppState createState() => RestartAppState();
}

class RestartAppState extends State<RestartApp> {
  Key _resetKey = UniqueKey();

  void restartApp() {
    setState(() => _resetKey = UniqueKey());
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: _resetKey,
      child: widget.child,
    );
  }
}
