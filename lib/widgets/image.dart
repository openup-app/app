import 'dart:io';

import 'package:flutter/widgets.dart';

class ImageUri extends StatefulWidget {
  final Uri uri;
  final Widget Function(BuildContext, Widget, int?, bool)? frameBuilder;
  final Widget Function(BuildContext, Widget, ImageChunkEvent?)? loadingBuilder;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;
  final BoxFit? fit;

  const ImageUri(
    this.uri, {
    super.key,
    this.frameBuilder,
    this.loadingBuilder,
    this.errorBuilder,
    this.fit,
  });

  @override
  State<ImageUri> createState() => _ImageUriState();
}

class _ImageUriState extends State<ImageUri> {
  late String _uri;
  File? _file;

  @override
  void initState() {
    super.initState();
    _uriUpdated();
  }

  @override
  void didUpdateWidget(covariant ImageUri oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uri != widget.uri) {
      _uriUpdated();
    }
  }

  void _uriUpdated() {
    _uri = widget.uri.toString();
    try {
      _file = File(widget.uri.toFilePath());
    } on UnsupportedError {
      // Nothing to do
    }
  }

  @override
  Widget build(BuildContext context) {
    final file = _file;
    if (file == null) {
      return Image.network(
        _uri,
        frameBuilder: widget.frameBuilder,
        loadingBuilder: widget.loadingBuilder,
        errorBuilder: widget.errorBuilder,
        fit: widget.fit,
      );
    }
    return Image.file(
      file,
      frameBuilder: widget.frameBuilder,
      errorBuilder: widget.errorBuilder,
      fit: widget.fit,
    );
  }
}
