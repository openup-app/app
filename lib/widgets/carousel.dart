import 'package:flutter/material.dart';
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

  set showMenu(bool value) {
    if (value) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
    setState(() => _showMenu = value);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          top: 75,
          child: Text(
            'Discover new people',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyMedium!
                .copyWith(fontWeight: FontWeight.w300, fontSize: 20),
          ),
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
        AnimatedBuilder(
          animation: _animationController,
          builder: (
            context,
            child,
          ) {
            final curvedAnimation = CurvedAnimation(
              parent: _animationController,
              curve: _animationController.status == AnimationStatus.forward
                  ? Curves.easeOutBack
                  : Curves.easeInBack,
            );
            return Transform.scale(
              scale: Tween(
                begin: 1.0,
                end: 0.66,
              ).animate(curvedAnimation).value,
              child: ClipRRect(
                borderRadius: Tween<BorderRadius>(
                  begin: BorderRadius.zero,
                  end: const BorderRadius.all(Radius.circular(33)),
                ).animate(curvedAnimation).value,
                child: child!,
              ),
            );
          },
          child: _showMenu
              ? Button(
                  onPressed: () => showMenu = false,
                  child: IgnorePointer(
                    child: widget.child,
                  ),
                )
              : widget.child,
        ),
      ],
    );
  }
}
