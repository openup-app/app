import 'package:flutter/widgets.dart';

typedef PageTransitionBuilder = Widget Function(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
);

Widget slideRightToLeftPageTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  final tween = Tween(
    begin: const Offset(1.0, 0.0),
    end: Offset.zero,
  ).chain(
    CurveTween(curve: Curves.easeInOutBack),
  );
  return SlideTransition(
    position: animation.drive(tween),
    child: child,
  );
}

Widget fadePageTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  const begin = 0.0;
  const end = 1.0;
  final tween = Tween(
    begin: begin,
    end: end,
  ).chain(CurveTween(curve: Curves.easeOut));
  return FadeTransition(
    opacity: animation.drive(tween),
    child: child,
  );
}

class SlideUpTransition extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const SlideUpTransition({
    super.key,
    required this.animation,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final pushingNext = animation.status == AnimationStatus.forward;
    return SlideTransition(
      position: Tween(
        begin: const Offset(0.0, 1.0),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          curve: pushingNext ? Curves.easeOutQuart : Curves.easeInQuart,
          parent: animation,
        ),
      ),
      child: child,
    );
  }
}
