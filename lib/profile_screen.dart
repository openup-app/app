import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/api/users/profile.dart';
import 'package:openup/widgets/back_button.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/home_button.dart';
import 'package:openup/widgets/profile_bio.dart';
import 'package:openup/widgets/image_builder.dart';
import 'package:openup/widgets/theming.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final Profile? profile;
  final bool editable;

  const ProfileScreen({
    Key? key,
    this.profile,
    required this.editable,
  }) : super(key: key);

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _audioBioKey = GlobalKey<ProfileBioState>();

  @override
  Widget build(BuildContext context) {
    Profile? profile = widget.profile;
    if (widget.editable) {
      profile = ref.watch(userProvider.select((p) => p.profile));
    }
    final gallery = profile?.gallery ?? [];
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          if (profile == null) ...[
            const Center(
              child: LoadingIndicator(),
            ),
          ] else ...[
            if (gallery.isEmpty)
              Center(
                child: Text(
                    widget.editable ? 'Add your first photo' : 'No photos',
                    style: Theming.of(context).text.subheading),
              ),
            Positioned.fill(
              child: Gallery(
                gallery: profile.gallery,
                slideshow: !widget.editable,
                blurPhotos: profile.blurPhotos,
              ),
            ),
            if (widget.editable)
              Positioned(
                right: MediaQuery.of(context).padding.right + 16,
                top: MediaQuery.of(context).padding.top + 16,
                child: Button(
                  onPressed: () async {
                    final state = _audioBioKey.currentState;
                    state?.stopAll();
                    await Navigator.of(context).pushNamed('profile-edit');
                    setState(() {});
                  },
                  child: Container(
                    width: 128,
                    height: 128,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(40)),
                      color: Color.fromRGBO(0xC4, 0xC4, 0xC4, 0.5),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.add,
                          size: 48,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Edit Photos',
                          style: Theming.of(context)
                              .text
                              .body
                              .copyWith(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 80,
              height: 88,
              child: Builder(
                builder: (context) {
                  if (widget.editable) {
                    return Consumer(
                      builder: (context, ref, child) {
                        return ProfileBio(
                          key: _audioBioKey,
                          name: profile?.name,
                          url: profile?.audio,
                          editable: true,
                          onRecorded: (audio) {
                            _uploadAudio(
                              context: context,
                              ref: ref,
                              bytes: audio,
                            );
                          },
                          onUpdateName: (name) {
                            _updateName(
                              context: context,
                              ref: ref,
                              name: name,
                            );
                          },
                        );
                      },
                    );
                  } else {
                    return ProfileBio(
                      name: profile!.name,
                      url: profile.audio,
                      editable: false,
                      onRecorded: (_) {},
                      onUpdateName: (_) {},
                    );
                  }
                },
              ),
            ),
          ],
          Positioned(
            left: MediaQuery.of(context).padding.left + 16,
            bottom: MediaQuery.of(context).padding.bottom + 16,
            child: const BackIconButton(),
          ),
          Positioned(
            right: MediaQuery.of(context).padding.right + 16,
            bottom: MediaQuery.of(context).padding.bottom + 16,
            child: const HomeButton(
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _uploadAudio({
    required BuildContext context,
    required WidgetRef ref,
    required Uint8List bytes,
  }) async {
    final result = await withBlockingModal(
      context: context,
      label: 'Uploading audio',
      future: updateAudio(
        context: context,
        ref: ref,
        bytes: bytes,
      ),
    );

    result.fold(
      (l) => displayError(context, l),
      (r) {},
    );
  }

  void _updateName({
    required BuildContext context,
    required WidgetRef ref,
    required String name,
  }) async {
    final result = await withBlockingModal(
      context: context,
      label: 'Updating name',
      future: updateName(
        context: context,
        ref: ref,
        name: name,
      ),
    );

    result.fold(
      (l) => displayError(context, l),
      (r) {},
    );
  }
}

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

class ProfileArguments {
  final Profile? profile;
  final bool editable;

  ProfileArguments({
    this.profile,
    required this.editable,
  });
}
