import 'package:flutter/material.dart';
import 'package:openup/widgets/common.dart';

/// Fades in the child when a frame is avaialbel (i.e. [frame] is not null).
/// Used when loading images.
Widget fadeInFrameBuilder(
  BuildContext context,
  Widget child,
  int? frame,
  bool wasSynchronouslyLoaded,
) {
  if (wasSynchronouslyLoaded) {
    return child;
  }
  return AnimatedOpacity(
    opacity: frame == null ? 0 : 1,
    duration: const Duration(milliseconds: 400),
    curve: Curves.easeOut,
    child: child,
  );
}

/// Displays loading progress.
Widget loadingBuilder(
  BuildContext context,
  Widget child,
  ImageChunkEvent? progress,
) {
  return Stack(
    alignment: Alignment.center,
    fit: StackFit.passthrough,
    children: [
      child,
      if (progress != null)
        Container(
          color: Colors.transparent,
          child: const Center(
            child: LoadingIndicator(
              size: 24,
            ),
          ),
        ),
    ],
  );
}

/// Error widget to display when loading fails.
Widget iconErrorBuilder(context, error, stackTrace) {
  return const Center(
    child: Icon(
      Icons.error,
      color: Colors.red,
    ),
  );
}
