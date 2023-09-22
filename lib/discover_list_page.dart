import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/discover_provider.dart';
import 'package:openup/location/location_provider.dart';
import 'package:openup/platform/just_audio_audio_player.dart';
import 'package:openup/shell_page.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/card_stack.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/discover_dialogs.dart';
import 'package:openup/widgets/gallery.dart';
import 'package:openup/widgets/photo_card.dart';
import 'package:openup/widgets/profile_display.dart';
import 'package:openup/widgets/record.dart';
import 'package:openup/widgets/scaffold.dart';

class DiscoverListPage extends ConsumerStatefulWidget {
  const DiscoverListPage({super.key});

  @override
  ConsumerState<DiscoverListPage> createState() => _DiscoverListPageState();
}

class _DiscoverListPageState extends ConsumerState<DiscoverListPage> {
  @override
  void initState() {
    super.initState();
    ref.listenManual<LocationMessage?>(locationMessageProvider,
        (previous, next) {
      if (next == null) {
        return;
      }
      switch (next) {
        case LocationMessage.permissionRationale:
          showLocationPermissionRationale(context);
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(discoverProvider);
    return Scaffold(
      appBar: const OpenupAppBar(
        body: OpenupAppBarBody(
          center: Text('Plus One'),
        ),
      ),
      body: _Background(
        child: state.map(
          init: (_) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Discover people near you',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),
                  PermissionButton(
                    icon: const Icon(Icons.public),
                    label: const Text('Enable Location'),
                    granted: false,
                    onPressed: () {
                      ref.read(discoverProvider.notifier).performQuery();
                    },
                  ),
                ],
              ),
            );
          },
          ready: (ready) {
            return SafeArea(
              child: _ListView(
                state: ready,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ListView extends ConsumerStatefulWidget {
  final DiscoverReadyState state;

  const _ListView({
    super.key,
    required this.state,
  });

  @override
  ConsumerState<_ListView> createState() => _ListViewState();
}

class _ListViewState extends ConsumerState<_ListView> {
  final _profileBuilderKey = GlobalKey<ProfileBuilderState>();

  bool _play = true;
  int _profileIndex = 0;

  @override
  Widget build(BuildContext context) {
    final profiles = widget.state.profiles;
    if (profiles.isEmpty) {
      return const Center(
        child: LoadingIndicator(),
      );
    }
    return ActivePage(
      onActivate: () {},
      onDeactivate: () => setState(() => _play = false),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return ProfileBuilder(
            key: _profileBuilderKey,
            profile: profiles[_profileIndex % profiles.length].profile,
            play: _play,
            builder: (context, playbackState, playbackInfoStream) {
              final currentProfile =
                  profiles[_profileIndex % profiles.length].profile;
              return CardStack(
                width: constraints.maxWidth,
                items: profiles,
                onChanged: (index) {
                  setState(() => _profileIndex = index);
                },
                itemBuilder: (context, item) {
                  final isCurrent = item.profile.uid == currentProfile.uid;
                  final profile = item;
                  return _ProfileDisplay(
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    profile: profile,
                    playbackState: isCurrent ? playbackState : null,
                    playbackInfoStream: isCurrent ? playbackInfoStream : null,
                    onPlay: () => setState(() => _play = true),
                    onPause: () => setState(() => _play = false),
                    onOptions: () {},
                    onMessage: () =>
                        _showRecordInvitePanel(context, profile.profile.uid),
                  );
                },
              );
            },
          );
        },
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
      submitLabel: const Text('Tab to send'),
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

class _ProfileDisplay extends ConsumerWidget {
  final double width;
  final double height;
  final PlaybackState? playbackState;
  final Stream<PlaybackInfo>? playbackInfoStream;
  final VoidCallback onPlay;
  final VoidCallback onPause;
  final VoidCallback onOptions;
  final VoidCallback onMessage;

  const _ProfileDisplay({
    super.key,
    required this.width,
    required this.height,
    required this.profile,
    required this.playbackState,
    required this.playbackInfoStream,
    required this.onPlay,
    required this.onPause,
    required this.onOptions,
    required this.onMessage,
  });

  final DiscoverProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myLatLong = ref.watch(locationProvider.select((s) => s.current));
    final distance = distanceMiles(profile.location.latLong, myLatLong).round();
    return PhotoCard(
      width: width,
      height: height,
      photo: Button(
        onPressed: _togglePlayPause,
        child: CameraFlashGallery(
          slideshow: true,
          gallery: profile.profile.gallery.map((e) => Uri.parse(e)).toList(),
        ),
      ),
      titleBuilder: (context) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(profile.profile.name.toUpperCase()),
            const SizedBox(width: 12),
            Text(
              profile.profile.age.toString(),
              style: const TextStyle(fontSize: 27),
            ),
          ],
        );
      },
      subtitle: Text('$distance ${distance == 1 ? 'mile' : 'miles'} away'),
      firstButton: Button(
        onPressed: onMessage,
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
      secondButton: Button(
        onPressed: onOptions,
        child: const Center(
          child: Text(
            'Options',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.black,
            ),
          ),
        ),
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
              return switch (playbackState) {
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
    switch (playbackState) {
      case PlaybackState.idle:
      case PlaybackState.paused:
        onPlay();
      case null:
        return;
      default:
        onPause();
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
                    imageFilter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: DefaultTextStyle(
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 60,
                        fontWeight: FontWeight.w400,
                        color: Color.fromRGBO(0xFF, 0xFF, 0xFF, 0.5),
                      ),
                      child: Column(
                        children: [
                          SizedBox(height: MediaQuery.of(context).padding.top),
                          SizedBox(height: constraints.maxHeight * 0.15),
                          const Text('EVERYONE'),
                          const Spacer(),
                          const Text('ICEBREAKER'),
                          const Spacer(),
                          const Text('ICEBREAKER'),
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
