import 'dart:async';

import 'package:flutter/material.dart';
import 'package:openup/widgets/common.dart';

class Gallery extends StatefulWidget {
  final List<String> gallery;
  final bool slideshow;
  final bool withWideBlur;
  final bool blurPhotos;

  const Gallery({
    Key? key,
    this.gallery = const [],
    required this.slideshow,
    this.withWideBlur = true,
    required this.blurPhotos,
  }) : super(key: key);

  @override
  State<Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<Gallery> {
  Timer? _slideshowTimer;
  bool resetPageOnce = false;
  int _index = 0;
  bool _ready = false;

  @override
  void dispose() {
    _slideshowTimer?.cancel();
    super.dispose();
  }

  void _maybeStartSlideshowTimer() {
    if (!widget.slideshow) {
      return;
    }
    if (_ready) {
      _slideshowTimer?.cancel();
      _slideshowTimer = Timer(const Duration(seconds: 3), () {
        setState(() {
          _index++;
          _ready = false;
        });
      });
    }
  }

  @override
  void didUpdateWidget(covariant Gallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.slideshow != widget.slideshow) {
      if (widget.slideshow) {
        _maybeStartSlideshowTimer();
      } else {
        _slideshowTimer?.cancel();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: Builder(
        builder: (context) {
          if (widget.gallery.isEmpty) {
            return const SizedBox.shrink();
          }
          final i = _index % widget.gallery.length;
          final photo = widget.gallery[i];

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 800),
            child: ProfileImage(
              key: ValueKey(_index),
              photo,
              blur: widget.blurPhotos,
              animate: _slideshowTimer?.isActive == true,
              onLoaded: () {
                setState(() => _ready = true);
                _maybeStartSlideshowTimer();
              },
            ),
          );
        },
      ),
    );
  }
}
