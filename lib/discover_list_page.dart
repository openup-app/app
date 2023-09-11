import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/discover_provider.dart';
import 'package:openup/location/location_provider.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/card_stack.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/discover_dialogs.dart';
import 'package:openup/widgets/gallery.dart';
import 'package:openup/widgets/profile_display.dart';
import 'package:openup/widgets/record.dart';

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
    return _Background(
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
          return _ListView(
            state: ready,
          );
        },
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
    return LayoutBuilder(
      builder: (context, constraints) {
        return Center(
          child: ProfileBuilder(
            profile: profiles[_profileIndex % profiles.length].profile,
            play: false,
            builder: (context, playbackState, playbackInfoStream) {
              return CardStack(
                width: constraints.maxWidth,
                items: profiles,
                onChanged: (index) {
                  setState(() => _profileIndex = index);
                },
                itemBuilder: (context, item) {
                  final profile = item;
                  return _ProfileCard(
                    profile: profile,
                    onOptions: () {},
                    onMessage: () =>
                        _showRecordInvitePanel(context, profile.profile.uid),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  void _showRecordInvitePanel(BuildContext context, String uid) async {
    // _tempPauseAudio();
    final userState = ref.read(userProvider2);
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
      submitLabel: const Text('Finish & Send'),
    );

    if (!mounted) {
      return;
    }
    if (result == null) {
      return;
    }

    final notifier = ref.read(userProvider2.notifier);
    await withBlockingModal(
      context: context,
      label: 'Sending invite...',
      future: notifier.sendMessage(uid: uid, audio: result.audio),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final VoidCallback onOptions;
  final VoidCallback onMessage;

  const _ProfileCard({
    super.key,
    required this.profile,
    required this.onOptions,
    required this.onMessage,
  });

  final DiscoverProfile profile;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: AspectRatio(
        aspectRatio: 6 / 10,
        child: Container(
          width: 340,
          height: 567,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(18),
                child: AspectRatio(
                  aspectRatio: 14 / 19,
                  child: CameraFlashGallery(
                    slideshow: true,
                    gallery: profile.profile.gallery,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            profile.profile.name.toUpperCase(),
                            style: const TextStyle(
                              fontFamily: 'Covered By Your Grace',
                              fontSize: 29,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            profile.profile.age.toString(),
                            style: const TextStyle(
                              fontFamily: 'Covered By Your Grace',
                              fontSize: 27,
                            ),
                          ),
                        ],
                      ),
                      const Text(
                        '4 miles away',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.music_note,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(
                height: 1,
                color: Color.fromRGBO(0xD2, 0xD2, 0xD2, 1.0),
              ),
              SizedBox(
                height: 50,
                child: Row(
                  children: [
                    Expanded(
                      child: Button(
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
                    ),
                    const VerticalDivider(
                      width: 1,
                      color: Color.fromRGBO(0xD2, 0xD2, 0xD2, 1.0),
                    ),
                    Expanded(
                      child: Button(
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
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
