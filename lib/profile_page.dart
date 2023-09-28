import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/platform/just_audio_audio_player.dart';
import 'package:openup/shell_page.dart';
import 'package:openup/util/photo_picker.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/card_stack.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/photo_card.dart';
import 'package:openup/widgets/profile_display.dart';
import 'package:openup/widgets/record.dart';
import 'package:openup/widgets/scaffold.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _scrollController = ScrollController();
  final _profileBuilderKey = GlobalKey<ProfileBuilderState>();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: const OpenupAppBar(
        body: OpenupAppBarBody(
          center: Text('Profile'),
        ),
        toolbar: _TopTabs(),
      ),
      body: ref.watch(userProvider).map(
        guest: (_) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Log in to create a profile'),
                ElevatedButton(
                  onPressed: () => context.pushNamed('signup'),
                  child: const Text('Log in'),
                ),
              ],
            ),
          );
        },
        signedIn: (signedIn) {
          final profile = signedIn.account.profile;
          return ActivePage(
            onActivate: () {},
            onDeactivate: () {
              _profileBuilderKey.currentState?.pause();
            },
            child: SafeArea(
              child: Center(
                child: _ProfileStack(
                  profile: profile,
                  profileBuilderKey: _profileBuilderKey,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TopTabs extends StatelessWidget {
  const _TopTabs({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: DefaultTextStyle.merge(
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        child: Row(
          children: [
            Expanded(
              child: Button(
                onPressed: () => context.pushNamed('my_meetups'),
                child: const Center(
                  child: Text('My Meetups'),
                ),
              ),
            ),
            const VerticalDivider(
              width: 1,
              color: Color.fromRGBO(0x33, 0x330, 0x33, 1.0),
            ),
            Expanded(
              child: Button(
                onPressed: () => context.pushNamed('calendar'),
                child: const Center(
                  child: Text('Calendar'),
                ),
              ),
            ),
            const VerticalDivider(
              width: 1,
              color: Color.fromRGBO(0x33, 0x330, 0x33, 1.0),
            ),
            Expanded(
              child: Button(
                onPressed: () => context.pushNamed('settings'),
                child: const Center(
                  child: Text('Settings'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileStack extends ConsumerStatefulWidget {
  final Profile profile;
  final GlobalKey<ProfileBuilderState> profileBuilderKey;

  const _ProfileStack({
    super.key,
    required this.profile,
    required this.profileBuilderKey,
  });

  @override
  ConsumerState<_ProfileStack> createState() => _ProfilePanelState();
}

class _ProfilePanelState extends ConsumerState<_ProfileStack> {
  Timer? _animationTimer;

  @override
  void dispose() {
    _animationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ProfileBuilder(
          key: widget.profileBuilderKey,
          profile: widget.profile,
          play: false,
          builder: (context, playbackState, playbackInfoStream) {
            return CardStack(
              width: constraints.maxWidth,
              items: widget.profile.gallery,
              onChanged: (_) {},
              itemBuilder: (context, item) {
                final photoIndex = widget.profile.gallery.indexOf(item);
                final photoName = '#${photoIndex + 1}';
                return PhotoCard(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  photo: Image.network(
                    item,
                    fit: BoxFit.cover,
                  ),
                  titleBuilder: (context) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(widget.profile.name.toUpperCase()),
                        const SizedBox(width: 12),
                        Text(
                          widget.profile.age.toString(),
                          style: const TextStyle(fontSize: 27),
                        ),
                      ],
                    );
                  },
                  subtitle: Text('Photo $photoName'),
                  firstButton: Button(
                    onPressed: () => _showRecordPanel(context),
                    child: const Center(
                      child: Text('Update Profile Bio'),
                    ),
                  ),
                  secondButton: Button(
                    onPressed: () => _updatePhoto(photoIndex),
                    child: Center(
                      child: Text('Update Photo $photoName'),
                    ),
                  ),
                  indicatorButton: Button(
                    onPressed: () => _onPlayPause(playbackState),
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
              },
            );
          },
        );
      },
    );
  }

  void _onPlayPause(PlaybackState playbackState) {
    switch (playbackState) {
      case PlaybackState.idle:
      case PlaybackState.paused:
        widget.profileBuilderKey.currentState?.play();
        break;
      default:
        widget.profileBuilderKey.currentState?.pause();
    }
  }

  void _updatePhoto(int index) async {
    final photo = await selectPhoto(
      context,
      label: 'This photo will be used in your profile',
    );
    if (photo != null && mounted) {
      final notifier = ref.read(userProvider.notifier);
      final uploadFuture = notifier.updateGalleryPhoto(
        index: index,
        photo: photo,
      );
      await withBlockingModal(
        context: context,
        label: 'Updating photo',
        future: uploadFuture,
      );
    }
  }

  Future<void> _showRecordPanel(BuildContext context) async {
    widget.profileBuilderKey.currentState?.pause();
    final result = await showRecordPanel(
      context: context,
      title: const Text('Recording Voice Bio'),
      submitLabel: const Text('Tap to update'),
    );
    if (result == null) {
      return;
    }
    if (!mounted) {
      return;
    }

    final notifier = ref.read(userProvider.notifier);
    return withBlockingModal(
      context: context,
      label: 'Updating voice bio...',
      future: notifier.updateAudioBio(result.audio),
    );
  }
}
