import 'package:flutter/material.dart';

class KeyboardScreen extends StatelessWidget {
  final Widget child;
  const KeyboardScreen({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: MediaQuery.of(context).viewInsets,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: constraints.maxHeight,
            ),
            child: child,
          ),
        );
      },
    );
  }
}
