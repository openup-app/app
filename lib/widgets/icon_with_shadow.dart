import 'package:decorated_icon/decorated_icon.dart';
import 'package:flutter/cupertino.dart';

/// Icon that can display an icon shaped shadow.
class IconWithShadow extends StatelessWidget {
  final IconData icon;
  final double? size;
  final Color? color;
  final List<BoxShadow> shadows;
  final TextDirection? textDirection;
  final String? semanticLabel;

  const IconWithShadow(
    this.icon, {
    Key? key,
    this.size,
    this.color,
    this.textDirection,
    this.shadows = const [
      BoxShadow(
        color: Color.fromRGBO(0x00, 0x00, 0x00, 0.5),
        offset: Offset(0.0, 2.0),
        blurRadius: 4,
        spreadRadius: 4,
      ),
    ],
    this.semanticLabel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DecoratedIcon(
      icon,
      size: size,
      color: color,
      shadows: shadows,
      textDirection: textDirection,
      semanticLabel: semanticLabel,
    );
  }
}
