import 'package:flutter/material.dart';
import 'package:openup/widgets/theming.dart';

class ToggleButton extends StatefulWidget {
  final bool value;
  final Color? color;
  final bool useShadow;
  final ValueChanged onChanged;
  const ToggleButton({
    Key? key,
    required this.value,
    this.color = const Color.fromRGBO(0x01, 0xA5, 0x43, 1.0),
    this.useShadow = false,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<ToggleButton> createState() => _ToggleButtonState();
}

class _ToggleButtonState extends State<ToggleButton> {
  late bool _value;
  bool _dragging = false;
  double _left = 4.0;

  @override
  void initState() {
    super.initState();
    _value = widget.value;
  }

  @override
  void didUpdateWidget(covariant ToggleButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    setState(() => _value = widget.value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _value = !_value;
        });
        widget.onChanged(_value);
      },
      onPanStart: (s) {
        setState(() {
          _dragging = true;
          _left = !widget.value ? 4.0 : 23.0;
        });
      },
      onPanUpdate: (s) {
        setState(() {
          _left += s.delta.dx;
          _left = _left.clamp(4.0, 23.0);
        });
      },
      onPanEnd: (_) {
        setState(() => _dragging = false);
        widget.onChanged(
            _left <= 4 ? false : (_left >= 23 ? true : widget.value));
      },
      child: SizedBox(
        width: 47,
        height: 26,
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(15)),
                color: widget.value
                    ? widget.color
                    : const Color.fromRGBO(0x6F, 0x6F, 0x6F, 1.0),
              ),
            ),
            AnimatedPositioned(
              duration:
                  _dragging ? Duration.zero : const Duration(milliseconds: 150),
              left: _dragging ? _left : (!_value ? 4 : 23),
              top: 3,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 1),
                  borderRadius: const BorderRadius.all(Radius.circular(14)),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Theming.of(context).shadow,
                      blurRadius: 4,
                      offset: const Offset(0.0, 4.0),
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
