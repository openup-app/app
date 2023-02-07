import 'dart:ui' as ui;

import 'package:flutter/material.dart' hide Image;
import 'package:flutter/rendering.dart';

class Screenshot extends StatefulWidget {
  final ScreenshotController controller;
  final Widget child;

  const Screenshot({
    super.key,
    required this.controller,
    required this.child,
  });

  @override
  State<Screenshot> createState() => _ScreenshotState();
}

class _ScreenshotState extends State<Screenshot> {
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: widget.controller._key,
      child: widget.child,
    );
  }
}

class ScreenshotController {
  final _key = GlobalKey();

  Future<ui.Image> takeScreenshot() {
    final renderObject =
        _key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (renderObject == null) {
      throw 'Widget must be mounted to take screenshot';
    }
    return renderObject.toImage();
  }
}
