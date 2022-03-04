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
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Icon(
          Icons.arrow_back_rounded,
          color: color,
        ),
      ),
    );
  }
}
