import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openup/api/users/users_api.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/theming.dart';

class ProfileButton extends ConsumerWidget {
  final Color color;
  const ProfileButton({
    Key? key,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _ProfileButtonTheme(
      color: color,
      child: Hero(
        tag: 'profile_button',
        flightShuttleBuilder: (
          flightContext,
          animation,
          flightDirection,
          fromHeroContext,
          toHeroContext,
        ) {
          return AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              final push = flightDirection == HeroFlightDirection.push;
              final from = _ProfileButtonTheme.of(fromHeroContext)?.color;
              final to = _ProfileButtonTheme.of(toHeroContext)?.color;
              final tweenColor = ColorTween(
                begin: push ? from : to,
                end: push ? to : from,
              ).evaluate(animation);
              if (from == null || to == null || tweenColor == null) {
                return _ProfileButton(color: color);
              }
              return _ProfileButton(color: tweenColor);
            },
          );
        },
        child: _ProfileButton(color: color),
      ),
    );
  }
}

class _ProfileButtonTheme extends InheritedWidget {
  final Color color;

  const _ProfileButtonTheme({
    Key? key,
    required this.color,
    required Widget child,
  }) : super(key: key, child: child);

  @override
  bool updateShouldNotify(covariant _ProfileButtonTheme oldWidget) =>
      oldWidget.color != color;

  static _ProfileButtonTheme? of(BuildContext context) {
    return context.findAncestorWidgetOfExactType<_ProfileButtonTheme>();
  }
}

class _ProfileButton extends ConsumerWidget {
  final Color color;
  const _ProfileButton({
    Key? key,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Button(
      onPressed: () => Scaffold.of(context).openEndDrawer(),
      child: Stack(
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Theming.of(context).shadow,
                    offset: const Offset(0.0, 4.0),
                    blurRadius: 4.0,
                  ),
                ],
                color: color,
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                'assets/images/profile.png',
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: StreamBuilder<int>(
              stream: ref.read(usersApiProvider).unreadChatMessageSumStream,
              initialData: 0,
              builder: (context, snapshot) {
                final sum = snapshot.requireData;
                if (sum == 0) {
                  return const SizedBox.shrink();
                }
                return Container(
                  width: 16,
                  height: 16,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Theming.of(context).shadow,
                        offset: const Offset(0.0, 4.0),
                        blurRadius: 2.0,
                      ),
                    ],
                    shape: BoxShape.circle,
                    color: Theming.of(context).alertRed,
                  ),
                  child: Text(
                    sum.toString(),
                    textAlign: TextAlign.center,
                    style: Theming.of(context).text.caption,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
