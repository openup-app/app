import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/audio/audio.dart';
import 'package:openup/location/location_provider.dart';
import 'package:openup/people_provider.dart';
import 'package:openup/shell_page.dart';
import 'package:openup/util/location.dart';
import 'package:openup/widgets/background.dart';
import 'package:openup/widgets/card_stack.dart';
import 'package:openup/widgets/common.dart';
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

    // Tries to show the location request if it's not already granted
    ref.read(locationProvider.notifier).retry().then((_) {
      // TODO: userProvider should watch locationProvider, handling this itself
      //   once it's a NotifierProvider rather than a StateNotifierProvider
      if (mounted) {
        ref
            .read(userProvider.notifier)
            .updateLocation(ref.read(locationProvider).current);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(peopleProvider);
    return Scaffold(
      appBar: OpenupAppBar(
        blurBackground: false,
        body: OpenupAppBarBody(
          center: Column(
            children: [
              Builder(
                builder: (context) {
                  return Text(
                    'Plus One',
                    style: DefaultTextStyle.of(context)
                        .style
                        .copyWith(fontSize: 27),
                  );
                },
              ),
              const Text(
                'Find a plus one',
                style: TextStyle(
                  fontSize: 17,
                  color: Color.fromRGBO(0xCC, 0xCC, 0xCC, 1.0),
                ),
              ),
            ],
          ),
        ),
      ),
      body: TextBackground(
        child: SafeArea(
          child: state.map(
            uninitialized: (_) {
              return const _ListView(
                profiles: null,
                latLong: null,
              );
            },
            initializing: (_) {
              return const _ListView(
                profiles: null,
                latLong: null,
              );
            },
            failed: (_) {
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
            },
            ready: (ready) {
              return _ListView(
                profiles: ready.profiles,
                latLong: ready.latLong,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ListView extends ConsumerStatefulWidget {
  final List<Profile>? profiles;
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
  final _cardStackKey = GlobalKey<CardStackState<Profile?>>();
  late final AudioController _controller;

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
              return CardStack<Profile?>(
                key: _cardStackKey,
                width: constraints.maxWidth,
                items: List.generate(3, (index) => null),
                onChanged: (_) {},
                itemBuilder: (context, _, key) {
                  return PhotoCardWiggle(
                    childKey: key,
                    child: PhotoCardLoading(
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                      useExtraTopPadding: true,
                    ),
                  );
                },
              );
            }
            if (profiles.isEmpty) {
              return const Center(
                child: Text('No profiles nearby'),
              );
            }

            final profile = profiles[_profileIndex];
            return ProfileBuilder(
              profile: profile,
              onController: (controller) =>
                  setState(() => _controller = controller),
              builder: (context, video, controller) {
                final currentProfile = profiles[_profileIndex];
                return CardStack<Profile>(
                  key: _cardStackKey,
                  width: constraints.maxWidth,
                  items: profiles,
                  onChanged: (index) {
                    setState(() => _profileIndex = index);
                  },
                  itemBuilder: (context, item, key) {
                    final profile = item;
                    final isCurrent = profile.uid == currentProfile.uid;
                    return PhotoCardWiggle(
                      childKey: key,
                      child: PhotoCardProfile(
                        key: ValueKey(profile.uid),
                        width: constraints.maxWidth,
                        height: constraints.maxHeight,
                        profile: profile,
                        distance:
                            distanceMiles(profile.location.latLong, latLong)
                                .round(),
                        playbackStream:
                            isCurrent ? controller.playbackStream : null,
                        onPlay: controller.play,
                        onPause: controller.pause,
                        onMessage: () =>
                            _showRecordInvitePanel(context, profile.uid),
                      ),
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
    notifier.refreshChatrooms();
  }

  void _pauseAudio() => _controller.pause();
}
