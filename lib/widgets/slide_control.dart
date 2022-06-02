import 'package:flutter/material.dart';
import 'package:openup/widgets/theming.dart';

class SlideControl extends StatefulWidget {
  final Widget thumbContents;
  final Widget trackContents;
  final bool trackBorder;
  final Gradient? trackGradient;
  final Color? trackColor;
  final VoidCallback onSlideComplete;
  final void Function(double value)? onSlideUpdate;

  const SlideControl({
    Key? key,
    required this.thumbContents,
    required this.trackContents,
    this.trackBorder = false,
    this.trackGradient,
    this.trackColor,
    required this.onSlideComplete,
    this.onSlideUpdate,
  }) : super(key: key);

  @override
  State<SlideControl> createState() => _SlideControlState();
}

class _SlideControlState extends State<SlideControl>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  Offset _dragStart = Offset.zero;
  double _valueStart = 0.0;
  double _value = 0.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 300,
      ),
    );
    _animationController.addListener(() {
      setState(() => _value = 1 - _animationController.value);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const thumbSize = 66.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final trackWidth = constraints.maxWidth - (8 * 2);
        final height = widget.trackBorder ? 93.0 : 81.0;
        return Stack(
          children: [
            Opacity(
              opacity: 0.5,
              child: Container(
                height: height,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(50)),
                  border: widget.trackBorder
                      ? Border.all(color: Colors.white, width: 4)
                      : null,
                  gradient: widget.trackGradient,
                  color: widget.trackColor,
                ),
              ),
            ),
            SizedBox(
              height: height,
              child: Padding(
                padding: widget.trackBorder
                    ? const EdgeInsets.symmetric(horizontal: 4.0)
                    : const EdgeInsets.symmetric(horizontal: 8.0),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 81),
                        child: DefaultTextStyle(
                          style: Theming.of(context).text.bodySecondary,
                          child: widget.trackContents,
                        ),
                      ),
                    ),
                    Positioned(
                      left: (_value * (trackWidth - thumbSize)),
                      top: 0,
                      bottom: 0,
                      child: GestureDetector(
                        onHorizontalDragDown: (details) {
                          setState(() {
                            _dragStart = details.localPosition;
                            _valueStart = _value;
                          });
                        },
                        onHorizontalDragUpdate: (details) {
                          final travel =
                              (details.localPosition - _dragStart).dx;
                          final travelRatio = travel / (trackWidth - thumbSize);
                          final value = _valueStart + travelRatio;
                          setState(() => _value = value.clamp(0.0, 1.0));
                          widget.onSlideUpdate?.call(_value);
                        },
                        onHorizontalDragEnd: (details) {
                          if (_value == 1.0) {
                            widget.onSlideComplete();
                          }
                          _animateThumbToStart();
                        },
                        onHorizontalDragCancel: _animateThumbToStart,
                        child: Container(
                          width: thumbSize,
                          height: thumbSize,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: widget.thumbContents,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _animateThumbToStart() {
    _animationController.forward(from: 1 - _value);
  }
}
