import 'package:flutter/material.dart';
import 'package:openup/profile_page2.dart';
import 'package:openup/widgets/button.dart';

class Carousel extends StatefulWidget {
  final Widget child;
  const Carousel({
    super.key,
    required this.child,
  });

  @override
  State<Carousel> createState() => CarouselState();
}

class CarouselState extends State<Carousel>
    with SingleTickerProviderStateMixin {
  late final _animationController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );
  bool _showMenu = false;
  int _selectedPage = 0;

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final previews = [
      _Preview(
        animation: _animationController,
        alignment: Alignment.topLeft,
        selected: _selectedPage == 0,
        onPressed: _showMenu
            ? () {
                setState(() => _selectedPage = 0);
                showMenu = false;
              }
            : null,
        child: widget.child,
      ),
      _Preview(
        animation: _animationController,
        alignment: Alignment.topRight,
        selected: _selectedPage == 1,
        onPressed: _showMenu ? () {} : null,
        child: const Placeholder(),
      ),
      _Preview(
        animation: _animationController,
        alignment: Alignment.bottomLeft,
        selected: _selectedPage == 2,
        onPressed: _showMenu
            ? () {
                setState(() => _selectedPage = 2);
                showMenu = false;
              }
            : null,
        child: const ProfilePage2(),
      ),
      _Preview(
        animation: _animationController,
        alignment: Alignment.bottomRight,
        selected: _selectedPage == 3,
        onPressed: _showMenu ? () {} : null,
        child: const Placeholder(),
      ),
    ];

    // Display on top of other pages in case its full screen
    final selectedPage = previews.removeAt(_selectedPage);
    previews.add(selectedPage);

    return Stack(
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
        AnimatedPadding(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: _showMenu
              ? EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top,
                  bottom: 56.0 + MediaQuery.of(context).padding.bottom,
                )
              : EdgeInsets.zero,
          child: Stack(
            children: [
              ...previews,
            ],
          ),
        ),
      ],
    );
  }

  set showMenu(bool value) {
    if (value) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
    setState(() => _showMenu = value);
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

class _Preview extends StatefulWidget {
  final AnimationController animation;
  final Alignment alignment;
  final bool selected;
  final VoidCallback? onPressed;
  final Widget child;

  const _Preview({
    super.key,
    required this.animation,
    required this.alignment,
    required this.selected,
    required this.onPressed,
    required this.child,
  });

  @override
  State<_Preview> createState() => _PreviewState();
}

class _PreviewState extends State<_Preview> {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.animation,
      builder: (
        context,
        child,
      ) {
        final Animation<double> curvedAnimation;
        if (!widget.selected) {
          curvedAnimation = const AlwaysStoppedAnimation<double>(1.0);
        } else {
          curvedAnimation = CurvedAnimation(
            parent: widget.animation,
            curve: widget.animation.status == AnimationStatus.forward
                ? Curves.easeOutBack
                : Curves.easeInBack,
          );
        }
        return Transform.scale(
          alignment: widget.alignment,
          scale: Tween(
            begin: 1.0,
            end: 0.5,
          ).animate(curvedAnimation).value,
          child: Transform.scale(
            alignment: -widget.alignment * 0.6,
            scale: Tween(
              begin: 1.0,
              end: 0.90,
            ).animate(curvedAnimation).value,
            child: ClipRRect(
              clipBehavior: Clip.hardEdge,
              borderRadius: Tween<BorderRadius>(
                begin: BorderRadius.zero,
                end: const BorderRadius.all(Radius.circular(33)),
              ).animate(curvedAnimation).value,
              child: child!,
            ),
          ),
        );
      },
      child: widget.onPressed != null
          ? Button(
              onPressed: widget.onPressed,
              child: IgnorePointer(
                child: widget.child,
              ),
            )
          : widget.child,
    );
  }
}
