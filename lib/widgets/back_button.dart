import 'package:flutter/cupertino.dart';
import 'package:openup/widgets/button.dart';

/// Button which displays a back chevron,
class BackIconButton extends StatelessWidget {
  final Color color;
  final double size;
  final VoidCallback? onPressed;
  const BackIconButton({
    Key? key,
    this.color = const Color.fromRGBO(0xBA, 0xBA, 0xBA, 1.0),
    this.size = 32,
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Button(
      onPressed: onPressed ?? Navigator.of(context).pop,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: BackIcon(
          color: color,
          size: size,
        ),
      ),
    );
  }
}

class BackIcon extends StatelessWidget {
  final Color color;
  final double size;

  const BackIcon({
    super.key,
    this.color = const Color.fromRGBO(0xBA, 0xBA, 0xBA, 1.0),
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    return Icon(
      CupertinoIcons.back,
      color: color,
      size: size,
    );
  }
}
