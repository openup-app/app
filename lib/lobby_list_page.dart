import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:list_diff/list_diff.dart';
import 'package:lottie/lottie.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/api/users/profile.dart';
import 'package:openup/call_screen.dart';
import 'package:openup/main.dart';
import 'package:openup/notifications/connectycube_call_kit_integration.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/image_builder.dart';
import 'package:openup/widgets/profile_button.dart';
import 'package:openup/widgets/theming.dart';

class StartWithCall {
  final String rid;
  final SimpleProfile profile;

  StartWithCall({
    required this.rid,
    required this.profile,
  });
}

class LobbyListPage extends ConsumerStatefulWidget {
  final StartWithCall? startWithCall;
  const LobbyListPage({
    Key? key,
    this.startWithCall,
  }) : super(key: key);

  @override
  LobbyListPageState createState() => LobbyListPageState();
}

class LobbyListPageState extends ConsumerState<LobbyListPage> {
  final _topics = {
    Topic.moved: 'Just moved',
    Topic.outing: 'Going out',
    Topic.lonely: 'Lonely',
    Topic.vacation: 'On vacation',
    Topic.business: 'Business',
  };
  Topic _topic = Topic.all;
  bool _topicsExpanded = false;

  bool _loading = false;
  Status? _status;
  var _participants = <TopicParticipant>[];
  late final Timer _refreshTimer;

  final _listKey = GlobalKey<AnimatedListState>();

  @override
  void initState() {
    super.initState();
    setState(() => _loading = true);

    Future.wait([
      FirebaseMessaging.instance.getToken(),
      getVoipPushNotificationToken(),
    ]).then((tokens) {
      if (!mounted) {
        return;
      }
      final api = GetIt.instance.get<Api>();
      api.addNotificationTokens(
        ref.read(userProvider).uid,
        messagingToken: tokens[0],
        voipToken: tokens[1],
      );
    });

    Future.wait([
      _fetchParticipants(),
      _getStatus(),
    ]).whenComplete(() {
      if (mounted) {
        setState(() => _loading = false);
      }
    });

    _refreshTimer = Timer.periodic(
      const Duration(seconds: 8),
      (_) async {
        if (mounted) {
          await _fetchParticipants();
        }
      },
    );

    final startWithCall = widget.startWithCall;
    if (startWithCall != null) {
      notificationCall(startWithCall);
    }
  }

  void notificationCall(StartWithCall startWithCall) {
    WidgetsBinding.instance?.scheduleFrameCallback((_) {
      _showPanel(builder: (context) {
        return _buildCallScreen(
          rid: startWithCall.rid,
          profile: startWithCall.profile,
        );
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    _refreshTimer.cancel();
  }

  Future<void> _fetchParticipants() async {
    final myUid = ref.read(userProvider).uid;
    final api = GetIt.instance.get<Api>();
    final participants = await api.getTopicList(_topic);
    if (mounted) {
      participants.fold(
        (l) {
          var message = errorToMessage(l);
          message = l.when(
            network: (_) => message,
            client: (client) => client.when(
              badRequest: () => 'Failed to get users',
              unauthorized: () => message,
              notFound: () => 'Unable to find topic participants',
              forbidden: () => message,
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
          final participants = r.where((p) => p.uid != myUid).toList()
            ..sort((a, b) => a.name.compareTo(b.name));

          final differences = await diff(
            _participants,
            participants,
            areEqual: (a, b) {
              return (a as TopicParticipant).name ==
                  (b as TopicParticipant).name;
            },
            getHashCode: (a) => a.hashCode,
          );
          differences.forEach(_performDiff);
          setState(() => _participants = participants);
        },
      );
    }
  }

  void _performDiff(Operation<TopicParticipant> d) {
    switch (d.type) {
      case OperationType.insertion:
        _listKey.currentState?.insertItem(
          d.index,
          duration: const Duration(milliseconds: 800),
        );
        break;
      case OperationType.deletion:
        _listKey.currentState?.removeItem(
          d.index,
          (context, animation) {
            return FadeTransition(
              opacity: animation,
              child: SizeTransition(
                sizeFactor: CurveTween(curve: Curves.easeIn).animate(animation),
                child: _ParticipantTile(
                  participant: d.item,
                  onPressed: () {},
                ),
              ),
            );
          },
          duration: const Duration(milliseconds: 800),
        );
        break;
    }
  }

  Future<void> _getStatus() async {
    final api = GetIt.instance.get<Api>();
    final uid = ref.read(userProvider).uid;
    final result = await api.getStatus(uid);
    result.fold(
      (l) => displayError(context, l),
      (r) => setState(() => _status = r),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Padding(
            padding:
                EdgeInsets.only(top: MediaQuery.of(context).padding.top + 88),
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 27.0, vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'People available to talk ...',
                        style: Theming.of(context).text.body.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w300,
                            color: const Color.fromRGBO(0x8E, 0x8E, 0x8E, 1.0)),
                      ),
                      const Spacer(),
                      Text(
                        _loading ? '' : _participants.length.toString(),
                        style: Theming.of(context).text.body.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w300,
                            color: const Color.fromRGBO(0x00, 0xD1, 0xFF, 1.0)),
                      ),
                    ],
                  ),
                ),
                if (_loading)
                  const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_participants.isEmpty)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: Text(
                          'No one is chatting about this topic',
                          textAlign: TextAlign.center,
                          style: Theming.of(context).text.body.copyWith(
                              fontSize: 24,
                              fontWeight: FontWeight.w500,
                              color:
                                  const Color.fromRGBO(0xAA, 0xAA, 0xAA, 1.0)),
                        ),
                      ),
                    ),
                  ),
                if (!_loading)
                  Expanded(
                    child: AnimatedList(
                      key: _listKey,
                      padding: const EdgeInsets.only(bottom: 156),
                      initialItemCount: _participants.length,
                      itemBuilder: (context, index, animation) {
                        final participant = _participants[index];
                        return FadeTransition(
                          opacity: animation,
                          child: SizeTransition(
                            sizeFactor: CurveTween(curve: Curves.easeOut)
                                .animate(animation),
                            child: _ParticipantTile(
                              participant: participant,
                              onPressed: () => _call(participant),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
        Positioned(
          right: 24,
          top: MediaQuery.of(context).padding.top + 16,
          child: const ProfileButton(
            color: Color.fromRGBO(0x89, 0xDE, 0xFF, 1.0),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 18.0, bottom: 12),
                child: Button(
                  onPressed: _participants.isEmpty
                      ? null
                      : () {
                          final index = Random().nextInt(_participants.length);
                          final participant = _participants[index];
                          _call(participant);
                        },
                  child: Container(
                    width: 140,
                    height: 61,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(61)),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color.fromRGBO(0x26, 0xEF, 0x3A, 1.0),
                          Color.fromRGBO(0x0A, 0x98, 0x18, 1.0),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 4.0,
                          offset: Offset(0.0, 4.0),
                          color: Color.fromRGBO(0x00, 0x00, 0x00, 0.25),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.call,
                          size: 30,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Random',
                          style: Theming.of(context).text.body.copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: _loading
                    ? null
                    : () async {
                        final completer = Completer<_StatusResult?>();
                        // Bug in Flutter not letting showBottomPanel return a result: https://github.com/flutter/flutter/issues/66837
                        await _showPanel<_StatusResult>(
                          builder: (context) {
                            return _StatusBox(
                              topic: _topic,
                              status: _status?.text,
                              resultCompleter: completer,
                            );
                          },
                        );

                        if (completer.isCompleted) {
                          final result = await completer.future;
                          setState(() => _status = result?.status);
                        }
                      },
                child: DecoratedBox(
                  decoration: const BoxDecoration(color: Colors.white),
                  child: Container(
                    height: 54,
                    margin: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    padding: const EdgeInsets.only(left: 38, right: 16),
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.all(
                        Radius.circular(34.5),
                      ),
                      color: Color.fromRGBO(0xE6, 0xE6, 0xE6, 1.0),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _status?.text ?? 'Why are you here today?',
                            overflow: TextOverflow.ellipsis,
                            style: Theming.of(context).text.body.copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.w300,
                                color: const Color.fromRGBO(
                                    0x7B, 0x7B, 0x7B, 1.0)),
                          ),
                        ),
                        const Icon(
                          Icons.access_time_filled,
                          color: Color.fromRGBO(0x7B, 0x7B, 0x7B, 1.0),
                        ),
                        const SizedBox(width: 4),
                        if (_status != null)
                          _CountdownTimer(
                            key: Key(_status?.text ?? ''),
                            remaining:
                                Duration(milliseconds: _status!.remaining),
                            onTimeUp: () {
                              if (mounted) {
                                setState(() => _status = null);
                              }
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_topicsExpanded)
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                setState(() => _topicsExpanded = false);
              },
              child: Container(color: Colors.transparent),
            ),
          ),
        Positioned(
          key: const Key('topic_selector'),
          left: 0,
          top: MediaQuery.of(context).padding.top + 16,
          child: _TopicSelector(
            open: _topicsExpanded,
            topics: _topics,
            selected: _topic,
            onSelected: (topic) async {
              setState(() {
                _topic = topic;
                _loading = true;
              });
              await _fetchParticipants();
              if (mounted) {
                setState(() => _loading = false);
              }
            },
            onOpen: _loading
                ? null
                : (open) => setState(() => _topicsExpanded = open),
          ),
        ),
      ],
    );
  }

  void _call(TopicParticipant participant) {
    _showPanel(
      dragIndicatorColor: Colors.white,
      builder: (context) {
        return _CallBox(participant: participant);
      },
    );
  }

  Future<T?> _showPanel<T>({
    Color dragIndicatorColor = const Color.fromRGBO(0xC4, 0xC4, 0xC4, 1.0),
    required WidgetBuilder builder,
  }) {
    final result = showBottomSheet<T?>(
      context: context,
      elevation: 8,
      clipBehavior: Clip.hardEdge,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(41),
          topRight: Radius.circular(41),
        ),
      ),
      builder: (context) {
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SizedBox(
            height: 274,
            child: Stack(
              children: [
                Positioned.fill(
                  child: builder(context),
                ),
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(top: 10),
                    decoration: BoxDecoration(
                      color: dragIndicatorColor,
                      borderRadius: const BorderRadius.all(Radius.circular(2)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    return result.closed;
  }
}

class _CountdownTimer extends StatefulWidget {
  final Duration remaining;
  final VoidCallback onTimeUp;
  const _CountdownTimer({
    Key? key,
    required this.remaining,
    required this.onTimeUp,
  }) : super(key: key);

  @override
  State<_CountdownTimer> createState() => __CountdownTimerState();
}

class __CountdownTimerState extends State<_CountdownTimer> {
  late DateTime _statusUpdatedTime;
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _restart();
  }

  @override
  void didUpdateWidget(covariant _CountdownTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.remaining != widget.remaining) {
      _restart();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _restart() {
    _statusUpdatedTime = DateTime.now();
    _update();
    _startPeriodicTimer();
  }

  void _startPeriodicTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => _update(),
    );
  }

  void _update() {
    final ellapsed = DateTime.now().difference(_statusUpdatedTime).abs();
    final remaining = widget.remaining - ellapsed;
    SchedulerBinding.instance?.scheduleFrameCallback((timeStamp) {
      if (remaining.isNegative) {
        setState(() {
          _remaining = Duration.zero;
          _timer?.cancel();
          widget.onTimeUp();
        });
      } else {
        setState(() => _remaining = remaining);
      }
    });
  }

  String _formatDuration(Duration d) =>
      '${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Text(
      _formatDuration(_remaining),
      style: Theming.of(context).text.body.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w300,
          color: const Color.fromRGBO(0x7B, 0x7B, 0x7B, 1.0)),
    );
  }
}

class _ParticipantTile extends StatelessWidget {
  final TopicParticipant participant;
  final VoidCallback onPressed;
  const _ParticipantTile({
    Key? key,
    required this.participant,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(
        color: Color.fromRGBO(0x01, 0xCB, 0xF7, 1.0),
        borderRadius: BorderRadius.all(Radius.circular(38)),
      ),
      child: Button(
        onPressed: onPressed,
        child: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.only(top: 20.0, left: 27.0, right: 27.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          height: 48,
                          padding: const EdgeInsets.only(right: 8),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: AutoSizeText(
                              participant.name,
                              minFontSize: 16,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theming.of(context).text.body.copyWith(
                                fontSize: 36,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                shadows: [
                                  const Shadow(
                                    blurRadius: 7.0,
                                    offset: Offset(2.0, 2.0),
                                    color:
                                        Color.fromRGBO(0x00, 0x00, 0x00, 0.25),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        _buildSymbolText(
                          context,
                          Icons.people,
                          participant.attributes.ethnicity,
                        ),
                        _buildSymbolText(
                          context,
                          Icons.self_improvement,
                          participant.attributes.religion,
                        ),
                        _buildSymbolText(
                          context,
                          Icons.work,
                          participant.attributes.interests,
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                  Container(
                    clipBehavior: Clip.hardEdge,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(13)),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 4.0,
                          offset: Offset(0.0, 4.0),
                          color: Color.fromRGBO(0x00, 0x00, 0x00, 0.25),
                        ),
                      ],
                    ),
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(
                        sigmaX: 8.0,
                        sigmaY: 8.0,
                      ),
                      child: Image.network(
                        participant.photo,
                        width: 105,
                        height: 124,
                        fit: BoxFit.cover,
                        frameBuilder: fadeInFrameBuilder,
                        loadingBuilder: circularProgressLoadingBuilder,
                        errorBuilder: iconErrorBuilder,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.fromRGBO(0x08, 0x6A, 0x7F, 1.0),
                    Color.fromRGBO(0x05, 0x57, 0x69, 1.0),
                  ],
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                participant.statusText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theming.of(context).text.body.copyWith(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w300),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSymbolText(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            icon,
            size: 21,
          ),
          const SizedBox(width: 11),
          Text(
            text,
            style: Theming.of(context).text.body.copyWith(
                fontSize: 16, color: Colors.white, fontWeight: FontWeight.w300),
          ),
        ],
      ),
    );
  }
}

class _TopicSelector extends StatefulWidget {
  final bool open;
  final Map<Topic, String> topics;
  final Topic selected;
  final void Function(Topic topic) onSelected;
  final void Function(bool open)? onOpen;

  const _TopicSelector({
    Key? key,
    required this.open,
    required this.topics,
    required this.selected,
    required this.onSelected,
    required this.onOpen,
  }) : super(key: key);

  @override
  State<_TopicSelector> createState() => __TopicSelectorState();
}

class __TopicSelectorState extends State<_TopicSelector>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _TopicSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.open != widget.open) {
      if (widget.open) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Color.fromRGBO(0xE6, 0xE6, 0xE6, 1.0),
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Button(
            onPressed: widget.onOpen == null
                ? null
                : () {
                    widget.onOpen?.call(!widget.open);
                  },
            child: Container(
              height: 60,
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 40, right: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        (widget.open || widget.selected == Topic.all)
                            ? 'Pick a topic to discuss'
                            : widget.topics[widget.selected] ??
                                'Pick a topic to discuss',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theming.of(context).text.body.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w300,
                            color: const Color.fromRGBO(0x7B, 0x7B, 0x7B, 1.0)),
                      ),
                    ),
                    RotationTransition(
                      turns: Tween(begin: 0.0, end: 0.25).animate(_controller),
                      child: const Icon(
                        Icons.chevron_right,
                        size: 40,
                        color: Color.fromRGBO(0xA2, 0xA2, 0xA2, 1.0),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizeTransition(
            sizeFactor: _controller,
            child: FadeTransition(
              opacity: _controller,
              child: ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: widget.topics.length,
                itemBuilder: (context, index) {
                  final entry = widget.topics.entries.elementAt(index);
                  final topic = Topic.values.firstWhere((t) => t == entry.key);
                  return Container(
                    height: 57,
                    margin: const EdgeInsets.only(top: 4, bottom: 4, right: 20),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(28),
                        bottomRight: Radius.circular(28),
                      ),
                    ),
                    child: Button(
                      onPressed: () {
                        if (widget.selected == topic) {
                          widget.onSelected(Topic.all);
                        } else {
                          widget.onSelected(topic);
                        }
                        _controller.reverse();
                        widget.onOpen?.call(false);
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(left: 40.0, right: 13),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                entry.value,
                                style: Theming.of(context).text.body.copyWith(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w500,
                                    color: const Color.fromRGBO(
                                        0xA2, 0xA2, 0xA2, 1.0)),
                              ),
                            ),
                            if (widget.selected == topic)
                              Container(
                                width: 35,
                                height: 35,
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(
                                  color: Color.fromRGBO(0x00, 0x93, 0x4C, 1.0),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.done, size: 32),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBox extends ConsumerStatefulWidget {
  final Topic topic;
  final String? status;
  final Completer<_StatusResult?> resultCompleter;

  const _StatusBox({
    Key? key,
    required this.topic,
    required this.status,
    required this.resultCompleter,
  }) : super(key: key);

  @override
  _StatusBoxState createState() => _StatusBoxState();
}

class _StatusBoxState extends ConsumerState<_StatusBox> {
  final _statusNode = FocusNode();
  final _statusController = TextEditingController();
  bool _posting = false;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    final status = widget.status;
    if (status != null) {
      _statusController.text = status;
    }
    _statusNode.requestFocus();

    _statusController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _statusNode.dispose();
    _statusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 28),
        Text(
          'Create your status',
          style: Theming.of(context).text.body.copyWith(
                color: Colors.black,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
        ),
        Padding(
          padding:
              const EdgeInsets.only(left: 27, right: 27, bottom: 26, top: 10),
          child: Text(
            'Your status will be up for an hour only, during that time anyone can call you.',
            style: Theming.of(context).text.body.copyWith(
                  color: const Color.fromRGBO(0x9E, 0x9E, 0x9E, 1.0),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 44,
                margin: const EdgeInsets.only(left: 19),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(23)),
                  color: Color.fromRGBO(0xE6, 0xE6, 0xE6, 1.0),
                ),
                child: TextField(
                  controller: _statusController,
                  focusNode: _statusNode,
                  keyboardType: TextInputType.text,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _submit(),
                  decoration: InputDecoration.collapsed(
                    hintText: widget.status == null
                        ? 'Why are you here today?'
                        : null,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 4.0, right: 11),
              child: _deleting
                  ? const SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(),
                    )
                  : Button(
                      onPressed:
                          (widget.status == null || _posting) ? null : _delete,
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.delete,
                          color: Color.fromRGBO(0xFF, 0x00, 0x00, 1.0),
                        ),
                      ),
                    ),
            ),
          ],
        ),
        const SizedBox(height: 34),
        Button(
          onPressed: _deleting
              ? null
              : (_statusController.text.isEmpty ? null : _submit),
          child: _posting
              ? const CircularProgressIndicator()
              : Container(
                  width: 153,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(23)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color.fromRGBO(0x00, 0xB0, 0xD5, 1.0),
                        Color.fromRGBO(0x06, 0x5E, 0x71, 1.0),
                      ],
                    ),
                  ),
                  child: Text(
                    'Post your Status',
                    textAlign: TextAlign.center,
                    style: Theming.of(context).text.body.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
        ),
      ],
    );
  }

  void _submit() async {
    setState(() => _posting = true);
    final uid = ref.read(userProvider).uid;
    final status = _statusController.text;
    final api = GetIt.instance.get<Api>();
    if (_statusController.text.isNotEmpty) {
      final result = await api.updateStatus(uid, widget.topic, status);
      if (!mounted) {
        return;
      }
      result.fold(
        (l) {
          displayError(context, l);
          setState(() => _posting = false);
        },
        (r) {
          widget.resultCompleter.complete(_StatusResult(r));
          Navigator.of(context).pop(_StatusResult(r));
        },
      );
    }
  }

  void _delete() async {
    setState(() => _deleting = true);
    final uid = ref.read(userProvider).uid;
    final api = GetIt.instance.get<Api>();
    final result = await api.deleteStatus(uid);
    if (!mounted) {
      return;
    }
    result.fold(
      (l) {
        displayError(context, l);
        setState(() => _deleting = false);
      },
      (_) {
        widget.resultCompleter.complete(_StatusResult(null));
        Navigator.of(context).pop(_StatusResult(null));
      },
    );
  }
}

class _CallBox extends StatefulWidget {
  final TopicParticipant participant;
  const _CallBox({
    Key? key,
    required this.participant,
  }) : super(key: key);

  @override
  State<_CallBox> createState() => _CallBoxState();
}

class _CallBoxState extends State<_CallBox> {
  String? _rid;

  @override
  void initState() {
    super.initState();
    final api = GetIt.instance.get<Api>();
    final resultFuture = api.call(
      widget.participant.uid,
      false,
      group: false,
    );
    resultFuture.then((result) {
      if (!mounted) {
        return;
      }
      result.fold(
        (l) {
          displayError(context, l);
          Navigator.of(context).pop();
        },
        (r) => setState(() => _rid = r),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_rid != null) {
      return _buildCallScreen(
        rid: _rid!,
        profile: SimpleProfile(
          uid: widget.participant.uid,
          name: widget.participant.name,
          photo: widget.participant.photo,
        ),
      );
    }
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.fromRGBO(0x23, 0xE5, 0x36, 1.0),
            Color.fromRGBO(0x0F, 0xA7, 0x1E, 1.0),
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: 12,
            right: 12,
            child: Button(
              onPressed: Navigator.of(context).pop,
              child: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 4.0,
                      offset: Offset(0.0, 4.0),
                      color: Color.fromRGBO(0x00, 0x00, 0x00, 0.25),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.close,
                  color: Color.fromRGBO(0xAE, 0xAE, 0xAE, 1.0),
                  size: 20,
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                'assets/images/call.json',
                fit: BoxFit.contain,
                width: 90,
              ),
              const SizedBox(width: 16),
              AutoSizeText(
                'Calling ${widget.participant.name}',
                minFontSize: 16,
                style: Theming.of(context).text.body.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MiniVoiceCallScreenContent extends ConsumerStatefulWidget {
  final List<UserConnection> users;
  final bool hasSentTimeRequest;
  final DateTime? endTime;
  final bool muted;
  final bool speakerphone;
  final VoidCallback onTimeUp;
  final VoidCallback onHangUp;
  final VoidCallback onSendTimeRequest;
  final void Function(String uid) onConnect;
  final void Function(String uid) onReport;
  final VoidCallback onToggleMute;
  final VoidCallback onToggleSpeakerphone;

  const MiniVoiceCallScreenContent({
    Key? key,
    required this.users,
    required this.hasSentTimeRequest,
    required this.endTime,
    required this.muted,
    required this.speakerphone,
    required this.onTimeUp,
    required this.onHangUp,
    required this.onSendTimeRequest,
    required this.onConnect,
    required this.onReport,
    required this.onToggleMute,
    required this.onToggleSpeakerphone,
  }) : super(key: key);

  @override
  _MiniVoiceCallScreenContentState createState() =>
      _MiniVoiceCallScreenContentState();
}

class _MiniVoiceCallScreenContentState
    extends ConsumerState<MiniVoiceCallScreenContent> {
  bool _showReportUi = false;
  @override
  Widget build(BuildContext context) {
    final tempFirstUser = widget.users.first;
    final profile = tempFirstUser.profile;
    final myProfile = ref.watch(userProvider).profile;

    if (_showReportUi) {
      return _ReportCallBox(
        name: profile.name,
        onReport: () => widget.onReport(profile.uid),
        onCancel: () => setState(() => _showReportUi = false),
      );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, right: 24.0),
          child: Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Button(
                onPressed: widget.onHangUp,
                child: Text(
                  'Leave',
                  style: Theming.of(context).text.body.copyWith(
                      color: const Color.fromRGBO(0xFF, 0x00, 0x00, 1.0),
                      fontSize: 20,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'You are talking to ',
                style: Theming.of(context).text.body.copyWith(
                    color: const Color.fromRGBO(0xB0, 0xB0, 0xB0, 1.0),
                    fontSize: 20,
                    fontWeight: FontWeight.w700),
              ),
              TextSpan(
                text: profile.name,
                style: Theming.of(context).text.body.copyWith(
                    color: const Color.fromRGBO(0x7B, 0x79, 0x79, 1.0),
                    fontSize: 20,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        const SizedBox(height: 11),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              clipBehavior: Clip.hardEdge,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: Image.network(
                myProfile!.photo,
                width: 69,
                height: 69,
                fit: BoxFit.cover,
                frameBuilder: fadeInFrameBuilder,
                loadingBuilder: circularProgressLoadingBuilder,
                errorBuilder: iconErrorBuilder,
              ),
            ),
            const SizedBox(width: 33),
            Column(
              children: [
                const Icon(
                  Icons.access_time_filled,
                  color: Color.fromRGBO(0x7B, 0x7B, 0x7B, 1.0),
                ),
                const SizedBox(height: 6),
                _CountdownTimer(
                  remaining: const Duration(minutes: 5),
                  onTimeUp: widget.onHangUp,
                ),
              ],
            ),
            const SizedBox(width: 33),
            Container(
              clipBehavior: Clip.hardEdge,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(
                  sigmaX: 8.0,
                  sigmaY: 8.0,
                ),
                child: Image.network(
                  profile.photo,
                  width: 69,
                  height: 69,
                  fit: BoxFit.cover,
                  frameBuilder: fadeInFrameBuilder,
                  loadingBuilder: circularProgressLoadingBuilder,
                  errorBuilder: iconErrorBuilder,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 19),
        const Divider(
          color: Color.fromRGBO(0xCA, 0xCA, 0xCA, 1.0),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Button(
              onPressed: () => widget.onConnect(profile.uid),
              child: const Padding(
                padding: EdgeInsets.all(12.0),
                child: Icon(
                  Icons.person_add,
                  color: Color.fromRGBO(0xA8, 0xA8, 0xA8, 1.0),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Button(
              onPressed: () {
                setState(() => _showReportUi = true);
              },
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  'R',
                  style: Theming.of(context).text.body.copyWith(
                      color: const Color.fromRGBO(0xA8, 0xA8, 0xA8, 1.0),
                      fontSize: 27,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Button(
              onPressed: widget.onToggleSpeakerphone,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Icon(
                  Icons.volume_up,
                  color: widget.speakerphone
                      ? const Color.fromRGBO(0x19, 0xC6, 0x2A, 1.0)
                      : const Color.fromRGBO(0xA8, 0xA8, 0xA8, 1.0),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Button(
              onPressed: widget.onToggleMute,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Icon(
                  widget.muted ? Icons.mic_off : Icons.mic,
                  color: const Color.fromRGBO(0xA8, 0xA8, 0xA8, 1.0),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LeaveCallBox extends StatelessWidget {
  const _LeaveCallBox({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 12, top: 16),
            child: Button(
              onPressed: () {},
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(
                  Icons.arrow_back,
                  color: Color.fromRGBO(0xB0, 0xB0, 0xB0, 1.0),
                  size: 32,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(
                  text:
                      'Leaving this call will prevent you from making or taking any calls for',
                  style: Theming.of(context).text.body.copyWith(
                        color: const Color.fromRGBO(0x66, 0x64, 0x64, 1.0),
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                TextSpan(
                  text: ' 5 minutes.\n',
                  style: Theming.of(context).text.body.copyWith(
                        color: const Color.fromRGBO(0xF5, 0x5A, 0x5A, 1.0),
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                TextSpan(
                  text: 'Do you wish to proceed?',
                  style: Theming.of(context).text.body.copyWith(
                        color: const Color.fromRGBO(0x66, 0x64, 0x64, 1.0),
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 31),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Button(
            onPressed: () {},
            child: Text(
              'Leave',
              style: Theming.of(context).text.body.copyWith(
                  color: const Color.fromRGBO(0xFF, 0x00, 0x00, 1.0),
                  fontSize: 20,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReportCallBox extends StatelessWidget {
  final String name;
  final VoidCallback onCancel;
  final VoidCallback onReport;
  const _ReportCallBox({
    Key? key,
    required this.name,
    required this.onReport,
    required this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        onCancel();
        return Future.value(false);
      },
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 12, top: 16),
              child: Button(
                onPressed: onCancel,
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(
                    Icons.arrow_back,
                    color: Color.fromRGBO(0xB0, 0xB0, 0xB0, 1.0),
                    size: 32,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'End call and',
                    style: Theming.of(context).text.body.copyWith(
                          color: const Color.fromRGBO(0x66, 0x64, 0x64, 1.0),
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  TextSpan(
                    text: ' report.\n',
                    style: Theming.of(context).text.body.copyWith(
                          color: const Color.fromRGBO(0xF5, 0x5A, 0x5A, 1.0),
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  TextSpan(
                    text: name,
                    style: Theming.of(context).text.body.copyWith(
                          color: const Color.fromRGBO(0x66, 0x64, 0x64, 1.0),
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 31),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Button(
                  onPressed: onCancel,
                  child: Text(
                    'No',
                    style: Theming.of(context).text.body.copyWith(
                        color: const Color.fromRGBO(0x82, 0x81, 0x81, 1.0),
                        fontSize: 20,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Button(
                  onPressed: onReport,
                  child: Text(
                    'Yes',
                    style: Theming.of(context).text.body.copyWith(
                        color: const Color.fromRGBO(0xFF, 0x00, 0x00, 1.0),
                        fontSize: 20,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Widget _buildCallScreen({
  required String rid,
  required SimpleProfile profile,
}) {
  return CallScreen(
    rid: rid,
    host: host,
    socketPort: socketPort,
    video: false,
    mini: true,
    serious: true,
    profiles: [profile],
    rekindles: const [],
    groupLobby: false,
  );
}

class _StatusResult {
  final Status? status;

  _StatusResult(this.status);
}
