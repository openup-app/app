import 'package:flutter/material.dart';

class Disable extends StatelessWidget {
  static const ColorFilter _kDefaultColorMatrix = ColorFilter.matrix(
    <double>[
      1, 0, 0, 0, 0, // Comments to stop dart format
      0, 1, 0, 0, 0, //
      0, 0, 1, 0, 0, //
      0, 0, 0, 1, 0, //
    ],
  );

  // Based on Lomski's answer at https://stackoverflow.com/a/62078847/1702627
  static const ColorFilter _kGreyscaleColorMatrix = ColorFilter.matrix(
    <double>[
      0.2126, 0.7152, 0.0722, 0,
      0, // Comments to stop dart format
      0.2126, 0.7152, 0.0722, 0, 0, //
      0.2126, 0.7152, 0.0722, 0, 0, //
      0, 0, 0, 1, 0, //
    ],
  );
  final bool disabling;
  final Widget child;

  const Disable({
    Key? key,
    this.disabling = true,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: disabling,
      child: ColorFiltered(
        colorFilter: !disabling ? _kDefaultColorMatrix : _kGreyscaleColorMatrix,
        child: child,
      ),
    );
  }
}
