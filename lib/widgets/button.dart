import 'package:flutter/material.dart';
import 'package:openup/widgets/theming.dart';

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
  _ButtonState createState() => _ButtonState();
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
            style: Theming.of(context).text.body,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
