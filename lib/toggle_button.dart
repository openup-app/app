import 'package:flutter/material.dart';
import 'package:openup/theming.dart';

class ToggleButton extends StatefulWidget {
  final bool value;
  final ValueChanged onChanged;
  const ToggleButton({
    Key? key,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<ToggleButton> createState() => _ToggleButtonState();
}

class _ToggleButtonState extends State<ToggleButton> {
  late bool _value;

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
      child: SizedBox(
        width: 60,
        height: 30,
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 1),
                borderRadius: const BorderRadius.all(Radius.circular(15)),
                color: const Color.fromARGB(0xFF, 0x8B, 0xC0, 0xFF),
                boxShadow: [
                  BoxShadow(
                    color: Theming.of(context).shadow,
                    blurRadius: 4.0,
                    offset: const Offset(0.0, 4.0),
                  )
                ],
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              left: !_value ? 4 : null,
              right: _value ? 4 : null,
              top: 4,
              child: Container(
                width: 21,
                height: 21,
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
