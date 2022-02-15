import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Sets the styling of system UI whenever the route is current.
class CurrentRouteSystemUiStyling extends StatefulWidget {
  final SystemUiOverlayStyle style;
  final Widget child;

  const CurrentRouteSystemUiStyling({
    Key? key,
    required this.style,
    required this.child,
  }) : super(key: key);

  const CurrentRouteSystemUiStyling.dark({
    Key? key,
    required this.child,
  })  : style = const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarBrightness: Brightness.light,
          statusBarIconBrightness: Brightness.dark,
        ),
        super(key: key);

  const CurrentRouteSystemUiStyling.light({
    Key? key,
    required this.child,
  })  : style = const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarBrightness: Brightness.dark,
          statusBarIconBrightness: Brightness.light,
        ),
        super(key: key);

  @override
  State<CurrentRouteSystemUiStyling> createState() =>
      _CurrentRouteSystemUiStylingState();
}

class _CurrentRouteSystemUiStylingState
    extends State<CurrentRouteSystemUiStyling> with RouteAware {
  RouteObserver? _routeObserver;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);

    _routeObserver?.unsubscribe(this);
    final routeObserver = InheritedRouteObserver.of(context)?.routeObserver;
    if (route != null && routeObserver != null) {
      InheritedRouteObserver.of(context)?.routeObserver.subscribe(this, route);
    }
    _routeObserver = routeObserver;
  }

  @override
  void dispose() {
    _routeObserver?.unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;

  @override
  void didPush() {
    SystemChrome.setSystemUIOverlayStyle(widget.style);
    super.didPush();
  }

  @override
  void didPopNext() {
    SystemChrome.setSystemUIOverlayStyle(widget.style);
    super.didPopNext();
  }
}

class InheritedRouteObserver extends InheritedWidget {
  final RouteObserver routeObserver;

  const InheritedRouteObserver({
    Key? key,
    required this.routeObserver,
    required Widget child,
  }) : super(key: key, child: child);

  static InheritedRouteObserver? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<InheritedRouteObserver>();
  }

  @override
  bool updateShouldNotify(InheritedRouteObserver oldWidget) {
    return oldWidget.routeObserver != routeObserver;
  }
}
