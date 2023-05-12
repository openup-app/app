import 'package:flutter/material.dart';

class ErrorText extends StatelessWidget {
  final String? errorText;
  final Widget child;

  const ErrorText({
    Key? key,
    this.errorText,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        child,
        AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeIn,
          opacity: errorText == null ? 0.0 : 1.0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 8),
              Text(
                errorText ?? '',
                style: TextStyle(
                  color: Colors.red.shade900,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
