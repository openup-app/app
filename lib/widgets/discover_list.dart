import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openup/api/api.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/profile_display.dart';

import '../platform/just_audio_audio_player.dart';

class DiscoverList extends ConsumerStatefulWidget {
  final List<DiscoverProfile> profiles;
  final DiscoverProfile? selectedProfile;
  final EdgeInsets itemPadding;
  final ValueChanged<DiscoverProfile?> onProfileChanged;
  final PlaybackState playbackState;
  final Stream<PlaybackInfo> playbackInfoStream;
  final VoidCallback onPlayPause;
  final VoidCallback onRecord;
  final VoidCallback onToggleFavorite;
  final VoidCallback onProfilePressed;

  const DiscoverList({
    super.key,
    required this.profiles,
    required this.selectedProfile,
    this.itemPadding = EdgeInsets.zero,
    required this.onProfileChanged,
    required this.playbackState,
    required this.playbackInfoStream,
    required this.onPlayPause,
    required this.onRecord,
    required this.onToggleFavorite,
    required this.onProfilePressed,
  });

  @override
  ConsumerState<DiscoverList> createState() => _DisoverListState();
}

class _DisoverListState extends ConsumerState<DiscoverList> {
  final _pageListener = ValueNotifier<double>(0);
  late final PageController _pageController;
  bool _reportPageChange = true;

  @override
  void initState() {
    super.initState();

    final initialSelectedProfile = widget.selectedProfile;
    final initialIndex = initialSelectedProfile == null
        ? 0
        : widget.profiles.indexWhere(
            (p) => p.profile.uid == initialSelectedProfile.profile.uid);
    _pageController = PageController(initialPage: initialIndex);

    _pageController.addListener(() {
      final page = _pageController.page ?? 0;
      _pageListener.value = page;
      final selectedProfile = widget.selectedProfile;
      final selectedIndex = selectedProfile == null
          ? 0
          : widget.profiles
              .indexWhere((p) => p.profile.uid == selectedProfile.profile.uid);
      final index = _pageController.page?.round() ?? selectedIndex;
      if (index != selectedIndex && _reportPageChange) {
        widget.onProfileChanged(widget.profiles[index]);
      }
    });
  }

  @override
  void didUpdateWidget(covariant DiscoverList oldWidget) {
    super.didUpdateWidget(oldWidget);
    final selectedProfile = widget.selectedProfile;
    final selectedIndex = selectedProfile == null
        ? 0
        : widget.profiles
            .indexWhere((p) => p.profile.uid == selectedProfile.profile.uid);
    final index = _pageController.page?.round() ?? selectedIndex;
    if (index != selectedIndex) {
      setState(() => _reportPageChange = false);
      _pageController
          .animateToPage(
        selectedIndex,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutQuart,
      )
          .then((_) {
        if (mounted) {
          setState(() => _reportPageChange = true);
        }
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 310 + widget.itemPadding.vertical,
      child: PageView.builder(
        controller: _pageController,
        clipBehavior: Clip.none,
        padEnds: true,
        itemCount: widget.profiles.length,
        itemBuilder: (context, index) {
          final profile = widget.profiles[index];
          final selected =
              profile.profile.uid == widget.selectedProfile?.profile.uid;
          return _MiniProfile(
            profile: profile,
            playbackState: widget.playbackState,
            playbackInfoStream:
                selected ? widget.playbackInfoStream : const Stream.empty(),
            onProfileChanged: widget.onProfileChanged,
            onPlayPause: widget.onPlayPause,
            onRecord: widget.onRecord,
            onToggleFavorite: widget.onToggleFavorite,
            onProfilePressed: widget.onProfilePressed,
          );
        },
      ),
    );
  }
}

class DiscoverListFull extends ConsumerStatefulWidget {
  final List<DiscoverProfile> profiles;
  final DiscoverProfile? selectedProfile;
  final ValueChanged<DiscoverProfile?> onProfileChanged;
  final bool play;
  final VoidCallback onPlayPause;
  final VoidCallback onRecord;
  final VoidCallback onBlock;

  const DiscoverListFull({
    super.key,
    required this.profiles,
    required this.selectedProfile,
    required this.onProfileChanged,
    required this.play,
    required this.onPlayPause,
    required this.onRecord,
    required this.onBlock,
  });

  @override
  ConsumerState<DiscoverListFull> createState() => _DisoverListFullState();
}

class _DisoverListFullState extends ConsumerState<DiscoverListFull> {
  final _pageListener = ValueNotifier<double>(0);
  late final PageController _pageController;
  bool _reportPageChange = true;

  @override
  void initState() {
    super.initState();

    final initialSelectedProfile = widget.selectedProfile;
    final initialIndex = initialSelectedProfile == null
        ? 0
        : widget.profiles.indexWhere(
            (p) => p.profile.uid == initialSelectedProfile.profile.uid);
    _pageController = PageController(initialPage: initialIndex);

    _pageController.addListener(() {
      final page = _pageController.page ?? 0;
      _pageListener.value = page;
      final selectedProfile = widget.selectedProfile;
      final selectedIndex = selectedProfile == null
          ? 0
          : widget.profiles
              .indexWhere((p) => p.profile.uid == selectedProfile.profile.uid);
      final index = _pageController.page?.round() ?? selectedIndex;
      if (index != selectedIndex && _reportPageChange) {
        widget.onProfileChanged(widget.profiles[index]);
      }
    });
  }

  @override
  void didUpdateWidget(covariant DiscoverListFull oldWidget) {
    super.didUpdateWidget(oldWidget);
    final selectedProfile = widget.selectedProfile;
    final selectedIndex = selectedProfile == null
        ? 0
        : widget.profiles
            .indexWhere((p) => p.profile.uid == selectedProfile.profile.uid);
    final index = _pageController.page?.round() ?? selectedIndex;
    if (index != selectedIndex) {
      setState(() => _reportPageChange = false);
      _pageController
          .animateToPage(
        selectedIndex,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutQuart,
      )
          .then((_) {
        if (mounted) {
          setState(() => _reportPageChange = true);
        }
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      padEnds: true,
      itemCount: widget.profiles.length,
      itemBuilder: (context, index) {
        final profile = widget.profiles[index];
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: 16 + MediaQuery.of(context).padding.bottom,
          ),
          child: ProfileDisplay(
            profile: profile.profile,
            play: widget.play,
            onPlayPause: widget.onPlayPause,
            onRecord: widget.onRecord,
            onBlock: widget.onBlock,
          ),
        );
      },
    );
  }
}

class _MiniProfile extends StatelessWidget {
  final DiscoverProfile profile;
  final PlaybackState playbackState;
  final Stream<PlaybackInfo> playbackInfoStream;
  final ValueChanged<DiscoverProfile?> onProfileChanged;
  final VoidCallback onPlayPause;
  final VoidCallback onRecord;
  final VoidCallback onToggleFavorite;
  final VoidCallback onProfilePressed;

  const _MiniProfile({
    super.key,
    required this.profile,
    required this.playbackState,
    required this.playbackInfoStream,
    required this.onProfileChanged,
    required this.onPlayPause,
    required this.onRecord,
    required this.onToggleFavorite,
    required this.onProfilePressed,
  });

  @override
  Widget build(BuildContext context) {
    final mutualContactCount = profile.profile.mutualContacts.length;
    return Stack(
      fit: StackFit.expand,
      children: [
        // White background so the card doesn't become see through when tapped
        ...[
          const Positioned(
            top: 20,
            left: 0,
            right: 0,
            bottom: 0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(34)),
              ),
            ),
          ),
          const Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: 100,
              height: 100,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
        Button(
          onPressed: onProfilePressed,
          child: Stack(
            children: [
              Positioned(
                top: 20,
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  clipBehavior: Clip.hardEdge,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(34)),
                    boxShadow: [
                      BoxShadow(
                        offset: Offset(0, 4),
                        blurRadius: 8,
                        color: Color.fromRGBO(0x00, 0x00, 0x00, 0.25),
                      ),
                    ],
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Positioned(
                        left: 12,
                        top: 12,
                        child: Button(
                          onPressed: () => onProfileChanged(null),
                          child: Container(
                            width: 48,
                            height: 48,
                            padding: const EdgeInsets.all(12),
                            child: const DecoratedBox(
                              decoration: BoxDecoration(
                                color: Color.fromRGBO(0x3D, 0x3D, 0x3D, 0.25),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 12,
                        top: 12,
                        child: Button(
                          onPressed: onToggleFavorite,
                          child: Container(
                            width: 48,
                            height: 48,
                            color: Colors.transparent,
                            alignment: Alignment.center,
                            child: Icon(
                              profile.favorite
                                  ? Icons.favorite
                                  : Icons.favorite_outline,
                              color: profile.favorite
                                  ? const Color.fromRGBO(0xFF, 0x4F, 0x4F, 1.0)
                                  : const Color.fromRGBO(
                                      0x3D, 0x3D, 0x3D, 0.25),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 12,
                        bottom: MediaQuery.of(context).padding.bottom + 12,
                        child: Button(
                          onPressed: onPlayPause,
                          child: Container(
                            width: 48,
                            height: 48,
                            alignment: Alignment.center,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color.fromRGBO(0x00, 0x85, 0xFF, 1.0),
                              ),
                              child: Builder(
                                builder: (context) {
                                  switch (playbackState) {
                                    case PlaybackState.playing:
                                      return const Icon(
                                        Icons.pause_rounded,
                                        size: 18,
                                        color: Colors.white,
                                      );
                                    case PlaybackState.loading:
                                      return const LoadingIndicator(
                                        size: 12,
                                        color: Colors.white,
                                      );
                                    default:
                                      return const Icon(
                                        Icons.play_arrow_rounded,
                                        size: 18,
                                        color: Colors.white,
                                      );
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 96),
                          AutoSizeText(
                            profile.profile.name,
                            textAlign: TextAlign.center,
                            minFontSize: 16,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: const TextStyle(
                                color: Color.fromRGBO(0x45, 0x45, 0x45, 1.0),
                              ),
                              children: [
                                TextSpan(
                                  text: '$mutualContactCount Shared ',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700),
                                ),
                                TextSpan(
                                  text:
                                      'Connection${mutualContactCount == 1 ? '' : 's'}',
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 26),
                            child: StreamBuilder<double>(
                              stream: playbackInfoStream.map((e) {
                                return e.duration.inMilliseconds == 0
                                    ? 0
                                    : e.position.inMilliseconds /
                                        e.duration.inMilliseconds;
                              }),
                              initialData: 0.0,
                              builder: (context, snapshot) {
                                return DecoratedBox(
                                  decoration: const BoxDecoration(
                                    color:
                                        Color.fromRGBO(0xE1, 0xE1, 0xE1, 1.0),
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(2)),
                                  ),
                                  child: FractionallySizedBox(
                                    widthFactor: snapshot.requireData,
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      height: 4,
                                      decoration: const BoxDecoration(
                                        color: Color.fromRGBO(
                                            0x3E, 0x97, 0xFF, 1.0),
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(2)),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const Spacer(),
                          Center(
                            child: Button(
                              onPressed: onRecord,
                              child: Container(
                                width: 123,
                                height: 46,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    width: 1.3,
                                    color: const Color.fromRGBO(
                                        0x00, 0x85, 0xFF, 1.0),
                                  ),
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(25),
                                  ),
                                ),
                                child: const Text(
                                  'send message',
                                  style: TextStyle(
                                    color:
                                        Color.fromRGBO(0x00, 0x85, 0xFF, 1.0),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: MediaQuery.of(context).padding.bottom,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  width: 100,
                  height: 100,
                  clipBehavior: Clip.hardEdge,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        offset: Offset(0, 1),
                        blurRadius: 4,
                        color: Color.fromRGBO(0x00, 0x00, 0x00, 0.25),
                      ),
                    ],
                  ),
                  child: Container(
                    foregroundDecoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        width: 2,
                        color: Colors.white,
                      ),
                    ),
                    child: Image.network(
                      profile.profile.photo,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
