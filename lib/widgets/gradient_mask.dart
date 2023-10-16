import 'package:flutter/widgets.dart';

class GradientMask extends StatelessWidget {
  final Gradient gradient;
  final Widget child;

  const GradientMask({
    super.key,
    required this.gradient,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: gradient.createShader,
      child: child,
    );
  }
}
