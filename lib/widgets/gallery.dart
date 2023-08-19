import 'dart:async';

import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
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

  bool _initialDidChangeDependencies = true;

  static const _duration = Duration(seconds: 4);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialDidChangeDependencies) {
      _initialDidChangeDependencies = false;
      _precache();
    }
  }

  void _precache() {
    widget.gallery.forEach((photo3d) {
      precacheImage(NetworkImage(photo3d.url), context);
      precacheImage(NetworkImage(photo3d.depthUrl), context);
    });
  }

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
      _slideshowTimer = Timer(_duration, () {
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
    if (oldWidget.gallery != widget.gallery) {
      _precache();
      _index = 0;
      _maybeStartSlideshowTimer();
    }
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

          return CinematicPhoto(
            key: ValueKey('${_index}_${photo3d.url}'),
            photo3d: photo3d,
            animate: _slideshowTimer?.isActive == true,
            onLoaded: () {
              setState(() => _ready = true);
              _maybeStartSlideshowTimer();
            },
            duration: _duration,
          );
        },
      ),
    );
  }
}

class NonCinematicGallery extends StatefulWidget {
  final List<String> gallery;
  final bool slideshow;

  const NonCinematicGallery({
    Key? key,
    this.gallery = const [],
    required this.slideshow,
  }) : super(key: key);

  @override
  State<NonCinematicGallery> createState() => _NonCinematicGalleryState();
}

class _NonCinematicGalleryState extends State<NonCinematicGallery> {
  Timer? _slideshowTimer;
  bool resetPageOnce = false;
  int _index = 0;
  bool _ready = false;

  bool _initialDidChangeDependencies = true;

  static const _duration = Duration(seconds: 4);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialDidChangeDependencies) {
      _initialDidChangeDependencies = false;
      _precache();
    }
  }

  void _precache() {
    widget.gallery.forEach((photoUrl) {
      precacheImage(NetworkImage(photoUrl), context);
    });
  }

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
      _slideshowTimer = Timer(_duration, () {
        setState(() {
          _index++;
          _ready = false;
        });
      });
    }
  }

  @override
  void didUpdateWidget(covariant NonCinematicGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    final equals = const DeepCollectionEquality().equals;
    if (!equals(oldWidget.gallery, widget.gallery)) {
      _precache();
      _index = 0;
      _maybeStartSlideshowTimer();
    }
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
          final photoUrl = widget.gallery[i];

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            switchInCurve: Curves.easeOutQuart,
            // Don't animate in reverse
            reverseDuration: const Duration(days: 1),
            switchOutCurve: Curves.easeOutQuart,
            transitionBuilder: (child, animation) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.1, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: FadeTransition(
                  opacity: animation,
                  child: child,
                ),
              );
            },
            child: NonCinematicPhoto(
              key: ValueKey('${_index}_$photoUrl'),
              url: photoUrl,
              animate: _slideshowTimer?.isActive == true,
              onLoaded: () {
                setState(() => _ready = true);
                _maybeStartSlideshowTimer();
              },
              duration: _duration,
            ),
          );
        },
      ),
    );
  }
}
