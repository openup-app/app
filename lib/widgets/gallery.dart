import 'dart:async';
import 'dart:ui';

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
  PageController? _pageController;
  Timer? _slideshowTimer;
  bool resetPageOnce = false;

  @override
  void initState() {
    super.initState();
    _resetPage();
  }

  @override
  void dispose() {
    _pageController?.dispose();
    _slideshowTimer?.cancel();
    super.dispose();
  }

  void _resetPage() {
    final gallery = widget.gallery;
    _pageController?.dispose();
    setState(() {
      _pageController = PageController(initialPage: gallery.length * 100000);
    });
    _maybeStartSlideshowTimer();
  }

  void _maybeStartSlideshowTimer() {
    if (!widget.slideshow) {
      return;
    }
    _slideshowTimer?.cancel();
    _slideshowTimer = Timer(const Duration(seconds: 3), () {
      final pageController = _pageController;
      final page = pageController?.page;
      if (pageController != null && page != null) {
        pageController.animateToPage(
          page.toInt() + 1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
      _maybeStartSlideshowTimer();
    });
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
    return Listener(
      onPointerDown: (_) => _slideshowTimer?.cancel(),
      onPointerUp: (_) => _maybeStartSlideshowTimer(),
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: ClipRRect(
          child: PageView.builder(
            controller: _pageController,
            itemBuilder: (context, index) {
              if (widget.gallery.isEmpty) {
                return const SizedBox.shrink();
              }
              final i = index % widget.gallery.length;
              if (widget.withWideBlur) {
                return Stack(
                  clipBehavior: Clip.hardEdge,
                  fit: StackFit.expand,
                  alignment: Alignment.center,
                  children: [
                    ClipRect(
                      clipBehavior: Clip.hardEdge,
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(
                          sigmaX: 16,
                          sigmaY: 16,
                        ),
                        child: ProfileImage(
                          widget.gallery[i],
                          blur: widget.blurPhotos,
                        ),
                      ),
                    ),
                    ProfileImage(
                      widget.gallery[i],
                      fit: BoxFit.contain,
                      blur: widget.blurPhotos,
                    ),
                  ],
                );
              } else {
                return ProfileImage(
                  widget.gallery[i],
                  blur: widget.blurPhotos,
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
