import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide Chip;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/api/users/profile.dart';
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
  List<TopicParticipant> _statuses = <TopicParticipant>[];

  @override
  void initState() {
    super.initState();
    setState(() => _loading = true);
    _fetchParticipants();
  }

  Future<void> _fetchParticipants() async {
    final myUid = ref.read(userProvider).uid;
    final api = GetIt.instance.get<Api>();
    const tempNearbyOnly = false;
    final topicParticipants = await api.getStatuses(myUid, tempNearbyOnly);
    if (mounted) {
      setState(() => _loading = false);
    }
    if (!mounted) {
      return;
    }
    topicParticipants.fold(
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
          _statuses =
              r.values.fold(<TopicParticipant>[], (p, e) => p..addAll(e));
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const obscuredTop = 164.0;
        const obscuredBottom = 72.0;
        const bottomHeight = 135.0;
        const padding = 32.0;
        final itemExtent =
            constraints.maxHeight - obscuredTop - obscuredBottom + padding;
        return Stack(
          children: [
            if (_loading)
              const Center(
                child: CircularProgressIndicator(),
              ),
            if (!_loading)
              Positioned.fill(
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: obscuredTop),
                  physics: _SnappingScrollPhysics(
                    itemExtent: itemExtent,
                    mainAxisStartPadding: obscuredTop,
                  ),
                  itemCount: _statuses.length,
                  itemBuilder: (context, index) {
                    final status = _statuses[index];
                    return SizedBox(
                      height: itemExtent,
                      child: Stack(
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
                                    padding: const EdgeInsets.only(
                                        bottom: bottomHeight),
                                    child: Image.network(
                                      status.photo,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    right: 16,
                                    top: 16,
                                    child: Column(
                                      children: [
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
                                              backgroundColor:
                                                  Colors.transparent,
                                              isScrollControlled: true,
                                              builder: (context) {
                                                return const Theming(
                                                  child: _SharePage(),
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
                            bottom: 12 + padding,
                            height: bottomHeight,
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          status.name,
                                          style: Theming.of(context)
                                              .text
                                              .body
                                              .copyWith(fontSize: 24),
                                        ),
                                        Text(
                                          status.location,
                                          style: Theming.of(context)
                                              .text
                                              .body
                                              .copyWith(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w300),
                                        )
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        const Icon(
                                          Icons.more_horiz,
                                          color: Colors.white,
                                          size: 32,
                                        ),
                                        Text(
                                          status.topic,
                                          style: Theming.of(context)
                                              .text
                                              .body
                                              .copyWith(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w400),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const RecordButton(
                                    label: 'Invite to voice chat'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: 154,
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
                                selected: true,
                                onSelected: () {},
                              ),
                              Chip(
                                label: 'Lonely',
                                selected: false,
                                onSelected: () {},
                              ),
                              Chip(
                                label: 'Favourites',
                                selected: false,
                                onSelected: () {},
                              ),
                              Chip(
                                label: 'Just Moved',
                                selected: false,
                                onSelected: () {},
                              ),
                              Chip(
                                label: 'Can\'t Sleep',
                                selected: false,
                                onSelected: () {},
                              ),
                              Chip(
                                label: 'Bored',
                                selected: false,
                                onSelected: () {},
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

class _SharePage extends StatefulWidget {
  const _SharePage({Key? key}) : super(key: key);

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
    const url = 'openupfriends.com/SammieJammy';
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
                        'SammieJammy',
                        style: Theming.of(context).text.body.copyWith(
                            fontSize: 24, fontWeight: FontWeight.w300),
                      ),
                      Text(
                        'Fort Worth, Texas',
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
                child: Image.network(
                  'https://picsum.photos/id/690/200/',
                  fit: BoxFit.cover,
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
