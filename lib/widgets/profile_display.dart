import 'dart:ui';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:openup/api/api.dart';
import 'package:openup/platform/just_audio_audio_player.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/gallery.dart';

class UserProfileDisplay extends StatefulWidget {
  final Profile profile;
  final bool playSlideshow;
  final bool invited;

  const UserProfileDisplay({
    Key? key,
    required this.profile,
    required this.playSlideshow,
    required this.invited,
  }) : super(key: key);

  @override
  State<UserProfileDisplay> createState() => _UserProfileDisplayState();
}

class _UserProfileDisplayState extends State<UserProfileDisplay> {
  @override
  Widget build(BuildContext context) {
    return CinematicGallery(
      slideshow: widget.playSlideshow,
      gallery: widget.profile.collection.photos,
    );
  }
}

class UserProfileInfoDisplay extends StatefulWidget {
  final Profile profile;
  final bool play;
  final Widget Function(
          BuildContext context, bool play, Stream<PlaybackInfo> playbackInfo)
      builder;

  const UserProfileInfoDisplay({
    super.key,
    required this.profile,
    required this.play,
    required this.builder,
  });

  @override
  State<UserProfileInfoDisplay> createState() => UserProfileInfoDisplayState();
}

class UserProfileInfoDisplayState extends State<UserProfileInfoDisplay> {
  final _player = JustAudioAudioPlayer();
  bool _audioPaused = false;

  @override
  void initState() {
    super.initState();
    final audio = widget.profile.audio;
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
  void didUpdateWidget(covariant UserProfileInfoDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.profile.audio != widget.profile.audio) {
      final audio = widget.profile.audio;
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

class PlaybackBar extends StatelessWidget {
  final Stream<PlaybackInfo> playbackInfoStream;

  const PlaybackBar({
    super.key,
    required this.playbackInfoStream,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PlaybackInfo>(
      stream: playbackInfoStream,
      initialData: const PlaybackInfo(),
      builder: (context, snapshot) {
        final value = snapshot.requireData;
        final position = value.position.inMilliseconds;
        final duration = value.duration.inMilliseconds;
        final ratio = duration == 0 ? 0.0 : position / duration;
        return ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5),
            child: Container(
              height: 8,
              color: const Color.fromRGBO(0xD7, 0xD7, 0xD7, 0.50),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: ratio < 0 ? 0 : ratio,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    color: const Color.fromRGBO(0xE7, 0xE7, 0xE7, 0.75),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class UserNameAndInvite extends StatelessWidget {
  final Profile profile;
  final VoidCallback onRecordInvite;

  const UserNameAndInvite({
    super.key,
    required this.profile,
    required this.onRecordInvite,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          color: Colors.white,
          padding: EdgeInsets.only(
            left: 34.0,
            right: 34.0,
            top: 26,
            bottom: 26 + MediaQuery.of(context).padding.bottom,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        AutoSizeText(
                          profile.name,
                          maxFontSize: 32,
                          minFontSize: 26,
                          style:
                              Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    color: Colors.black,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          profile.age.toString(),
                          style:
                              Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    color: Colors.black,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w300,
                                  ),
                        ),
                        const SizedBox(width: 8),
                        OnlineIndicatorBuilder(
                          uid: profile.uid,
                          builder: (context, online) {
                            return online
                                ? const OnlineIndicator()
                                : const SizedBox.shrink();
                          },
                        ),
                      ],
                    ),
                    if (profile.mutualFriends.isNotEmpty)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.info,
                            color: Color.fromRGBO(0x38, 0x7B, 0xFF, 1.0),
                            size: 18,
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Button(
                              onPressed: profile.mutualFriends.isEmpty
                                  ? null
                                  : () => _showMutualFriendsModal(context),
                              useFadeWheNoPressedCallback: false,
                              child: Text(
                                profile.mutualFriends.length == 1
                                    ? '1 mutual friend'
                                    : '${profile.mutualFriends.length} mutual friends',
                                textAlign: TextAlign.left,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium!
                                    .copyWith(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  shadows: [
                                    const Shadow(
                                      blurRadius: 4,
                                      color: Color.fromRGBO(
                                          0x00, 0x00, 0x00, 0.25),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: _RecordButton(
                    onPressed: onRecordInvite,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!kReleaseMode)
          ColoredBox(
            color: Colors.white,
            child: Container(
              decoration: const BoxDecoration(
                color: Color.fromRGBO(0x00, 0x00, 0x00, 0.4),
                borderRadius: BorderRadius.all(
                  Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.all(8),
              alignment: Alignment.center,
              child: AutoSizeText(
                profile.uid,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium!
                    .copyWith(color: Colors.black),
              ),
            ),
          ),
      ],
    );
  }

  void _showMutualFriendsModal(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return _MutualFriendsModal(
          uids: profile.mutualFriends,
        );
      },
    );
  }
}

class UserDetails extends StatelessWidget {
  final Profile profile;
  final Stream<PlaybackInfo>? playbackStream;
  final bool showRecordButton;
  final String recordButtonLabel;
  final VoidCallback onRecordPressed;

  const UserDetails({
    Key? key,
    required this.profile,
    required this.playbackStream,
    required this.showRecordButton,
    required this.recordButtonLabel,
    required this.onRecordPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          left: 24,
          right: 24,
          bottom: 24 + MediaQuery.of(context).padding.bottom,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AutoSizeText(
                    profile.name,
                    maxFontSize: 32,
                    minFontSize: 26,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    profile.age.toString(),
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontSize: 28,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(width: 8),
                  OnlineIndicatorBuilder(
                    uid: profile.uid,
                    builder: (context, online) {
                      return online
                          ? const OnlineIndicator()
                          : const SizedBox.shrink();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                height: 4,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(2)),
                  color: Color.fromRGBO(0xFF, 0xFF, 0xFF, 0.5),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: StreamBuilder<PlaybackInfo>(
                    stream: playbackStream,
                    initialData: const PlaybackInfo(),
                    builder: (context, snapshot) {
                      final value = snapshot.requireData;
                      final position = value.position.inMilliseconds;
                      final duration = value.duration.inMilliseconds;
                      final ratio = duration == 0 ? 0.0 : position / duration;
                      return FractionallySizedBox(
                        widthFactor: ratio < 0 ? 0 : ratio,
                        alignment: Alignment.centerLeft,
                        child: Container(
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(2)),
                            color: Color.fromRGBO(0xFF, 0xFF, 0xFF, 1.0),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Button(
                      onPressed: profile.mutualFriends.isEmpty
                          ? null
                          : () => _showMutualFriendsModal(context),
                      useFadeWheNoPressedCallback: false,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (profile.mutualFriends.isNotEmpty)
                            Text(
                              profile.mutualFriends.length == 1
                                  ? '1 mutual friend'
                                  : '${profile.mutualFriends.length} mutual friends',
                              textAlign: TextAlign.left,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                shadows: [
                                  const Shadow(
                                    blurRadius: 4,
                                    color:
                                        Color.fromRGBO(0x00, 0x00, 0x00, 0.25),
                                  )
                                ],
                              ),
                            ),
                          AutoSizeText(
                            profile.location,
                            overflow: TextOverflow.ellipsis,
                            minFontSize: 2,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                  fontWeight: FontWeight.w300,
                                  fontSize: 15,
                                ),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (showRecordButton)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: _RecordButton(
                        label: recordButtonLabel,
                        onPressed: onRecordPressed,
                      ),
                    ),
                ],
              ),
              if (!kReleaseMode)
                Container(
                  decoration: const BoxDecoration(
                    color: Color.fromRGBO(0x00, 0x00, 0x00, 0.4),
                    borderRadius: BorderRadius.all(
                      Radius.circular(24),
                    ),
                  ),
                  padding: const EdgeInsets.all(8),
                  alignment: Alignment.center,
                  child: AutoSizeText(
                    profile.uid,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _showMutualFriendsModal(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return _MutualFriendsModal(
          uids: profile.mutualFriends,
        );
      },
    );
  }
}

class _RecordButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const _RecordButton({
    super.key,
    this.label = 'send invite',
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Button(
      onPressed: onPressed,
      child: Container(
        width: 145,
        height: 51,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromRGBO(0xEA, 0x6B, 0x6B, 1.0),
              Color.fromRGBO(0xF1, 0x3B, 0x3B, 1.0),
            ],
          ),
          borderRadius: BorderRadius.all(Radius.circular(9)),
          boxShadow: [
            BoxShadow(
              blurRadius: 20,
              color: Color.fromRGBO(0x00, 0x00, 0x00, 0.15),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mic),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium!
                  .copyWith(fontSize: 14, fontWeight: FontWeight.w400),
            ),
          ],
        ),
      ),
    );
  }
}

class _MutualFriendsModal extends StatefulWidget {
  final List<String> uids;

  const _MutualFriendsModal({
    super.key,
    required this.uids,
  });

  @override
  State<_MutualFriendsModal> createState() => _MutualFriendsModalState();
}

class _MutualFriendsModalState extends State<_MutualFriendsModal> {
  bool _loading = true;

  final _profiles = <Profile>[];

  @override
  void initState() {
    super.initState();
    final api = GetIt.instance.get<Api>();
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
