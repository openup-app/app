import 'dart:async';

import 'package:flutter/material.dart';
import 'package:openup/api/api.dart';
import 'package:openup/widgets/common.dart';

class Gallery extends StatefulWidget {
  final List<String> gallery;
  final bool slideshow;

  const Gallery({
    Key? key,
    this.gallery = const [],
    required this.slideshow,
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

class CinematicGallery extends StatefulWidget {
  final List<Photo3d> gallery;
  final bool slideshow;

  const CinematicGallery({
    Key? key,
    this.gallery = const [],
    required this.slideshow,
  }) : super(key: key);

  @override
  State<CinematicGallery> createState() => _CinematicGalleryState();
}

class _CinematicGalleryState extends State<CinematicGallery> {
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
      _slideshowTimer = Timer(const Duration(seconds: 4), () {
        setState(() {
          _index++;
          _ready = false;
        });
      });
    }
  }

  @override
  void didUpdateWidget(covariant CinematicGallery oldWidget) {
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
          final photo3d = widget.gallery[i];

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 800),
            child: CinematicPhoto(
              key: ValueKey(_index),
              photo3d: photo3d,
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
