import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:openup/widgets/button.dart';

class MenuPage extends StatefulWidget {
  final int currentIndex;
  final Widget child;

  const MenuPage({
    super.key,
    required this.currentIndex,
    required this.child,
  });

  @override
  State<MenuPage> createState() => MenuPageState();
}

class MenuPageState extends State<MenuPage>
    with SingleTickerProviderStateMixin {
  late final _animationController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );

  final _screenshots = <ui.Image?>[null, null, null, null];

  @override
  void didUpdateWidget(covariant MenuPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != oldWidget.currentIndex) {
      _animationController.reverse();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final previews = [
      _PageDisplay(
        key: const ValueKey('0'),
        alignment: Alignment.topLeft,
        animation: _animationController,
        selected: widget.currentIndex == 0,
        onPressed: () => context.goNamed('discover'),
        screenshot: _screenshots[0],
        child: widget.currentIndex == 0 ? widget.child : const Placeholder(),
      ),
      _PageDisplay(
        key: const ValueKey('1'),
        alignment: Alignment.topRight,
        animation: _animationController,
        selected: widget.currentIndex == 1,
        onPressed: () => context.goNamed('relationships'),
        screenshot: _screenshots[1],
        child: widget.currentIndex == 1 ? widget.child : const Placeholder(),
      ),
      _PageDisplay(
        key: const ValueKey('2'),
        alignment: Alignment.bottomLeft,
        animation: _animationController,
        selected: widget.currentIndex == 2,
        onPressed: () => context.goNamed('profile'),
        screenshot: _screenshots[2],
        child: widget.currentIndex == 2 ? widget.child : const Placeholder(),
      ),
      _PageDisplay(
        key: const ValueKey('3'),
        alignment: Alignment.bottomRight,
        animation: _animationController,
        selected: widget.currentIndex == 3,
        onPressed: () => context.goNamed('people'),
        screenshot: _screenshots[3],
        child: widget.currentIndex == 3 ? widget.child : const Placeholder(),
      ),
    ];

    // Display on top of other pages in case its full screen
    final selectedPage = previews.removeAt(widget.currentIndex);
    previews.add(selectedPage);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/menu_background.png',
            fit: BoxFit.fill,
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 65,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 21,
                  height: 21,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Color.fromRGBO(0xBE, 0x00, 0x00, 1.0),
                        Color.fromRGBO(0xFD, 0x53, 0x53, 1.0),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '1',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium!
                          .copyWith(fontWeight: FontWeight.w500, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  'New chat request',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium!
                      .copyWith(fontWeight: FontWeight.w500, fontSize: 16),
                ),
              ],
            ),
          ),
          Stack(
            children: [
              ...previews,
            ],
          ),
        ],
      ),
    );
  }

  void showMenu(ui.Image screenshot) {
    setState(() => _screenshots[widget.currentIndex] = screenshot);
    _animationController.forward();
  }
}

class MenuButton extends StatelessWidget {
  final Color color;
  final VoidCallback onPressed;
  const MenuButton({
    super.key,
    this.color = const Color.fromRGBO(0x5A, 0x5A, 0x5A, 0.5),
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Button(
          onPressed: onPressed,
          child: Image.asset(
            'assets/images/app_icon_new.png',
            fit: BoxFit.contain,
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
  final ui.Image? screenshot;
  final Widget child;

  const _PageDisplay({
    super.key,
    required this.alignment,
    required this.animation,
    required this.selected,
    required this.onPressed,
    required this.screenshot,
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
        final childVisible = widget.selected && widget.animation.value == 0.0;
        return IgnorePointer(
          ignoring: widget.animation.value != 0.0,
          child: Stack(
            children: [
              Visibility(
                visible: !childVisible,
                child: CustomPaint(
                  painter: ScreenshotPainter(
                    screenshot: widget.screenshot,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
              Visibility(
                visible: childVisible,
                maintainState: true,
                maintainAnimation: true,
                maintainSize: true,
                child: widget.child,
              ),
            ],
          ),
        );
      },
    );
  }
}

class ScreenshotPainter extends CustomPainter {
  final ui.Image? screenshot;

  ScreenshotPainter({
    required this.screenshot,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final s = screenshot;
    if (s == null) {
      return;
    }
    final screenshotSize = Size(s.width.toDouble(), s.height.toDouble());
    final fittedSizes = applyBoxFit(BoxFit.cover, screenshotSize, size);
    canvas.drawImageRect(
      s,
      Alignment.center
          .inscribe(fittedSizes.source, Offset.zero & screenshotSize),
      Alignment.center.inscribe(fittedSizes.destination, Offset.zero & size),
      Paint(),
    );
  }

  @override
  bool shouldRepaint(covariant ScreenshotPainter oldDelegate) {
    return screenshot == null && oldDelegate.screenshot != null ||
        screenshot != null && oldDelegate.screenshot == null ||
        (screenshot != null &&
            oldDelegate.screenshot != null &&
            !screenshot!.isCloneOf(oldDelegate.screenshot!));
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
