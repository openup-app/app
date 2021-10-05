import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:openup/widgets/theming.dart';

class InputArea extends StatelessWidget {
  final String? errorText;
  final Widget child;

  const InputArea({
    Key? key,
    this.errorText,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64.0,
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(32)),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Theming.of(context).shadow,
            offset: const Offset(0.0, 4.0),
            blurRadius: 1.0,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          DefaultTextStyle(
            style: Theming.of(context).text.body.copyWith(color: Colors.grey),
            child: Center(child: child),
          ),
          if (errorText != null)
            Positioned(
              bottom: -1,
              child: Text(
                errorText!,
                style: Theming.of(context)
                    .text
                    .caption
                    .copyWith(color: Colors.red, fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }
}
