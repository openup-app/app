import 'package:flutter/material.dart';

class InputArea extends StatelessWidget {
  final String? errorText;
  final Color color;
  final Widget child;

  const InputArea({
    Key? key,
    this.errorText,
    this.color = Colors.white,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64.0,
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Stack(
        alignment: Alignment.center,
        children: [
          DefaultTextStyle(
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: Colors.white,
                  fontSize: 20,
                ),
            child: Center(child: child),
          ),
          if (errorText != null)
            Positioned(
              bottom: -1,
              child: Text(
                errorText!,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: Colors.red.shade900,
                      fontSize: 14,
                    ),
              ),
            ),
        ],
      ),
    );
  }
}
