import 'package:flutter/material.dart';

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
    child: child,
    curve: Curves.easeOut,
  );
}

/// Displays loading progress.
Widget circularProgressLoadingBuilder(
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
          child: Center(
            child: CircularProgressIndicator(
              value: progress.expectedTotalBytes != null
                  ? progress.cumulativeBytesLoaded /
                      progress.expectedTotalBytes!
                  : null,
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
