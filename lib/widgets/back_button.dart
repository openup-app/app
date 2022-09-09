import 'package:flutter/material.dart';
import 'package:openup/widgets/button.dart';

/// Material Design back button which displays the same icon regardless of the
/// current [TargetPlatform].
class BackIconButton extends StatelessWidget {
  final Color? color;
  const BackIconButton({
    Key? key,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Button(
      onPressed: Navigator.of(context).pop,
      child: Icon(
        Icons.chevron_left,
        color: color,
        size: 46,
      ),
    );
  }
}
