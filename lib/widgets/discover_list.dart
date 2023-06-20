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
      height: 168 + widget.itemPadding.vertical,
      child: PageView.builder(
        controller: _pageController,
        clipBehavior: Clip.none,
        padEnds: true,
        itemCount: widget.profiles.length,
        itemBuilder: (context, index) {
          final profile = widget.profiles[index];
          return Padding(
            padding: widget.itemPadding,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _MiniProfile(
                  profile: profile,
                  playbackState: widget.playbackState,
                  onProfileChanged: widget.onProfileChanged,
                  onPlayPause: widget.onPlayPause,
                  onRecord: widget.onRecord,
                  onToggleFavorite: widget.onToggleFavorite,
                  onProfilePressed: widget.onProfilePressed,
                ),
                Positioned(
                  left: 33,
                  right: 33,
                  bottom: 0,
                  child: StreamBuilder<double>(
                    stream: widget.playbackInfoStream.map((e) =>
                        e.position.inMilliseconds / e.duration.inMilliseconds),
                    initialData: 0.0,
                    builder: (context, snapshot) {
                      return FractionallySizedBox(
                        widthFactor: snapshot.requireData,
                        alignment: Alignment.centerLeft,
                        child: Container(
                          height: 3,
                          decoration: const BoxDecoration(
                              color: Color.fromRGBO(0x3E, 0x97, 0xFF, 1.0),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(2))),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
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
  final ValueChanged<DiscoverProfile?> onProfileChanged;
  final VoidCallback onPlayPause;
  final VoidCallback onRecord;
  final VoidCallback onToggleFavorite;
  final VoidCallback onProfilePressed;

  const _MiniProfile({
    super.key,
    required this.profile,
    required this.playbackState,
    required this.onProfileChanged,
    required this.onPlayPause,
    required this.onRecord,
    required this.onToggleFavorite,
    required this.onProfilePressed,
  });

  @override
  Widget build(BuildContext context) {
    const lightColor = Color.fromRGBO(0x45, 0x45, 0x45, 1.0);
    return Button(
      onPressed: onProfilePressed,
      child: Container(
        width: 200,
        height: 200,
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 22 + 100 + 22,
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Container(
                      width: 100,
                      height: 100,
                      clipBehavior: Clip.hardEdge,
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: Image.network(
                        profile.profile.photo,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    top: 0,
                    child: Button(
                      onPressed: () => onProfileChanged(null),
                      child: Container(
                        width: 48,
                        height: 48,
                        padding: const EdgeInsets.all(12),
                        child: const DecoratedBox(
                          decoration: BoxDecoration(
                            color: Color.fromRGBO(0x3D, 0x3D, 0x3D, 1.0),
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
                    left: 4,
                    right: 4,
                    bottom: 22,
                    child: AutoSizeText(
                      profile.profile.name,
                      textAlign: TextAlign.center,
                      minFontSize: 16,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.profile.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.5,
                    ),
                  ),
                  const Text(
                    'Name',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: lightColor,
                    ),
                  ),
                  const Divider(color: Color.fromRGBO(0xEB, 0xEB, 0xEB, 1.0)),
                  const Text(
                    'Location',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.5,
                    ),
                  ),
                  const Text(
                    'Location',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: lightColor,
                    ),
                  ),
                  const Divider(color: Color.fromRGBO(0xEB, 0xEB, 0xEB, 1.0)),
                  const Text(
                    '1 Shared',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.5,
                    ),
                  ),
                  const Text(
                    'Connections',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: lightColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Button(
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
                      color: const Color.fromRGBO(0xFF, 0x4F, 0x4F, 1.0),
                    ),
                  ),
                ),
                Button(
                  onPressed: onRecord,
                  child: Container(
                    width: 48,
                    height: 48,
                    color: Colors.transparent,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.mic,
                      color: Color.fromRGBO(0xFF, 0x4F, 0x4F, 1.0),
                    ),
                  ),
                ),
                Button(
                  onPressed: onPlayPause,
                  child: Container(
                    width: 48,
                    height: 48,
                    color: Colors.transparent,
                    alignment: Alignment.center,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: Builder(
                        builder: (context) {
                          switch (playbackState) {
                            case PlaybackState.playing:
                              return const Icon(
                                Icons.pause,
                                color: Colors.black,
                              );
                            case PlaybackState.loading:
                              return const LoadingIndicator(
                                size: 16,
                                color: Colors.black,
                              );
                            default:
                              return const Icon(
                                Icons.play_arrow,
                                color: Colors.black,
                              );
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}
