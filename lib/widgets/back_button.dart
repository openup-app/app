import 'package:flutter/cupertino.dart';
import 'package:openup/widgets/button.dart';

/// Material Design back button which displays the same icon regardless of the
/// current [TargetPlatform].
class BackIconButton extends StatelessWidget {
  final Color? color;
  final VoidCallback? onPressed;
  const BackIconButton({
    Key? key,
    this.color = const Color.fromRGBO(0xBA, 0xBA, 0xBA, 1.0),
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Button(
      onPressed: onPressed ?? Navigator.of(context).pop,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(
          CupertinoIcons.back,
          color: color,
          size: 32,
        ),
      ),
    );
  }
}
