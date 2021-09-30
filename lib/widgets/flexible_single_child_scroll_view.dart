import 'package:flutter/widgets.dart';

/// A [SingleChildScrollView] that allows the child to use
/// [Flexible] widgets.
///
/// Based on https://github.com/flutter/flutter/issues/18711#issuecomment-505791677
class FlexibleSingleChildScrollView extends StatelessWidget {
  final Widget child;
  const FlexibleSingleChildScrollView({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: constraints.maxWidth,
              minHeight: constraints.maxHeight,
            ),
            child: IntrinsicHeight(
              child: child,
            ),
          ),
        );
      },
    );
  }
}
