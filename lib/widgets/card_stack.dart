import 'package:flutter/material.dart';
import 'package:openup/widgets/animation.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

typedef ItemBuilder<T> = Function(BuildContext context, T item);

class CardStack<T> extends StatefulWidget {
  final double width;
  final List<T> items;
  final ItemBuilder<T> itemBuilder;
  final void Function(int index) onChanged;

  const CardStack({
    super.key,
    required this.width,
    required this.items,
    required this.onChanged,
    required this.itemBuilder,
  });

  @override
  State<CardStack> createState() => _CardStackState<T>();
}

class _CardStackState<T> extends State<CardStack<T>>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final _items = <T>[];
  final _subItems = <T>[];
  int _topItemIndex = 0;
  final _keys = <GlobalKey>[];
  GlobalKey? _draggingKey;
  bool _dragRight = true;
  double _previousValue = 0.0;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 660,
      ),
    );

    _animation = TweenSequence([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 50,
      ),
    ]).animate(_controller);

    _controller.addStatusListener(_onAnimationStatusUpdate);

    _controller.addListener(_onAnimationUpdate);

    _rebuildItemList();
  }

  @override
  void didUpdateWidget(covariant CardStack<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // TODO: Handle when the list items themselves change
    if (oldWidget.items.length != widget.items.length) {
      _rebuildItemList();
    }
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  void _rebuildItemList() {
    if (widget.items.length >= 3) {
      _items
        ..clear()
        ..addAll(widget.items);
    } else if (widget.items.length == 2) {
      _items
        ..clear()
        ..addAll(widget.items)
        ..add(widget.items[0]);
    } else if (widget.items.length == 1) {
      _items
        ..clear()
        ..addAll(List.generate(3, (_) => widget.items.first));
    }
    _keys
      ..clear()
      ..addAll(List.generate(3, (_) => GlobalKey()));
    _subItems
      ..clear()
      ..addAll(_items);
  }

  void _onAnimationStatusUpdate(AnimationStatus status) {
    if (_draggingKey != null &&
        (status == AnimationStatus.completed ||
            status == AnimationStatus.dismissed)) {
      setState(() => _draggingKey = null);

      if (status == AnimationStatus.completed) {
        setState(() {
          _topItemIndex = (_topItemIndex + 1) % _items.length;
          _subItems[2] = _items[(_topItemIndex + 2) % _items.length];
        });
      }
      _controller.value = 0;
    }
  }

  void _onAnimationUpdate() {
    const reorderThreshold = 0.5;
    final current = _controller.value;
    final justPassedThreshold =
        (_previousValue < reorderThreshold && current >= reorderThreshold) ||
            (_previousValue >= reorderThreshold && current < reorderThreshold);
    final towardsOne = current > _previousValue;
    if (justPassedThreshold && _draggingKey != null) {
      if (towardsOne && _dragRight) {
        // Next
        setState(() {
          _keys.add(_keys.removeAt(0));
          _subItems.add(_subItems.removeAt(0));
        });
        widget.onChanged((_topItemIndex + 1) % _items.length);
      } else if (!towardsOne && _dragRight) {
        // Undo next
        setState(() {
          _keys.insert(0, _keys.removeAt(2));
          _subItems.insert(0, _subItems.removeAt(2));
        });
        widget.onChanged((_topItemIndex - 1) % _items.length);
      } else if (!towardsOne && !_dragRight) {
        // Previous
        setState(() {
          _keys.insert(0, _keys.removeAt(2));
          _subItems.insert(0, _subItems.removeAt(2));
        });
        widget.onChanged((_topItemIndex - 1) % _items.length);
      } else if (towardsOne && _dragRight) {
        // Undo previous
        setState(() {
          _keys.add(_keys.removeAt(0));
          _subItems.add(_subItems.removeAt(0));
        });
        widget.onChanged((_topItemIndex + 1) % _items.length);
      }
    }
    _previousValue =
        _controller.status == AnimationStatus.dismissed ? 0 : _controller.value;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragDown: (details) => _controller.stop(),
      onHorizontalDragUpdate: (details) {
        if (_draggingKey == null) {
          if (details.delta.dx > 0) {
            setState(() {
              _draggingKey = _keys.first;
              _dragRight = true;
            });
          } else if (details.delta.dx < 0) {
            _controller.value = 0.999;
            setState(() {
              _draggingKey = _keys.last;
              _dragRight = false;
              _topItemIndex = (_topItemIndex - 1) % _items.length;
              _subItems[2] = _items[_topItemIndex];
            });
          }
        }

        final delta = details.delta.dx / widget.width;
        _controller.value += delta;
      },
      onHorizontalDragEnd: (details) {
        const velocityThreshold = 400.0;
        final velocity = details.primaryVelocity ?? 0;
        if (_dragRight) {
          if (_controller.value > 0.5 || velocity > velocityThreshold) {
            _controller.forward(from: _controller.value);
          } else {
            _controller.animateBack(0.0);
          }
        } else {
          if (_controller.value < 0.5 ||
              (velocity.sign == -1 && velocity.abs() > velocityThreshold)) {
            _controller.animateBack(0.0);
          } else {
            _controller.forward();
          }
        }
      },
      child: Stack(
        children: [
          for (var i = 2; i >= 0; i--)
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                final key = _keys[i];
                final isDragging = key == _draggingKey;
                const opacityPerCard = 0.25;
                final double opacity = switch (i) {
                      0 => 0.0,
                      1 => _controller.value > 0.5
                          ? 1
                          : 1 - (_controller.value * 2).clamp(0, 1),
                      2 => _controller.value > 0.5
                          ? 1
                          : 2 - (_controller.value * 2).clamp(0, 1),
                      _ => 0,
                    } *
                    opacityPerCard;

                return ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(opacity.clamp(0, 1)),
                    BlendMode.multiply,
                  ),
                  child: Transform.translate(
                    offset: isDragging
                        ? Offset(_animation.value * widget.width, 0)
                        : Offset.zero,
                    child: child,
                  ),
                );
              },
              child: _WiggleAnimation(
                childKey: _keys[i],
                child: widget.itemBuilder(context, _subItems[i]),
              ),
            ),
        ],
      ),
    );
  }
}

class _WiggleAnimation extends StatelessWidget {
  final GlobalKey childKey;
  final Widget child;

  const _WiggleAnimation({
    super.key,
    required this.childKey,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return WiggleBuilder(
      key: childKey,
      seed: childKey.hashCode,
      builder: (context, child, wiggle) {
        final offset = Offset(
          wiggle(frequency: 0.3, amplitude: 30),
          wiggle(frequency: 0.3, amplitude: 30),
        );

        final rotationZ = wiggle(frequency: 0.5, amplitude: radians(8));
        final rotationY = wiggle(frequency: 0.5, amplitude: radians(20));
        const perspectiveDivide = 0.002;
        final transform = Matrix4.identity()
          ..setEntry(3, 2, perspectiveDivide)
          ..rotateY(rotationY)
          ..rotateZ(rotationZ);
        return Transform.translate(
          offset: offset,
          child: Transform(
            transform: transform,
            alignment: Alignment.center,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
