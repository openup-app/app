import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openup/api/api.dart';
import 'package:openup/widgets/profile_display.dart';

class DiscoverList extends ConsumerStatefulWidget {
  final List<DiscoverProfile> profiles;
  final int profileIndex;
  final void Function(int index) onProfileChanged;
  final bool play;
  final VoidCallback onPlayPause;
  final VoidCallback showRecordPanel;
  final VoidCallback onBlock;

  const DiscoverList({
    super.key,
    required this.profiles,
    required this.profileIndex,
    required this.onProfileChanged(int index),
    required this.play,
    required this.onPlayPause,
    required this.showRecordPanel,
    required this.onBlock,
  });

  @override
  ConsumerState<DiscoverList> createState() => _DisoverListState();
}

class _DisoverListState extends ConsumerState<DiscoverList> {
  final _pageListener = ValueNotifier<double>(0);
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();

    _pageController = PageController(initialPage: widget.profileIndex);
    _pageController.addListener(() {
      final page = _pageController.page ?? 0;
      _pageListener.value = page;
      final index = _pageController.page?.round() ?? widget.profileIndex;

      if (index != widget.profileIndex) {
        widget.onProfileChanged(index);
      }
    });
  }

  @override
  void didUpdateWidget(covariant DiscoverList oldWidget) {
    super.didUpdateWidget(oldWidget);
    final index = _pageController.page?.round() ?? widget.profileIndex;
    if (widget.profileIndex != index) {
      _pageController.jumpTo(widget.profileIndex.toDouble());
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
      itemCount: widget.profiles.length,
      itemBuilder: (context, index) {
        final profile = widget.profiles[index].profile;
        return ClipRRect(
          clipBehavior: Clip.hardEdge,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
          child: Container(
            margin: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 24 + MediaQuery.of(context).padding.top,
              bottom: 16 + MediaQuery.of(context).padding.bottom,
            ),
            clipBehavior: Clip.hardEdge,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(48)),
            ),
            child: ProfileDisplay(
              profile: profile,
              play: widget.play,
              onPlayPause: widget.onPlayPause,
              onRecord: widget.showRecordPanel,
              onBlock: widget.onBlock,
            ),
          ),
        );
      },
    );
  }
}
