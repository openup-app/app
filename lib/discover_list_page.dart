import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/people_provider.dart';
import 'package:openup/platform/just_audio_audio_player.dart';
import 'package:openup/shell_page.dart';
import 'package:openup/util/location.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/card_stack.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/gallery.dart';
import 'package:openup/widgets/photo_card.dart';
import 'package:openup/widgets/profile_display.dart';
import 'package:openup/widgets/record.dart';

class DiscoverListPage extends ConsumerStatefulWidget {
  const DiscoverListPage({super.key});

  @override
  ConsumerState<DiscoverListPage> createState() => _DiscoverListPageState();
}

class _DiscoverListPageState extends ConsumerState<DiscoverListPage> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(peopleProvider);
    return Scaffold(
      body: _Background(
        child: SafeArea(
          child: Builder(
            builder: (context) {
              if (state is PeopleFailed) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Something went wrong finding people nearby'),
                      const SizedBox(height: 16),
                      RoundedButton(
                        onPressed: () => ref.refresh(peopleProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              final readyState = state.map(
                uninitialized: (_) => null,
                initializing: (_) => null,
                failed: (_) => null,
                ready: (ready) => ready,
              );
              return _ListView(
                profiles: readyState?.profiles,
                latLong: readyState?.latLong,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ListView extends ConsumerStatefulWidget {
  final List<DiscoverProfile>? profiles;
  final LatLong? latLong;

  const _ListView({
    super.key,
    required this.profiles,
    required this.latLong,
  });

  @override
  ConsumerState<_ListView> createState() => _ListViewState();
}

class _ListViewState extends ConsumerState<_ListView> {
  final _cardStackKey = GlobalKey<CardStackState<DiscoverProfile?>>();
  final _profileBuilderKey = GlobalKey<ProfileBuilderState>();

  bool _active = false;
  bool _play = true;
  int _profileIndex = 0;

  @override
  Widget build(BuildContext context) {
    return ActivePage(
      onActivate: () => setState(() => _active = true),
      onDeactivate: () {
        setState(() {
          _active = false;
          _play = false;
        });
      },
      child: Shimmer(
        linearGradient: kShimmerGradient,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final profiles = widget.profiles;
            final latLong = widget.latLong;
            if (profiles == null || latLong == null) {
              return CardStack<DiscoverProfile?>(
                key: _cardStackKey,
                width: constraints.maxWidth,
                items: List.generate(3, (index) => null),
                onChanged: (_) {},
                itemBuilder: (context, _) {
                  return PhotoCardLoading(
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    useExtraTopPadding: true,
                  );
                },
              );
            }
            if (profiles.isEmpty) {
              return const Center(
                child: Text('No profiles nearby'),
              );
            }
            return ProfileBuilder(
              key: _profileBuilderKey,
              profile: profiles[_profileIndex % profiles.length].profile,
              play: _play,
              builder: (context, playbackState, playbackInfoStream) {
                final currentProfile =
                    profiles[_profileIndex % profiles.length].profile;
                return CardStack<DiscoverProfile?>(
                  key: _cardStackKey,
                  width: constraints.maxWidth,
                  items: profiles,
                  onChanged: (index) {
                    setState(() => _profileIndex = index);
                  },
                  itemBuilder: (context, item) {
                    final profile = item;
                    if (profile == null) {
                      return const SizedBox.shrink();
                    }
                    final isCurrent = profile.profile.uid == currentProfile.uid;
                    return _ProfileDisplay(
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                      profile: profile,
                      distance: distanceMiles(profile.location.latLong, latLong)
                          .round(),
                      playbackState: isCurrent ? playbackState : null,
                      playbackInfoStream: isCurrent ? playbackInfoStream : null,
                      onPlay: () {
                        if (_active) {
                          setState(() => _play = true);
                        }
                      },
                      onPause: () => setState(() => _play = false),
                      onMessage: () =>
                          _showRecordInvitePanel(context, profile.profile.uid),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _showRecordInvitePanel(BuildContext context, String uid) async {
    _pauseAudio();
    final userState = ref.read(userProvider);
    final signedIn = userState.map(
      guest: (_) => null,
      signedIn: (signedIn) => signedIn,
    );
    if (signedIn == null) {
      return;
    }

    final result = await showRecordPanel(
      context: context,
      title: const Text('Recording Message'),
      submitLabel: const Text('Tap to send'),
    );

    if (!mounted) {
      return;
    }
    if (result == null) {
      return;
    }

    final notifier = ref.read(userProvider.notifier);
    await withBlockingModal(
      context: context,
      label: 'Sending invite...',
      future: notifier.sendMessage(uid: uid, audio: result.audio),
    );
  }

  void _pauseAudio() => setState(() => _play = false);
}

class _ProfileDisplay extends ConsumerStatefulWidget {
  final double width;
  final double height;
  final DiscoverProfile profile;
  final int distance;
  final PlaybackState? playbackState;
  final Stream<PlaybackInfo>? playbackInfoStream;
  final VoidCallback onPlay;
  final VoidCallback onPause;
  final VoidCallback onMessage;

  const _ProfileDisplay({
    super.key,
    required this.width,
    required this.height,
    required this.profile,
    required this.distance,
    required this.playbackState,
    required this.playbackInfoStream,
    required this.onPlay,
    required this.onPause,
    required this.onMessage,
  });

  @override
  ConsumerState<_ProfileDisplay> createState() => _ProfileDisplayState();
}

class _ProfileDisplayState extends ConsumerState<_ProfileDisplay> {
  bool _loading = true;
  bool _initialDidChangeDeps = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialDidChangeDeps) {
      _precache();
      _initialDidChangeDeps = false;
    }
  }

  void _precache() async {
    await Future.wait([
      for (final uri in widget.profile.profile.gallery)
        precacheImage(NetworkImage(uri.toString()), context)
    ]);
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return PhotoCardLoading(
        width: widget.width,
        height: widget.height,
      );
    }

    return PhotoCard(
      width: widget.width,
      height: widget.height,
      useExtraTopPadding: true,
      photo: Button(
        onPressed: _togglePlayPause,
        child: CameraFlashGallery(
          slideshow: true,
          gallery:
              widget.profile.profile.gallery.map((e) => Uri.parse(e)).toList(),
        ),
      ),
      titleBuilder: (context) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.profile.profile.name.toUpperCase()),
            const SizedBox(width: 12),
            Text(
              widget.profile.profile.age.toString(),
              style: const TextStyle(fontSize: 27),
            ),
          ],
        );
      },
      subtitle: Text(
          '${widget.distance} ${widget.distance == 1 ? 'mile' : 'miles'} away'),
      firstButton: Button(
        onPressed: widget.onMessage,
        child: const Center(
          child: Text(
            'Message',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.black,
            ),
          ),
        ),
      ),
      secondButton: ReportBlockPopupMenu2(
        name: widget.profile.profile.name,
        uid: widget.profile.profile.uid,
        onBlock: () {},
        builder: (context) {
          return const Center(
            child: Text(
              'Options',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.black,
              ),
            ),
          );
        },
      ),
      indicatorButton: Button(
        onPressed: _togglePlayPause,
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          margin: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Colors.black,
            shape: BoxShape.circle,
          ),
          child: Builder(
            builder: (context) {
              return switch (widget.playbackState) {
                null => const SizedBox.shrink(),
                PlaybackState.idle ||
                PlaybackState.paused =>
                  const Icon(Icons.play_arrow),
                PlaybackState.playing => SvgPicture.asset(
                    'assets/images/audio_indicator.svg',
                    width: 16,
                    height: 18,
                  ),
                _ => const LoadingIndicator(),
              };
            },
          ),
        ),
      ),
    );
  }

  void _togglePlayPause() {
    switch (widget.playbackState) {
      case PlaybackState.idle:
      case PlaybackState.paused:
        widget.onPlay();
      case null:
        return;
      default:
        widget.onPause();
    }
  }
}

class _Background extends StatelessWidget {
  final Widget child;

  const _Background({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ColoredBox(
          color: Colors.black,
          child: Stack(
            fit: StackFit.expand,
            alignment: Alignment.center,
            children: [
              RepaintBoundary(
                child: OverflowBox(
                  minWidth: constraints.maxWidth * 1.3,
                  minHeight: constraints.maxHeight * 1.3,
                  maxWidth: constraints.maxWidth * 1.3,
                  maxHeight: constraints.maxHeight * 1.3,
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(
                      sigmaX: 12,
                      sigmaY: 12,
                      tileMode: TileMode.decal,
                    ),
                    child: DefaultTextStyle.merge(
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.visible,
                      maxLines: 1,
                      softWrap: false,
                      style: const TextStyle(
                        fontSize: 90,
                        fontWeight: FontWeight.w400,
                        color: Color.fromRGBO(0xFF, 0xFF, 0xFF, 0.5),
                      ),
                      child: Column(
                        children: [
                          SizedBox(height: MediaQuery.of(context).padding.top),
                          SizedBox(height: constraints.maxHeight * 0.15),
                          const Text('EVERYONE'),
                          const Spacer(),
                          const Text('NEEDS AN'),
                          const Spacer(),
                          const Text('ICE BREAKER'),
                          SizedBox(height: constraints.maxHeight * 0.15),
                          SizedBox(
                              height: MediaQuery.of(context).padding.bottom),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              child,
            ],
          ),
        );
      },
    );
  }
}
