import 'package:auto_size_text/auto_size_text.dart';
import 'package:dartz/dartz.dart' show Either;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/platform/just_audio_audio_player.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/drag_handle.dart';
import 'package:openup/widgets/gallery.dart';
import 'package:openup/widgets/icon_with_shadow.dart';
import 'package:openup/widgets/record.dart';

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

class ProfileDisplay extends StatelessWidget {
  final Profile profile;
  final Stream<PlaybackInfo> playbackInfoStream;
  final VoidCallback onPlay;
  final VoidCallback onPause;
  final Widget recordLabel;
  final VoidCallback onRecord;
  final VoidCallback? onBlock;

  const ProfileDisplay({
    super.key,
    required this.profile,
    required this.playbackInfoStream,
    required this.onPlay,
    required this.onPause,
    required this.recordLabel,
    required this.onRecord,
    this.onBlock,
  });

  @override
  Widget build(BuildContext context) {
    final mutualContactCount = profile.mutualContacts.length;
    final playingStream = playbackInfoStream.map((info) =>
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
                    onPause();
                  } else {
                    onPlay();
                  }
                },
                child: Stack(
                  children: [
                    KeyedSubtree(
                      key: ValueKey(profile.uid),
                      child: NonCinematicGallery(
                        slideshow: playing,
                        gallery: profile.gallery,
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
                        stream: playbackInfoStream.map((e) {
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
                child: Button(
                  useFadeWheNoPressedCallback: false,
                  onPressed: mutualContactCount == 0
                      ? null
                      : () {
                          onPause();
                          showCupertinoModalPopup(
                            context: context,
                            builder: (context) {
                              return _MutualContactsModal(
                                contacts: profile.mutualContacts,
                              );
                            },
                          );
                        },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: AutoSizeText(
                              profile.name,
                              minFontSize: 15,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w500,
                                color: Color.fromRGBO(0x38, 0x37, 0x37, 1.0),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (profile.age != null)
                            Text(
                              profile.age.toString(),
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w300,
                                color: Color.fromRGBO(0x38, 0x37, 0x37, 1.0),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const InfoIcon(),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '$mutualContactCount Shared Connection${mutualContactCount == 1 ? '' : 's'}',
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
                    ],
                  ),
                ),
              ),
              if (onBlock != null)
                ReportBlockPopupMenu2(
                  uid: profile.uid,
                  name: profile.name,
                  onBlock: onBlock!,
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
            Expanded(
              child: _RecordButton(
                label: recordLabel,
                onPressed: onRecord,
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
    return const Stack(
      alignment: Alignment.center,
      children: [
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
  final Widget label;
  final VoidCallback? onPressed;

  const _RecordButton({
    super.key,
    required this.label,
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
        child: DefaultTextStyle(
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Colors.white,
          ),
          child: label,
        ),
      ),
    );
  }
}

class _MutualContactsModal extends StatelessWidget {
  final List<KnownContact> contacts;

  const _MutualContactsModal({
    super.key,
    required this.contacts,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoActionSheet(
      cancelButton: CupertinoActionSheetAction(
        onPressed: Navigator.of(context).pop,
        isDefaultAction: true,
        child: const Text('Cancel'),
      ),
      title: const Text(
        'Shared connections',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w300,
          color: Colors.white,
        ),
      ),
      actions: [
        for (final contact in contacts)
          CupertinoActionSheetAction(
            onPressed: () {
              showProfileBottomSheetLoadProfile(
                context: context,
                uid: contact.uid,
              );
            },
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
                    contact.photo,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    contact.name,
                    textAlign: TextAlign.left,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                    ),
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

/// Implements the actions that [ProfileDisplay] can perform.
class ProfileDisplayBehavior extends ConsumerWidget {
  final Profile profile;
  final GlobalKey<ProfileBuilderState> profileBuilderKey;
  final PlaybackState playbackState;
  final Stream<PlaybackInfo> playbackInfoStream;
  final VoidCallback onReportedOrBlocked;

  const ProfileDisplayBehavior({
    super.key,
    required this.profile,
    required this.profileBuilderKey,
    required this.playbackState,
    required this.playbackInfoStream,
    required this.onReportedOrBlocked,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Consumer(
      builder: (context, ref, child) {
        final userState = ref.read(userProvider2);
        final myUid = userState.map(
          guest: (_) => null,
          signedIn: (signedIn) => signedIn.account.profile.uid,
        );
        final isMe = profile.uid == myUid;
        return ProfileDisplay(
          profile: profile,
          playbackInfoStream: playbackInfoStream,
          onPlay: () => profileBuilderKey.currentState?.play(),
          onPause: () => profileBuilderKey.currentState?.pause(),
          recordLabel: isMe
              ? const Text('Update Voice Bio')
              : const Text('Send Message'),
          onRecord: () async {
            final result = await showRecordPanel(
              context: context,
              title: isMe
                  ? const Text('Recording Voice Bio')
                  : const Text('Recording Message'),
              submitLabel: isMe
                  ? const Text('Finish & Update')
                  : const Text('Finish & Send'),
            );
            if (context.mounted) {
              if (result == null) {
                return;
              }

              final notifier = ref.read(userProvider2.notifier);
              final future = isMe
                  ? notifier.updateAudioBio(result.audio)
                  : notifier.sendMessage(uid: profile.uid, audio: result.audio);
              return withBlockingModal(
                context: context,
                label: isMe ? 'Updating voice bio...' : 'Sending message...',
                future: future,
              );
            }
          },
          onBlock: isMe
              ? null
              : () {
                  // TODO
                },
        );
      },
    );
  }
}

class _ProfileDisplayLoadProfile extends ConsumerStatefulWidget {
  final String uid;
  const _ProfileDisplayLoadProfile({
    super.key,
    required this.uid,
  });

  @override
  ConsumerState<_ProfileDisplayLoadProfile> createState() =>
      __ProfileDisplayLoadProfileState();
}

class __ProfileDisplayLoadProfileState
    extends ConsumerState<_ProfileDisplayLoadProfile> {
  final profileBuilderKey = GlobalKey<ProfileBuilderState>();
  Either<ApiError, Profile>? _profile;

  @override
  void initState() {
    super.initState();
    _init();
  }

  void _init() async {
    final result = await ref.read(apiProvider).getProfile(widget.uid);
    if (mounted) {
      setState(() => _profile = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    if (profile == null) {
      return const Center(
        child: LoadingIndicator(
          color: Colors.black,
        ),
      );
    }
    return profile.fold(
      (l) {
        return const Center(
          child: Text(
            'Failed to load profile',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.black,
            ),
          ),
        );
      },
      (profile) {
        return _buildProfileBuilderIfNull(
          context: context,
          profile: profile,
          profileBuilderKey: profileBuilderKey,
          playbackInfoStream: null,
          builder: (context, playbackState, playbackInfoStream) {
            return ProfileDisplayBehavior(
              profile: profile,
              profileBuilderKey: profileBuilderKey,
              playbackState: playbackState,
              playbackInfoStream: playbackInfoStream,
              onReportedOrBlocked: Navigator.of(context).pop,
            );
          },
        );
      },
    );
  }
}

void showProfileBottomSheetLoadProfile({
  required BuildContext context,
  AnimationController? transitionAnimationController,
  required String uid,
}) {
  final mediaQueryData = MediaQuery.of(context);
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    useRootNavigator: true,
    isScrollControlled: true,
    transitionAnimationController: transitionAnimationController,
    builder: (context) {
      return MediaQuery(
        data: mediaQueryData,
        child: Stack(
          children: [
            _ProfileDisplayLoadProfile(
              uid: uid,
            ),
            // Builder to access media query via context
            Builder(
              builder: (context) {
                return Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top + 8),
                    child: const DragHandle(
                      width: 36,
                      color: Colors.white,
                      shadow: BoxShadow(
                        offset: Offset(0, 1),
                        blurRadius: 8,
                        color: Color.fromRGBO(0x00, 0x00, 0x00, 0.4),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      );
    },
  );
}

void showProfileBottomSheet({
  required BuildContext context,
  AnimationController? transitionAnimationController,
  required Profile profile,
  GlobalKey<ProfileBuilderState>? existingProfileBuilderKey,
  Stream<PlaybackInfo>? existingPlaybackInfoStream,
}) {
  final mediaQueryData = MediaQuery.of(context);
  final profileBuilderKey =
      existingProfileBuilderKey ?? GlobalKey<ProfileBuilderState>();
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    useRootNavigator: true,
    isScrollControlled: true,
    transitionAnimationController: transitionAnimationController,
    builder: (context) {
      return MediaQuery(
        data: mediaQueryData,
        child: Stack(
          children: [
            _buildProfileBuilderIfNull(
              context: context,
              profile: profile,
              profileBuilderKey: profileBuilderKey,
              playbackInfoStream: existingPlaybackInfoStream,
              builder: (context, playbackState, playbackInfoStream) {
                return ProfileDisplayBehavior(
                  profile: profile,
                  profileBuilderKey: profileBuilderKey,
                  playbackState: playbackState,
                  playbackInfoStream: playbackInfoStream,
                  onReportedOrBlocked: Navigator.of(context).pop,
                );
              },
            ),
            // Builder to access media query via context
            Builder(
              builder: (context) {
                return Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top + 8),
                    child: const DragHandle(
                      width: 36,
                      color: Colors.white,
                      shadow: BoxShadow(
                        offset: Offset(0, 1),
                        blurRadius: 8,
                        color: Color.fromRGBO(0x00, 0x00, 0x00, 0.4),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      );
    },
  );
}

Widget _buildProfileBuilderIfNull({
  required BuildContext context,
  required Profile profile,
  required GlobalKey<ProfileBuilderState> profileBuilderKey,
  required Stream<PlaybackInfo>? playbackInfoStream,
  required Widget Function(BuildContext context, PlaybackState playbackState,
          Stream<PlaybackInfo> playbackInfoStream)
      builder,
}) {
  if (playbackInfoStream == null) {
    return ProfileBuilder(
      key: profileBuilderKey,
      play: true,
      profile: profile,
      builder: (context, playbackState, playbackInfoStream) {
        return builder(context, playbackState, playbackInfoStream);
      },
    );
  }
  return StreamBuilder<PlaybackState>(
    stream: playbackInfoStream.map((event) => event.state),
    initialData: PlaybackState.idle,
    builder: (context, snapshot) {
      final playbackState = snapshot.requireData;
      return builder(context, playbackState, playbackInfoStream);
    },
  );
}
