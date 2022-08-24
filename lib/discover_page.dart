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
  List<ProfileWithOnline> _profiles = <ProfileWithOnline>[];
  int _currentProfileIndex = 0;
  Topic? _selectedTopic;
  JustAudioAudioPlayer? _player;
  final _invitedUsers = <String>{};

  @override
  void initState() {
    super.initState();
    setState(() => _loading = true);
    __fetchStatuses();
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  Future<void> __fetchStatuses() async {
    final myUid = ref.read(userProvider).uid;
    final api = GetIt.instance.get<Api>();
    final profiles = await api.getDiscover(myUid);

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
        setState(() {
          _profiles = r;
          _player = JustAudioAudioPlayer();
        });
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
                  child: ElevatedButton(
                    onPressed: __fetchStatuses,
                    child: const Text('Refresh'),
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
                  itemCount: filteredProfiles.length,
                  onItemChanged: (index) {
                    // Seems to be off by one and the first element
                    setState(() => _currentProfileIndex = index + 1);
                    _player?.stop();
                    final audio =
                        filteredProfiles[_currentProfileIndex].profile.audio;
                    if (audio != null) {
                      _player?.setUrl(audio);
                      _player?.play(loop: true);
                    }
                  },
                  itemBuilder: (context, index) {
                    final profileWithOnline = filteredProfiles[index];
                    final profile = profileWithOnline.profile;
                    return SizedBox(
                      height: itemExtent,
                      child: _UserProfileDisplay(
                        profile: profile,
                        slideshowPlaying: _currentProfileIndex == index,
                        playbackInfoStream: _player?.playbackInfoStream,
                        bottomPadding: padding,
                        bottomHeight: bottomHeight,
                        online: profileWithOnline.online,
                        invited: _invitedUsers.contains(profile.uid),
                        onInvite: () =>
                            setState(() => _invitedUsers.add(profile.uid)),
                        onBeginRecording: () => _player?.stop(),
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
                                    setState(() => _selectedTopic = null);
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
  final bool slideshowPlaying;
  final Stream<PlaybackInfo>? playbackInfoStream;
  final double bottomPadding;
  final double bottomHeight;
  final bool online;
  final bool invited;
  final VoidCallback onInvite;
  final VoidCallback onBeginRecording;

  const _UserProfileDisplay({
    Key? key,
    required this.profile,
    required this.slideshowPlaying,
    this.playbackInfoStream,
    required this.bottomPadding,
    required this.bottomHeight,
    required this.online,
    required this.invited,
    required this.onInvite,
    required this.onBeginRecording,
  }) : super(key: key);

  @override
  State<_UserProfileDisplay> createState() => __UserProfileDisplayState();
}

class __UserProfileDisplayState extends State<_UserProfileDisplay> {
  bool _uploading = false;

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
                    slideshow: widget.slideshowPlaying,
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
                                child: _SharePage(
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
          height: widget.bottomHeight + 32,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.slideshowPlaying && widget.playbackInfoStream != null)
                StreamBuilder<PlaybackInfo>(
                  stream: widget.playbackInfoStream,
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.profile.name,
                        style: Theming.of(context)
                            .text
                            .body
                            .copyWith(fontSize: 24),
                      ),
                      Text(
                        widget.profile.location,
                        style: Theming.of(context).text.body.copyWith(
                            fontSize: 16, fontWeight: FontWeight.w300),
                      )
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Icon(
                        Icons.more_horiz,
                        color: Colors.white,
                        size: 32,
                      ),
                      Text(
                        widget.profile.topic.name,
                        style: Theming.of(context).text.body.copyWith(
                            fontSize: 20, fontWeight: FontWeight.w400),
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
                    onBeginRecording: widget.onBeginRecording,
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

class _SharePage extends StatefulWidget {
  final Profile profile;
  final String location;
  const _SharePage({
    Key? key,
    required this.profile,
    required this.location,
  }) : super(key: key);

  @override
  State<_SharePage> createState() => __SharePageState();
}

class __SharePageState extends State<_SharePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final url = 'openupfriends.com/${widget.profile.name}';
    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(39),
          topRight: Radius.circular(39),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 26),
          SizedBox(
            height: 58,
            child: Stack(
              children: [
                Center(
                  child: Column(
                    children: [
                      Text(
                        widget.profile.name,
                        style: Theming.of(context).text.body.copyWith(
                            fontSize: 24, fontWeight: FontWeight.w300),
                      ),
                      Text(
                        widget.location,
                        style: Theming.of(context).text.body.copyWith(
                            fontSize: 24, fontWeight: FontWeight.w300),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 39,
                  top: 0,
                  child: Button(
                    onPressed: Navigator.of(context).pop,
                    child: const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Icon(
                        CupertinoIcons.chevron_down,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: ClipRRect(
                borderRadius: const BorderRadius.all(
                  Radius.circular(24),
                ),
                child: Gallery(
                  slideshow: true,
                  gallery: widget.profile.gallery,
                  withWideBlur: false,
                ),
              ),
            ),
          ),
          const SizedBox(height: 31),
          Text(
            'Share profile',
            style: Theming.of(context)
                .text
                .body
                .copyWith(fontSize: 24, fontWeight: FontWeight.w300),
          ),
          const SizedBox(height: 13),
          Button(
            onPressed: () {},
            child: Container(
              height: 58,
              margin: const EdgeInsets.symmetric(horizontal: 32),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(
                  Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10.0),
                    child: Icon(
                      Icons.share,
                      color: Color.fromRGBO(0x36, 0x36, 0x36, 1.0),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: AutoSizeText(
                        url,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        minFontSize: 16,
                        maxFontSize: 20,
                        style: Theming.of(context).text.body.copyWith(
                            fontWeight: FontWeight.w300, color: Colors.black),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
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
