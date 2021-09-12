import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:openup/theming.dart';

class InputArea extends StatelessWidget {
  final Widget child;

  const InputArea({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60.0,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(30)),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Theming.of(context).shadow,
            offset: const Offset(0.0, 4.0),
            blurRadius: 1.0,
          ),
        ],
      ),
      child: DefaultTextStyle(
        style: Theming.of(context).text.body.copyWith(color: Colors.grey),
        child: Center(child: child),
      ),
    );
  }
}
