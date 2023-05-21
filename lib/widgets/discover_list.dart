import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openup/api/api.dart';
import 'package:openup/widgets/button.dart';

class DiscoverList extends ConsumerStatefulWidget {
  final List<DiscoverProfile> profiles;
  final int profileIndex;
  final void Function(int index) onProfileChanged;
  final bool play;
  final VoidCallback onPlayPause;
  final VoidCallback onRecord;
  final VoidCallback onProfilePressed;

  const DiscoverList({
    super.key,
    required this.profiles,
    required this.profileIndex,
    required this.onProfileChanged(int index),
    required this.play,
    required this.onPlayPause,
    required this.onRecord,
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

    _pageController = PageController(
      initialPage: widget.profileIndex,
      viewportFraction: 0.9,
    );
    _pageController.addListener(() {
      final page = _pageController.page ?? 0;
      _pageListener.value = page;
      final index = _pageController.page?.round() ?? widget.profileIndex;

      if (index != widget.profileIndex && _reportPageChange) {
        widget.onProfileChanged(index);
      }
    });
  }

  @override
  void didUpdateWidget(covariant DiscoverList oldWidget) {
    super.didUpdateWidget(oldWidget);
    final index = _pageController.page?.round() ?? widget.profileIndex;
    if (widget.profileIndex != index) {
      setState(() => _reportPageChange = false);
      _pageController
          .animateToPage(
        widget.profileIndex.toInt(),
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
            margin: EdgeInsets.only(
              bottom: 16 + MediaQuery.of(context).padding.bottom,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: _MiniProfile(
              profile: profile,
              play: widget.play,
              onPlayPause: widget.onPlayPause,
              onRecord: widget.onRecord,
              onProfilePressed: widget.onProfilePressed,
            ),
          );
        },
      ),
    );
  }
}

class _MiniProfile extends StatelessWidget {
  final DiscoverProfile profile;
  final bool play;
  final VoidCallback onPlayPause;
  final VoidCallback onRecord;
  final VoidCallback onProfilePressed;

  const _MiniProfile({
    super.key,
    required this.profile,
    required this.play,
    required this.onPlayPause,
    required this.onRecord,
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
          color: Colors.white,
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
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(
                    Icons.favorite_outline,
                    color: Color.fromRGBO(0xFF, 0x4F, 0x4F, 1.0),
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
                      color: Colors.black,
                    ),
                    child: Icon(
                      play ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
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
