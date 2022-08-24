import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide Chip;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/chat/chat_api2.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/api/users/profile.dart';
import 'package:openup/platform/just_audio_audio_player.dart';
import 'package:openup/profile_screen.dart';
import 'package:openup/report_screen.dart';
import 'package:openup/share_page.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/theming.dart';

class DiscoverPage extends ConsumerStatefulWidget {
  const DiscoverPage({Key? key}) : super(key: key);

  @override
  ConsumerState<DiscoverPage> createState() => DiscoverPageState();
}

class DiscoverPageState extends ConsumerState<DiscoverPage> {
  bool _loading = false;
  final _profiles = <ProfileWithOnline>[];
  int _currentProfileIndex = 0;
  Topic? _selectedTopic;
  final _invitedUsers = <String>{};

  @override
  void initState() {
    super.initState();
    _fetchStatuses();
  }

  Future<void> _fetchStatuses() async {
    if (!mounted) {
      return;
    }

    if (_profiles.isEmpty) {
      setState(() => _loading = true);
    }
    final myUid = ref.read(userProvider).uid;
    final api = GetIt.instance.get<Api>();
    final startAfterUid = _profiles.isEmpty ? null : _profiles.last.profile.uid;
    final profiles = await api.getDiscover(
      myUid,
      // startAfterUid: startAfterUid,
      topic: _selectedTopic,
    );

    if (!mounted) {
      return;
    }
    setState(() => _loading = false);

    profiles.fold(
      (l) {
        var message = errorToMessage(l);
        message = l.when(
          network: (_) => message,
          client: (client) => client.when(
            badRequest: () => 'Unable to request users',
            unauthorized: () => message,
            notFound: () => 'Unable to find users',
            forbidden: () => message,
            conflict: () => message,
          ),
          server: (_) => message,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
          ),
        );
      },
      (r) async {
        setState(() => _profiles.addAll(r));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final obscuredTop = 140.0 + MediaQuery.of(context).padding.top;
        final obscuredBottom = MediaQuery.of(context).padding.bottom;
        const bottomHeight = 135.0;
        const padding = 32.0;
        final itemExtent =
            constraints.maxHeight - obscuredTop - obscuredBottom + padding;
        final filteredProfiles = _profiles
            .where((profileWithOnline) =>
                _selectedTopic == null ||
                profileWithOnline.profile.topic == _selectedTopic)
            .toList();
        return Stack(
          children: [
            if (_loading)
              const Center(
                child: CircularProgressIndicator(),
              ),
            if (!_loading && filteredProfiles.isEmpty)
              Positioned(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'There are no profiles here',
                          style: Theming.of(context).text.body,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _fetchStatuses,
                        child: const Text('Refresh'),
                      ),
                    ],
                  ),
                ),
              ),
            if (!_loading && filteredProfiles.isNotEmpty)
              Positioned.fill(
                child: _SnappingListView.builder(
                  padding: EdgeInsets.only(
                    top: obscuredTop + 8,
                    bottom: obscuredBottom,
                  ),
                  itemExtent: itemExtent,
                  itemCount: filteredProfiles.length + 1,
                  onItemChanged: (index) {
                    // Seems to be off by one and the first element
                    setState(() => _currentProfileIndex = index + 1);

                    // if (index > _profiles.length - 3) {
                    //   print('fetching');
                    //   _fetchStatuses();
                    // }
                  },
                  itemBuilder: (context, index) {
                    if (index == filteredProfiles.length) {
                      if (_loading) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      return const SizedBox.shrink();
                    }

                    final profileWithOnline = filteredProfiles[index];
                    final profile = profileWithOnline.profile;
                    return SizedBox(
                      height: itemExtent,
                      child: _UserProfileDisplay(
                        profile: profile,
                        play: _currentProfileIndex == index,
                        bottomPadding: padding,
                        bottomHeight: bottomHeight,
                        online: profileWithOnline.online,
                        invited: _invitedUsers.contains(profile.uid),
                        onInvite: () =>
                            setState(() => _invitedUsers.add(profile.uid)),
                        onBlock: () => setState(() => _profiles.removeWhere(
                            ((p) => p.profile.uid == profile.uid))),
                        onReport: () {
                          Navigator.of(context).pushNamed(
                            'call-report',
                            arguments: ReportScreenArguments(uid: profile.uid),
                          );
                        },
                        onBeginRecording: () {},
                      ),
                    );
                  },
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: 140 + MediaQuery.of(context).padding.top,
              child: Stack(
                children: [
                  const BlurredSurface(
                    child: SizedBox.expand(),
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            'Discover new people',
                            style: Theming.of(context).text.body,
                          ),
                        ),
                        const SizedBox(height: 6),
                        RichText(
                          text: TextSpan(
                            style: Theming.of(context).text.body.copyWith(
                                fontSize: 16, fontWeight: FontWeight.w300),
                            children: [
                              TextSpan(
                                  text: 'Discover ',
                                  style: Theming.of(context).text.body.copyWith(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700)),
                              const TextSpan(
                                  text: 'others who also want to make '),
                              TextSpan(
                                text: 'new friends',
                                style: Theming.of(context).text.body.copyWith(
                                    fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                              const TextSpan(text: '.'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 40,
                          child: ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            scrollDirection: Axis.horizontal,
                            children: [
                              Chip(
                                label: 'All',
                                selected: _selectedTopic == null,
                                onSelected: () {
                                  if (_selectedTopic != null) {
                                    setState(() {
                                      _profiles.clear();
                                      _selectedTopic = null;
                                    });
                                    _fetchStatuses();
                                  }
                                },
                              ),
                              Chip(
                                label: 'Favourites',
                                selected: false,
                                onSelected: () {},
                              ),
                              for (final topic in Topic.values)
                                Chip(
                                  label: topicLabel(topic),
                                  selected: _selectedTopic == topic,
                                  onSelected: () {
                                    if (_selectedTopic == topic) {
                                      setState(() => _selectedTopic = null);
                                    } else {
                                      setState(() => _selectedTopic = topic);
                                    }
                                    setState(() => _profiles.clear());
                                    _fetchStatuses();
                                  },
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _UserProfileDisplay extends StatefulWidget {
  final Profile profile;
  final bool play;
  final double bottomPadding;
  final double bottomHeight;
  final bool online;
  final bool invited;
  final VoidCallback onInvite;
  final VoidCallback onBeginRecording;
  final VoidCallback onBlock;
  final VoidCallback onReport;

  const _UserProfileDisplay({
    Key? key,
    required this.profile,
    required this.play,
    required this.bottomPadding,
    required this.bottomHeight,
    required this.online,
    required this.invited,
    required this.onInvite,
    required this.onBeginRecording,
    required this.onBlock,
    required this.onReport,
  }) : super(key: key);

  @override
  State<_UserProfileDisplay> createState() => __UserProfileDisplayState();
}

class __UserProfileDisplayState extends State<_UserProfileDisplay> {
  bool _uploading = false;

  final _player = JustAudioAudioPlayer();

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
  }

  @override
  void didUpdateWidget(covariant _UserProfileDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          child: Container(
            foregroundDecoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.black,
                ],
                stops: [
                  0.2,
                  0.7,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Padding(
                  padding: EdgeInsets.only(bottom: widget.bottomHeight),
                  child: Gallery(
                    slideshow: widget.play,
                    gallery: widget.profile.gallery,
                    withWideBlur: false,
                  ),
                ),
                Positioned(
                  right: 16,
                  top: 16,
                  child: Column(
                    children: [
                      if (widget.online)
                        const Icon(
                          Icons.circle,
                          color: Colors.green,
                        ),
                      const SizedBox(height: 24),
                      Button(
                        onPressed: () {},
                        child: const Icon(
                          Icons.bookmark_outline,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Button(
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            isScrollControlled: true,
                            builder: (context) {
                              return Theming(
                                child: SharePage(
                                  profile: widget.profile,
                                  location: widget.profile.location,
                                ),
                              );
                            },
                          );
                        },
                        child: const Icon(
                          Icons.reply,
                          color: Colors.white,
                          size: 32,
                          textDirection: TextDirection.rtl,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 12 + widget.bottomPadding,
          height: widget.bottomHeight + 44,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.play)
                StreamBuilder<PlaybackInfo>(
                  stream: _player.playbackInfoStream,
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
                        height: 13,
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(3)),
                          color: Color.fromRGBO(0xD9, 0xD9, 0xD9, 1.0),
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AutoSizeText(
                          widget.profile.name,
                          maxFontSize: 26,
                          style: Theming.of(context).text.body,
                        ),
                        Text(
                          widget.profile.location,
                          style: Theming.of(context).text.body.copyWith(
                              fontSize: 16, fontWeight: FontWeight.w300),
                        )
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      ReportBlockPopupMenu(
                        uid: widget.profile.uid,
                        name: widget.profile.name,
                        onBlock: widget.onBlock,
                        onReport: widget.onReport,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Text(
                          topicLabel(widget.profile.topic),
                          style: Theming.of(context).text.body.copyWith(
                              fontSize: 20, fontWeight: FontWeight.w400),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Consumer(
                builder: (context, ref, _) {
                  return RecordButton(
                    label: 'Invite to voice chat',
                    submitLabel: 'Send invitation',
                    submitting: _uploading,
                    submitted: widget.invited,
                    onSubmit: (path) async {
                      setState(() => _uploading = true);
                      final uid = ref.read(userProvider).uid;
                      final api = GetIt.instance.get<Api>();
                      final result = await api.sendMessage2(
                        uid,
                        widget.profile.uid,
                        ChatType2.audio,
                        path,
                      );
                      if (mounted) {
                        setState(() => _uploading = false);
                        result.fold(
                          (l) => displayError(context, l),
                          (r) => widget.onInvite(),
                        );
                      }
                    },
                    onBeginRecording: () {
                      _player.stop();
                      widget.onBeginRecording();
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// From nxcco and yunyu's SnappingListScrollPhysics: https://gist.github.com/nxcco/98fca4a7dbdecf2f423013cf55230dba
class _SnappingListView extends StatefulWidget {
  final Axis scrollDirection;
  final ScrollController? controller;

  final IndexedWidgetBuilder? itemBuilder;
  final List<Widget>? children;
  final int? itemCount;

  final double itemExtent;
  final ValueChanged<int>? onItemChanged;

  final EdgeInsets padding;

  const _SnappingListView({
    Key? key,
    this.scrollDirection = Axis.vertical,
    this.controller,
    required this.children,
    required this.itemExtent,
    required this.onItemChanged,
    this.padding = const EdgeInsets.all(0.0),
  })  : assert(itemExtent > 0),
        itemCount = null,
        itemBuilder = null,
        super(key: key);

  const _SnappingListView.builder({
    Key? key,
    this.scrollDirection = Axis.vertical,
    this.controller,
    required this.itemBuilder,
    this.itemCount,
    required this.itemExtent,
    this.onItemChanged,
    this.padding = const EdgeInsets.all(0.0),
  })  : assert(itemExtent > 0),
        children = null,
        super(key: key);

  @override
  createState() => _SnappingListViewState();
}

class _SnappingListViewState extends State<_SnappingListView> {
  int _lastItem = 0;

  @override
  Widget build(BuildContext context) {
    final startPadding = widget.scrollDirection == Axis.horizontal
        ? widget.padding.left
        : widget.padding.top;
    final scrollPhysics = _SnappingScrollPhysics(
        mainAxisStartPadding: startPadding, itemExtent: widget.itemExtent);
    final listView = widget.children != null
        ? ListView(
            scrollDirection: widget.scrollDirection,
            controller: widget.controller,
            itemExtent: widget.itemExtent,
            physics: scrollPhysics,
            padding: widget.padding,
            children: widget.children!,
          )
        : ListView.builder(
            scrollDirection: widget.scrollDirection,
            controller: widget.controller,
            itemCount: widget.itemCount,
            itemExtent: widget.itemExtent,
            physics: scrollPhysics,
            padding: widget.padding,
            itemBuilder: widget.itemBuilder!,
          );
    return NotificationListener<ScrollNotification>(
      child: listView,
      onNotification: (notif) {
        if (notif.depth == 0 &&
            widget.onItemChanged != null &&
            notif is ScrollUpdateNotification) {
          final currItem =
              (notif.metrics.pixels - startPadding) ~/ widget.itemExtent;
          if (currItem != _lastItem) {
            _lastItem = currItem;
            widget.onItemChanged!(currItem);
          }
        }
        return false;
      },
    );
  }
}

class _SnappingScrollPhysics extends ScrollPhysics {
  final double mainAxisStartPadding;
  final double itemExtent;

  const _SnappingScrollPhysics({
    ScrollPhysics? parent,
    this.mainAxisStartPadding = 0.0,
    required this.itemExtent,
  }) : super(parent: parent);

  @override
  _SnappingScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _SnappingScrollPhysics(
      parent: buildParent(ancestor),
      mainAxisStartPadding: mainAxisStartPadding,
      itemExtent: itemExtent,
    );
  }

  double _getItem(ScrollMetrics position) {
    return (position.pixels - mainAxisStartPadding) / itemExtent;
  }

  double _getPixels(ScrollMetrics position, double item) {
    return min(item * itemExtent, position.maxScrollExtent);
  }

  double _getTargetPixels(
    ScrollMetrics position,
    Tolerance tolerance,
    double velocity,
  ) {
    double item = _getItem(position);
    if (velocity < -tolerance.velocity) {
      item -= 0.5;
    } else if (velocity > tolerance.velocity) {
      item += 0.5;
    }
    return _getPixels(position, item.roundToDouble());
  }

  @override
  Simulation? createBallisticSimulation(
      ScrollMetrics position, double velocity) {
    // If we're out of range and not headed back in range, defer to the parent
    // ballistics, which should put us back in range at a page boundary.
    if ((velocity <= 0.0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0.0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }

    final Tolerance tolerance = this.tolerance;
    final double target = _getTargetPixels(position, tolerance, velocity);
    if (target != position.pixels) {
      return ScrollSpringSimulation(
        spring,
        position.pixels,
        target,
        velocity,
        tolerance: tolerance,
      );
    }
    return null;
  }

  @override
  bool get allowImplicitScrolling => false;
}
