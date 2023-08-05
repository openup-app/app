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
    PlaybackState playbackState,
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
  PlaybackState _playbackState = PlaybackState.idle;

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
      setState(() => _playbackState = playbackInfo.state);
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
      _playbackState,
      _player.playbackInfoStream,
    );
  }
}

class ProfileDisplay extends ConsumerStatefulWidget {
  final Profile profile;
  final Stream<PlaybackInfo> playbackInfoStream;
  final VoidCallback onPlay;
  final VoidCallback onPause;
  final VoidCallback onRecord;
  final VoidCallback onBlock;

  const ProfileDisplay({
    super.key,
    required this.profile,
    required this.playbackInfoStream,
    required this.onPlay,
    required this.onPause,
    required this.onRecord,
    required this.onBlock,
  });

  @override
  ConsumerState<ProfileDisplay> createState() => _ProfileDisplayState();
}

class _ProfileDisplayState extends ConsumerState<ProfileDisplay> {
  @override
  Widget build(BuildContext context) {
    final myUid = ref.read(userProvider2).map(
          guest: (_) => null,
          signedIn: (signedIn) => signedIn.account.profile.uid,
        );
    final mutualContactCount = widget.profile.mutualContacts.length;
    final playingStream = widget.playbackInfoStream.map((info) =>
        info.state != PlaybackState.idle && info.state != PlaybackState.paused);
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<bool>(
            stream: playingStream,
            initialData: false,
            builder: (context, snapshot) {
              final playing = snapshot.requireData;
              return Button(
                onPressed: () {
                  if (playing) {
                    widget.onPause();
                  } else {
                    widget.onPlay();
                  }
                },
                child: Stack(
                  children: [
                    KeyedSubtree(
                      key: ValueKey(widget.profile.uid),
                      child: NonCinematicGallery(
                        slideshow: playing,
                        gallery: widget.profile.gallery,
                      ),
                    ),
                    if (!playing)
                      const Center(
                        child: IgnorePointer(
                          child: IconWithShadow(
                            Icons.play_arrow,
                            size: 80,
                          ),
                        ),
                      ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: StreamBuilder<double>(
                        stream: widget.playbackInfoStream.map((e) {
                          return e.duration.inMilliseconds == 0
                              ? 0
                              : e.position.inMilliseconds /
                                  e.duration.inMilliseconds;
                        }),
                        initialData: 0.0,
                        builder: (context, snapshot) {
                          return DecoratedBox(
                            decoration: const BoxDecoration(
                              color: Color.fromRGBO(0x6C, 0x6C, 0x6C, 0.5),
                            ),
                            child: FractionallySizedBox(
                              widthFactor: snapshot.requireData,
                              alignment: Alignment.centerLeft,
                              child: Container(
                                height: 4,
                                decoration: const BoxDecoration(
                                  color: Color.fromRGBO(0xFF, 0xFF, 0xFF, 0.75),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(2)),
                                ),
                              ),
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
        ),
        const SizedBox(height: 28),
        Padding(
          padding: const EdgeInsets.only(left: 26, right: 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: AutoSizeText(
                            widget.profile.name,
                            minFontSize: 15,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (widget.profile.age != null)
                          Text(
                            widget.profile.age.toString(),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Button(
                      useFadeWheNoPressedCallback: false,
                      onPressed: () {
                        showCupertinoModalPopup(
                          context: context,
                          builder: (context) {
                            return _MutualFriendsModal(
                              uids: [widget.profile.uid],
                            );
                          },
                        );
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const InfoIcon(),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '$mutualContactCount mutual friend${mutualContactCount == 1 ? '' : 's'}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Builder(
                builder: (context) {
                  if (widget.profile.uid == myUid) {
                    return const SizedBox.shrink();
                  } else {
                    return ReportBlockPopupMenu2(
                      uid: widget.profile.uid,
                      name: widget.profile.name,
                      onBlock: widget.onBlock,
                      builder: (context) {
                        return const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(
                            CupertinoIcons.ellipsis,
                            color: Colors.black,
                            size: 20,
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 23),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(width: 26),
            Button(
              onPressed: Navigator.of(context).pop,
              child: Container(
                width: 51,
                height: 51,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      offset: Offset(0, 3),
                      blurRadius: 10,
                      color: Color.fromRGBO(0x00, 0x00, 0x00, 0.25),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.close,
                  color: Color.fromRGBO(0x47, 0x47, 0x47, 1.0),
                ),
              ),
            ),
            const SizedBox(width: 22),
            if (widget.profile.uid != myUid)
              Expanded(
                child: _RecordButton(
                  onPressed: () {
                    final userState = ref.read(userProvider2);
                    userState.map(
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
                                  onPressed: () => context.pushNamed('signup'),
                                  child: const Text('Log in'),
                                )
                              ],
                            );
                          },
                        );
                      },
                      signedIn: (_) => widget.onRecord(),
                    );
                  },
                ),
              ),
            const SizedBox(width: 18),
          ],
        ),
        SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
      ],
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
          width: 14,
          height: 14,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
        Icon(
          Icons.info,
          color: Color.fromRGBO(0x00, 0x85, 0xFF, 1.0),
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
    this.label = 'Send Message',
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Button(
      onPressed: onPressed,
      child: Container(
        height: 51,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: Color.fromRGBO(0x00, 0x85, 0xFF, 1.0),
          borderRadius: BorderRadius.all(Radius.circular(11)),
          boxShadow: [
            BoxShadow(
              offset: Offset(0, 2),
              blurRadius: 17,
              color: Color.fromRGBO(0x00, 0x00, 0x00, 0.25),
            ),
          ],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Colors.white,
          ),
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
                    profile.photo,
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
