import 'package:flutter/material.dart';

class Button extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPressStart;
  final VoidCallback? onLongPressEnd;
  const Button({
    Key? key,
    required this.child,
    required this.onPressed,
    this.onLongPressStart,
    this.onLongPressEnd,
  }) : super(key: key);

  @override
  State<Button> createState() => _ButtonState();
}

class _ButtonState extends State<Button> with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      value: 1.0,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Opacity(
          opacity: widget.onPressed == null ? 0.5 : _animationController.value,
          child: child!,
        );
      },
      child: IgnorePointer(
        ignoring: widget.onPressed == null,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapDown: (_) => setState(() => _animationController.value = 0.6),
          onTapUp: (_) {
            setState(() {
              _animationController.forward(from: 0.6);
            });
            widget.onPressed?.call();
          },
          onTapCancel: () => setState(() {
            _animationController.forward(from: 0.6);
          }),
          onLongPressStart: widget.onLongPressStart == null
              ? null
              : (_) => widget.onLongPressStart?.call(),
          onLongPressEnd: widget.onLongPressEnd == null
              ? null
              : (_) => widget.onLongPressEnd?.call(),
          child: DefaultTextStyle(
            style: Theme.of(context).textTheme.bodyMedium!,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class GradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool white;
  final Widget child;

  const GradientButton({
    Key? key,
    required this.onPressed,
    this.white = false,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Button(
      onPressed: onPressed,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(14.5)),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0x40, 0x00, 0x00, 0.2),
              offset: Offset(0.0, 4.0),
              blurRadius: 4.0,
            ),
          ],
          gradient: white
              ? null
              : const LinearGradient(
                  colors: [
                    Color.fromRGBO(0xFF, 0x94, 0x94, 1.0),
                    Color.fromRGBO(0xFF, 0xBD, 0xBD, 1.0),
                  ],
                ),
          color: white ? Colors.white : null,
        ),
        child: DefaultTextStyle(
          style: Theme.of(context)
              .textTheme
              .bodyMedium!
              .copyWith(color: white ? Colors.black : null),
          child: child,
        ),
      ),
    );
  }
}
