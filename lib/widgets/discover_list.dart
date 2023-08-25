import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openup/api/api.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';

import '../platform/just_audio_audio_player.dart';

class DiscoverList extends ConsumerStatefulWidget {
  final List<DiscoverProfile> profiles;
  final DiscoverProfile? selectedProfile;
  final ValueChanged<DiscoverProfile?> onProfileChanged;
  final PlaybackState playbackState;
  final Stream<PlaybackInfo> playbackInfoStream;
  final VoidCallback onPlay;
  final VoidCallback onPause;
  final VoidCallback onToggleFavorite;
  final VoidCallback onProfilePressed;

  const DiscoverList({
    super.key,
    required this.profiles,
    required this.selectedProfile,
    required this.onProfileChanged,
    required this.playbackState,
    required this.playbackInfoStream,
    required this.onPlay,
    required this.onPause,
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
      height: 80,
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
            playbackInfoStream:
                selected ? widget.playbackInfoStream : const Stream.empty(),
            onProfileChanged: widget.onProfileChanged,
            onPlay: widget.onPlay,
            onPause: widget.onPause,
            onToggleFavorite: widget.onToggleFavorite,
            onProfilePressed: widget.onProfilePressed,
          );
        },
      ),
    );
  }
}

class _MiniProfile extends StatelessWidget {
  final DiscoverProfile profile;
  final Stream<PlaybackInfo> playbackInfoStream;
  final ValueChanged<DiscoverProfile?> onProfileChanged;
  final VoidCallback onPlay;
  final VoidCallback onPause;
  final VoidCallback onToggleFavorite;
  final VoidCallback onProfilePressed;

  const _MiniProfile({
    super.key,
    required this.profile,
    required this.playbackInfoStream,
    required this.onProfileChanged,
    required this.onPlay,
    required this.onPause,
    required this.onToggleFavorite,
    required this.onProfilePressed,
  });

  @override
  Widget build(BuildContext context) {
    final mutualContactCount = profile.profile.mutualContacts.length;
    return Button(
      onPressed: onProfilePressed,
      child: Stack(
        children: [
          Row(
            children: [
              const SizedBox(width: 21),
              Container(
                width: 50,
                height: 50,
                clipBehavior: Clip.hardEdge,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                  boxShadow: [
                    BoxShadow(
                      offset: Offset(0, 1),
                      blurRadius: 9,
                      color: Color.fromRGBO(0x00, 0x00, 0x00, 0.35),
                    ),
                  ],
                ),
                child: Image.network(
                  profile.profile.photo,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AutoSizeText(
                      profile.profile.name,
                      textAlign: TextAlign.center,
                      minFontSize: 16,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Color.fromRGBO(0x3C, 0x3C, 0x3C, 1.0),
                      ),
                    ),
                    const SizedBox(height: 4),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: Color.fromRGBO(0x45, 0x45, 0x45, 1.0),
                        ),
                        children: [
                          TextSpan(
                            text: '$mutualContactCount Shared ',
                          ),
                          TextSpan(
                            text:
                                'Connection${mutualContactCount == 1 ? '' : 's'}',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Button(
                onPressed: onToggleFavorite,
                child: Container(
                  width: 48,
                  height: 48,
                  color: Colors.transparent,
                  alignment: Alignment.center,
                  child: Icon(
                    profile.favorite ? Icons.favorite : Icons.favorite_outline,
                    color: profile.favorite
                        ? const Color.fromRGBO(0xFF, 0x4F, 0x4F, 1.0)
                        : const Color.fromRGBO(0x3D, 0x3D, 0x3D, 1.0),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              StreamBuilder<PlaybackState>(
                initialData: PlaybackState.idle,
                stream: playbackInfoStream.map((e) => e.state),
                builder: (context, snapshot) {
                  final playbackState = snapshot.requireData;
                  return Button(
                    onPressed: () {
                      switch (playbackState) {
                        case PlaybackState.idle:
                        case PlaybackState.paused:
                          onPlay();
                          break;
                        default:
                          onPause();
                      }
                    },
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
                          builder: (conext) {
                            switch (playbackState) {
                              case PlaybackState.playing:
                                return const Icon(
                                  Icons.pause_rounded,
                                  size: 18,
                                  color: Colors.white,
                                );
                              case PlaybackState.loading:
                                return const LoadingIndicator(
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
                  );
                },
              ),
              const SizedBox(width: 16),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 4,
            child: StreamBuilder<double>(
              stream: playbackInfoStream.map((e) {
                return e.duration.inMilliseconds == 0
                    ? 0
                    : e.position.inMilliseconds / e.duration.inMilliseconds;
              }),
              initialData: 0.0,
              builder: (context, snapshot) {
                return DecoratedBox(
                  decoration: const BoxDecoration(
                    color: Color.fromRGBO(0xE3, 0xE2, 0xE2, 1.0),
                  ),
                  child: FractionallySizedBox(
                    widthFactor: snapshot.requireData,
                    alignment: Alignment.centerLeft,
                    child: const ColoredBox(
                      color: Color.fromRGBO(0x00, 0x85, 0xFF, 1.0),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
