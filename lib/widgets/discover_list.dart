import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openup/api/api.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/profile_display.dart';

class DiscoverList extends ConsumerStatefulWidget {
  final List<DiscoverProfile> profiles;
  final DiscoverProfile? selectedProfile;
  final ValueChanged<DiscoverProfile?> onProfileChanged;
  final bool play;
  final VoidCallback onPlayPause;
  final VoidCallback onRecord;
  final VoidCallback onToggleFavorite;
  final VoidCallback onProfilePressed;

  const DiscoverList({
    super.key,
    required this.profiles,
    required this.selectedProfile,
    required this.onProfileChanged,
    required this.play,
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
    _pageController = PageController(
      initialPage: initialIndex,
      viewportFraction: 0.9,
    );

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
    return Container(
      height: 168,
      margin:
          EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 16),
      child: PageView.builder(
        controller: _pageController,
        padEnds: true,
        itemCount: widget.profiles.length,
        itemBuilder: (context, index) {
          final profile = widget.profiles[index];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: _MiniProfile(
              profile: profile,
              play: widget.play,
              onPlayPause: widget.onPlayPause,
              onRecord: widget.onRecord,
              onToggleFavorite: widget.onToggleFavorite,
              onProfilePressed: widget.onProfilePressed,
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
          padding: const EdgeInsets.all(20.0),
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
  final bool play;
  final VoidCallback onPlayPause;
  final VoidCallback onRecord;
  final VoidCallback onToggleFavorite;
  final VoidCallback onProfilePressed;

  const _MiniProfile({
    super.key,
    required this.profile,
    required this.play,
    required this.onPlayPause,
    required this.onRecord,
    required this.onToggleFavorite,
    required this.onProfilePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Button(
      onPressed: onProfilePressed,
      child: Container(
        height: 168,
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(34)),
          color: Color.fromRGBO(0x29, 0x2C, 0x2E, 1.0),
          boxShadow: [
            BoxShadow(
              offset: Offset(0, 4),
              blurRadius: 8,
              color: Color.fromRGBO(0x00, 0x00, 0x00, 0.25),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(width: 16),
            Container(
              width: 124,
              height: 124,
              clipBehavior: Clip.hardEdge,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: Image.network(
                profile.profile.photo,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16),
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
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Button(
                  onPressed: onToggleFavorite,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
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
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(
                      Icons.mic,
                      color: Color.fromRGBO(0xFF, 0x4F, 0x4F, 1.0),
                    ),
                  ),
                ),
                Button(
                  onPressed: onPlayPause,
                  child: Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: Icon(
                      play ? Icons.pause : Icons.play_arrow,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 24),
          ],
        ),
      ),
    );
  }
}
