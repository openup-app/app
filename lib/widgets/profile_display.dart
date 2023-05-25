import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/platform/just_audio_audio_player.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/gallery.dart';
import 'package:openup/widgets/icon_with_shadow.dart';

class ProfileBuilder extends StatefulWidget {
  final Profile? profile;
  final bool play;
  final Widget Function(
    BuildContext context,
    bool play,
    Stream<PlaybackInfo> playbackInfo,
  ) builder;

  const ProfileBuilder({
    super.key,
    required this.profile,
    required this.play,
    required this.builder,
  });

  @override
  State<ProfileBuilder> createState() => ProfileBuilderState();
}

class ProfileBuilderState extends State<ProfileBuilder> {
  final _player = JustAudioAudioPlayer();
  bool _audioPaused = false;

  @override
  void initState() {
    super.initState();
    final audio = widget.profile?.audio;
    if (audio != null) {
      _player.setUrl(audio);
    }

    if (widget.play) {
      _player.play(loop: true);
    }
    _player.playbackInfoStream.listen((playbackInfo) {
      final isPaused = playbackInfo.state == PlaybackState.idle;
      if (!_audioPaused && isPaused) {
        setState(() => _audioPaused = true);
      } else if (_audioPaused && !isPaused) {
        setState(() => _audioPaused = false);
      }
    });
  }

  @override
  void didUpdateWidget(covariant ProfileBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.profile?.audio == null) {
      _player.stop();
    }

    if (oldWidget.profile?.audio != widget.profile?.audio) {
      final audio = widget.profile?.audio;
      if (audio != null) {
        _player.setUrl(audio);
      }
    }

    if (widget.play && !oldWidget.play) {
      _player.play(loop: true);
    } else if (!widget.play && oldWidget.play) {
      _player.stop();
    }
  }

  @override
  void dispose() {
    _player.stop();
    _player.dispose();
    super.dispose();
  }

  void play() => _player.play(loop: true);

  void pause() => _player.pause();

  @override
  Widget build(BuildContext context) {
    return widget.builder(
      context,
      widget.play && !_audioPaused,
      _player.playbackInfoStream,
    );
  }
}

class ProfileDisplay extends ConsumerWidget {
  final Profile profile;
  final bool play;
  final VoidCallback onPlayPause;
  final VoidCallback onRecord;
  final VoidCallback onBlock;

  const ProfileDisplay({
    super.key,
    required this.profile,
    required this.play,
    required this.onPlayPause,
    required this.onRecord,
    required this.onBlock,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(48)),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Button(
            onPressed: onPlayPause,
            child: KeyedSubtree(
              key: ValueKey(profile.uid),
              child: CinematicGallery(
                slideshow: play,
                gallery: profile.collection.photos,
              ),
            ),
          ),
          if (!play)
            const Center(
              child: IgnorePointer(
                child: IconWithShadow(
                  Icons.play_arrow,
                  size: 80,
                ),
              ),
            ),
          Positioned(
            right: 22,
            top: 28,
            child: ReportBlockPopupMenu2(
              uid: profile.uid,
              name: profile.name,
              onBlock: onBlock,
              builder: (context) {
                return const _ProfileButtonContents(
                  icon: Icon(
                    CupertinoIcons.ellipsis,
                    color: Colors.black,
                    size: 20,
                  ),
                  size: 29,
                );
              },
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 120,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.5),
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 51,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              margin: const EdgeInsets.only(bottom: 38),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Button(
                      useFadeWheNoPressedCallback: false,
                      onPressed: () {
                        showCupertinoModalPopup(
                          context: context,
                          builder: (context) {
                            return _MutualFriendsModal(
                              uids: [profile.uid],
                            );
                          },
                        );
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AutoSizeText(
                            profile.name,
                            minFontSize: 15,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white),
                          ),
                          Row(
                            children: [
                              const InfoIcon(),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text('1 mutual friends',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium!
                                        .copyWith(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w400,
                                            color: Colors.white)),
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 146,
                    child: _RecordButton(
                      onPressed: () {
                        ref.read(userProvider2).map(
                          guest: (_) {
                            showCupertinoDialog(
                              context: context,
                              builder: (context) {
                                return CupertinoAlertDialog(
                                  title: const Text('Log in to send invites'),
                                  actions: [
                                    CupertinoDialogAction(
                                      onPressed: Navigator.of(context).pop,
                                      child: const Text('Cancel'),
                                    ),
                                    CupertinoDialogAction(
                                      onPressed: () =>
                                          context.pushNamed('signup'),
                                      child: const Text('Log in'),
                                    )
                                  ],
                                );
                              },
                            );
                          },
                          signedIn: (_) {
                            onRecord();
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Info icon with solid white background
class InfoIcon extends StatelessWidget {
  const InfoIcon({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: const [
        SizedBox(
          width: 10,
          height: 10,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
        Icon(
          Icons.info,
          color: Color.fromRGBO(0xFF, 0x38, 0x38, 1.0),
          size: 16,
        ),
      ],
    );
  }
}

class ProfileButton extends StatelessWidget {
  final Widget icon;
  final Widget? label;
  final double size;
  final VoidCallback onPressed;

  const ProfileButton({
    super.key,
    required this.icon,
    this.label,
    this.size = 35,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Button(
      onPressed: onPressed,
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: _ProfileButtonContents(
          icon: icon,
          label: label,
          size: size,
        ),
      ),
    );
  }
}

class _ProfileButtonContents extends StatelessWidget {
  final Widget icon;
  final Widget? label;
  final double size;

  const _ProfileButtonContents({
    super.key,
    required this.icon,
    this.label,
    this.size = 35,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: label == null ? size : null,
      height: size,
      alignment: Alignment.center,
      padding: label == null
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            offset: Offset(0, 2),
            blurRadius: 4,
            color: Color.fromRGBO(0x00, 0x00, 0x00, 0.25),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          if (label != null) ...[
            const SizedBox(width: 8),
            DefaultTextStyle(
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              child: label!,
            ),
          ],
        ],
      ),
    );
  }
}

class _RecordButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const _RecordButton({
    super.key,
    this.label = 'send message',
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Button(
      onPressed: onPressed,
      child: Container(
        width: 146,
        height: 51,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromRGBO(0xF3, 0x49, 0x50, 1.0),
              Color.fromRGBO(0xDF, 0x39, 0x3F, 1.0),
            ],
          ),
          borderRadius: BorderRadius.all(Radius.circular(25)),
          boxShadow: [
            BoxShadow(
              offset: Offset(0, 4),
              blurRadius: 4,
              color: Color.fromRGBO(0x00, 0x00, 0x00, 0.25),
            ),
          ],
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              fontSize: 14, fontWeight: FontWeight.w400, color: Colors.white),
        ),
      ),
    );
  }
}

class _MutualFriendsModal extends ConsumerStatefulWidget {
  final List<String> uids;

  const _MutualFriendsModal({
    super.key,
    required this.uids,
  });

  @override
  ConsumerState<_MutualFriendsModal> createState() =>
      _MutualFriendsModalState();
}

class _MutualFriendsModalState extends ConsumerState<_MutualFriendsModal> {
  bool _loading = true;

  final _profiles = <Profile>[];

  @override
  void initState() {
    super.initState();
    final api = ref.read(apiProvider);
    Future.wait(widget.uids.map(api.getProfile)).then((results) {
      if (mounted) {
        final profiles = results.map((result) {
          return result.fold(
            (l) => null,
            (r) => r,
          );
        });

        final nonNullProfiles =
            List<Profile>.from(profiles.where((e) => e != null));

        setState(() {
          _loading = false;
          _profiles.addAll(nonNullProfiles);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoActionSheet(
      cancelButton: CupertinoActionSheetAction(
        onPressed: Navigator.of(context).pop,
        isDefaultAction: true,
        child: const Text('Cancel'),
      ),
      title: Text(
        'Mutual friends',
        style: Theme.of(context)
            .textTheme
            .bodyMedium!
            .copyWith(fontSize: 16, fontWeight: FontWeight.w300),
      ),
      actions: [
        if (_loading)
          CupertinoActionSheetAction(
            onPressed: () {},
            child: const LoadingIndicator(size: 35),
          ),
        for (final profile in _profiles)
          CupertinoActionSheetAction(
            onPressed: () {},
            child: Row(
              children: [
                const SizedBox(width: 21),
                Container(
                  width: 35,
                  height: 35,
                  clipBehavior: Clip.hardEdge,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  child: Image.network(
                    profile.collection.photos.first.url,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    profile.name,
                    textAlign: TextAlign.left,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
      ],
    );
  }
}
