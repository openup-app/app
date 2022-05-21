import 'dart:async';
import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:list_diff/list_diff.dart';
import 'package:lottie/lottie.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/call_state.dart';
import 'package:openup/api/signaling/phone.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/api/users/profile.dart';
import 'package:openup/call_screen.dart';
import 'package:openup/notifications/ios_voip_handlers.dart' as ios_voip;
import 'package:openup/report_screen.dart';
import 'package:openup/util/us_locations.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/icon_with_shadow.dart';
import 'package:openup/widgets/image_builder.dart';
import 'package:openup/widgets/profile_button.dart';
import 'package:openup/widgets/theming.dart';
import 'package:tuple/tuple.dart';

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
  String _state = 'Texas';
  String _city = 'Houston';
  bool _stateExpanded = false;
  bool _cityExpanded = false;

  bool _loading = false;
  Status? _status;
  var _topicStatuses = <Tuple2<Topic, List<TopicParticipant>>>[];
  late final Timer _refreshTimer;
  int _userCount = 0;

  final _listKeys = Map.fromEntries(
      Topic.values.map((e) => MapEntry(e, GlobalKey<AnimatedListState>())));

  StreamSubscription? _phoneStateSubscription;

  @override
  void initState() {
    super.initState();
    setState(() => _loading = true);
    final isIOS = Platform.isIOS;
    Future.wait([
      FirebaseMessaging.instance.getToken(),
      if (isIOS) ios_voip.getVoipPushNotificationToken(),
    ]).then((tokens) {
      if (!mounted) {
        return;
      }
      final api = GetIt.instance.get<Api>();
      api.addNotificationTokens(
        ref.read(userProvider).uid,
        fcmMessagingAndVoipToken: isIOS ? null : tokens[0],
        fcmMessagingToken: isIOS ? tokens[0] : null,
        apnVoipToken: isIOS ? tokens[1] : null,
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
      const Duration(seconds: 15),
      (_) async {
        if (mounted) {
          await _fetchParticipants();
        }
      },
    );

    final callInfoStream = GetIt.instance.get<CallState>().callInfoStream;
    callInfoStream.listen(_onCallInfo);
  }

  void _onCallInfo(CallInfo callInfo) {
    callInfo.map(
      active: (activeCall) {
        WidgetsBinding.instance?.scheduleFrameCallback((_) {
          _showPanel(
            builder: (context) {
              return CallPanel(
                activeCall: activeCall,
                onCallEnded: (reason) =>
                    _onCallEnded(activeCall.profile.uid, reason),
                rekindles: const [],
              );
            },
          );
        });
      },
      none: (_) {},
    );
  }

  /// Join a call from a notification
  void joinCall(StartWithCall startWithCall) {
    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(
    //     content: Text('Joining: ${startWithCall.rid}'),
    //   ),
    // );
    // WidgetsBinding.instance?.scheduleFrameCallback((_) {
    //   _showPanel(
    //     builder: (context) {
    //       return _buildCallScreen(
    //         rid: startWithCall.rid,
    //         profile: startWithCall.profile,
    //         isInitiator: false,
    //         onCallEnded: (reason) =>
    //             _onCallEnded(startWithCall.profile.uid, reason),
    //       );
    //     },
    //   );
    // });
  }

  @override
  void dispose() {
    super.dispose();
    _phoneStateSubscription?.cancel();
    _refreshTimer.cancel();
  }

  Future<void> _fetchParticipants() async {
    final myUid = ref.read(userProvider).uid;
    final api = GetIt.instance.get<Api>();
    final topicParticipants = await api.getStatuses(myUid, _state, _city);
    if (mounted) {
      topicParticipants.fold(
        (l) {
          var message = errorToMessage(l);
          message = l.when(
            network: (_) => message,
            client: (client) => client.when(
              badRequest: () => 'Failed to get users',
              unauthorized: () => message,
              notFound: () => 'Unable to find statuses',
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
          final topicStatuses = <Tuple2<Topic, List<TopicParticipant>>>[];
          for (final entry in r.entries) {
            topicStatuses.add(Tuple2(entry.key, entry.value));
          }

          for (final tuple in topicStatuses) {
            tuple.item2.removeWhere((e) => e.uid == myUid);
            tuple.item2.sort((a, b) => a.name.compareTo(b.name));
          }
          topicStatuses.removeWhere((tuple) => tuple.item2.isEmpty);
          topicStatuses
              .sort((a, b) => b.item2.length.compareTo(a.item2.length));

          for (final tuple in topicStatuses) {
            final topic = tuple.item1;
            final participants = tuple.item2;
            final topicStatuses = _topicStatuses.firstWhere(
              (e) => e.item1 == topic,
              orElse: () => Tuple2(topic, []),
            );
            final differences = await diff(
              topicStatuses.item2,
              participants,
              areEqual: (a, b) {
                return (a as TopicParticipant).name ==
                    (b as TopicParticipant).name;
              },
              getHashCode: (a) => a.hashCode,
            );
            for (final difference in differences) {
              _performDiff(topic, difference);
            }
          }

          setState(() {
            _userCount =
                topicStatuses.fold<int>(0, (p, e) => p + e.item2.length);
            _topicStatuses = topicStatuses;
          });
        },
      );
    }
  }

  void _performDiff(Topic topic, Operation<TopicParticipant> d) {
    switch (d.type) {
      case OperationType.insertion:
        _listKeys[topic]?.currentState?.insertItem(
              d.index,
              duration: const Duration(milliseconds: 400),
            );
        break;
      case OperationType.deletion:
        _listKeys[topic]?.currentState?.removeItem(
              d.index,
              (c, a) => _animatedRemoveBuilder(c, a, d.item),
              duration: const Duration(milliseconds: 400),
            );
        break;
    }
  }

  Widget _animatedRemoveBuilder(
    BuildContext context,
    Animation<double> animation,
    TopicParticipant participant,
  ) {
    return FadeTransition(
      opacity: animation,
      child: SizeTransition(
        axis: Axis.horizontal,
        sizeFactor: CurveTween(curve: Curves.easeIn).animate(animation),
        child: _ParticipantTile(
          participant: participant,
          onPressed: () {
            // Nothing to do
          },
          onBlock: () {
            // Nothing to do
          },
        ),
      ),
    );
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
    return WillPopScope(
      onWillPop: () {
        if (_stateExpanded || _cityExpanded) {
          setState(() {
            _stateExpanded = false;
            _cityExpanded = false;
          });
          return Future.value(false);
        }
        return Future.value(true);
      },
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromRGBO(0x2B, 0x86, 0xA2, 1.0),
              Color.fromRGBO(0xA3, 0xCB, 0xD8, 1.0),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 152),
                child: Column(
                  children: [
                    if (_loading)
                      const Expanded(
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    if (!_loading && _topicStatuses.isEmpty)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(
                              left: 16.0, top: 16, right: 16, bottom: 72),
                          child: Center(
                            child: Text(
                              'No one is available to chat,\ncreate a status to be the first!',
                              textAlign: TextAlign.center,
                              style: Theming.of(context).text.body.copyWith(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                            ),
                          ),
                        ),
                      ),
                    if (!_loading && _topicStatuses.isNotEmpty)
                      Expanded(
                        child: ListView.builder(
                          itemCount: _topicStatuses.length,
                          padding: const EdgeInsets.only(top: 16, bottom: 76),
                          itemBuilder: (context, index) {
                            final topic = _topicStatuses[index].item1;
                            final participants = _topicStatuses[index].item2;
                            // Only possible to occur when just blocked a user
                            if (participants.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 16.0, bottom: 8),
                                  child: Text(
                                    _topicToTitle(topic),
                                    style:
                                        Theming.of(context).text.body.copyWith(
                                      fontSize: 26,
                                      shadows: [
                                        const Shadow(
                                          blurRadius: 8,
                                          color: Color.fromRGBO(
                                              0x00, 0x00, 0x00, 0.25),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(left: 16.0),
                                  child: Text(
                                    _topicToDescription(topic),
                                    style:
                                        Theming.of(context).text.body.copyWith(
                                      fontSize: 18,
                                      shadows: [
                                        const Shadow(
                                          blurRadius: 8,
                                          color: Color.fromRGBO(
                                              0x00, 0x00, 0x00, 0.25),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: 300,
                                  child: AnimatedList(
                                    key: _listKeys[topic],
                                    padding: const EdgeInsets.only(left: 8),
                                    scrollDirection: Axis.horizontal,
                                    initialItemCount: participants.length,
                                    itemBuilder: (context, index, animation) {
                                      final participant = participants[index];
                                      return FadeTransition(
                                        opacity: animation,
                                        child: SizeTransition(
                                          axis: Axis.horizontal,
                                          sizeFactor:
                                              CurveTween(curve: Curves.easeOut)
                                                  .animate(animation),
                                          child: _ParticipantTile(
                                            participant: participant,
                                            onPressed: () {
                                              showDialog(
                                                context: context,
                                                builder: (context) {
                                                  return Dialog(
                                                    clipBehavior: Clip.none,
                                                    backgroundColor:
                                                        Colors.transparent,
                                                    insetPadding:
                                                        EdgeInsets.zero,
                                                    child: SizedBox(
                                                      width: 355,
                                                      height: 491,
                                                      child:
                                                          _ParticipantCallTile(
                                                        participant:
                                                            participant,
                                                        onCall: () {
                                                          Navigator.of(context)
                                                              .pop();
                                                          _call(participant);
                                                        },
                                                        onBlock: () {
                                                          Navigator.of(context)
                                                              .pop();
                                                          final item =
                                                              participants
                                                                  .removeAt(
                                                                      index);
                                                          setState(() {});
                                                          _listKeys[topic]
                                                              ?.currentState
                                                              ?.removeItem(
                                                                index,
                                                                (c, a) =>
                                                                    _animatedRemoveBuilder(
                                                                        c,
                                                                        a,
                                                                        item),
                                                                duration:
                                                                    const Duration(
                                                                        milliseconds:
                                                                            400),
                                                              );
                                                        },
                                                      ),
                                                    ),
                                                  );
                                                },
                                              );
                                            },
                                            onBlock: () {
                                              Navigator.of(context).pop();
                                              final item =
                                                  participants.removeAt(index);
                                              setState(() {});
                                              _listKeys[topic]
                                                  ?.currentState
                                                  ?.removeItem(
                                                    index,
                                                    (c, a) =>
                                                        _animatedRemoveBuilder(
                                                            c, a, item),
                                                    duration: const Duration(
                                                        milliseconds: 400),
                                                  );
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
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
                  GestureDetector(
                    onTap: _loading
                        ? null
                        : () async {
                            final completer = Completer<_StatusResult?>();
                            // Bug in Flutter not letting showBottomPanel return a result: https://github.com/flutter/flutter/issues/66837
                            await _showPanel<_StatusResult>(
                              builder: (context) {
                                return _StatusBox(
                                  state: _state,
                                  city: _city,
                                  status: _status?.text,
                                  topic: _status?.topic,
                                  resultCompleter: completer,
                                );
                              },
                            );

                            if (completer.isCompleted) {
                              final result = await completer.future;
                              setState(() => _status = result?.status);
                            }
                          },
                    child: Container(
                      height: 54,
                      margin: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.all(
                          Radius.circular(34.5),
                        ),
                        color: Color.fromRGBO(0xE6, 0xE6, 0xE6, 1.0),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 7,
                            offset: Offset(0.0, 2.0),
                            color: Color.fromRGBO(0x00, 0x00, 0x00, 0.25),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _status?.text ?? 'Why are you here today?',
                              textAlign: _status == null
                                  ? TextAlign.center
                                  : TextAlign.start,
                              overflow: TextOverflow.ellipsis,
                              style: Theming.of(context).text.body.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w300,
                                  color: const Color.fromRGBO(
                                      0x7B, 0x7B, 0x7B, 1.0)),
                            ),
                          ),
                          if (_status != null) ...[
                            const Icon(
                              Icons.access_time_filled,
                              color: Color.fromRGBO(0x7B, 0x7B, 0x7B, 1.0),
                            ),
                            const SizedBox(width: 4),
                            _CountdownTimer(
                              key: Key(_status?.text ?? ''),
                              endTime: _status!.endTime,
                              onTimeUp: () {
                                if (mounted) {
                                  setState(() => _status = null);
                                }
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            if (_stateExpanded || _cityExpanded)
              Positioned.fill(
                child: GestureDetector(
                  onPanDown: (_) {
                    setState(() {
                      _stateExpanded = false;
                      _cityExpanded = false;
                    });
                  },
                  child: Container(color: Colors.transparent),
                ),
              ),
            Positioned(
              right: 16,
              height: 50,
              top: MediaQuery.of(context).padding.top + 16 + 8 + 68,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 210),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$_city, $_state',
                      overflow: TextOverflow.ellipsis,
                      style: Theming.of(context)
                          .text
                          .body
                          .copyWith(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'People Available : ',
                            style: Theming.of(context).text.body.copyWith(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                          TextSpan(
                            text: _loading ? '' : _userCount.toString(),
                            style: Theming.of(context).text.body.copyWith(
                                fontSize: 17,
                                fontWeight: FontWeight.w500,
                                color: const Color.fromRGBO(
                                    0x00, 0xFF, 0x47, 1.0)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              key: const Key('city_selector'),
              left: 0,
              top: MediaQuery.of(context).padding.top + 16 + 8 + 60,
              child: _Selector(
                label: 'Which City?',
                width: !_cityExpanded ? 164 : null,
                open: _cityExpanded,
                items: usLocations[_state]!,
                selected: _city,
                onSelected: (index) async {
                  setState(() {
                    _city = usLocations[_state]![index];
                    _loading = true;
                  });
                  await _fetchParticipants();
                  if (mounted) {
                    setState(() => _loading = false);
                  }
                },
                onOpen: _loading
                    ? null
                    : (open) {
                        setState(() {
                          _cityExpanded = open;
                          _stateExpanded = false;
                        });
                      },
              ),
            ),
            Positioned(
              key: const Key('state_selector'),
              left: 0,
              top: MediaQuery.of(context).padding.top + 16,
              child: _Selector(
                label: 'Which State would you like to see and be at?',
                open: _stateExpanded,
                items: usLocations.keys.toList(),
                selected: _state,
                onSelected: (index) async {
                  setState(() {
                    _state = usLocations.keys.toList()[index];
                    _city = usLocations[_state]!.first;
                    _loading = true;
                  });
                  await _fetchParticipants();
                  if (mounted) {
                    setState(() => _loading = false);
                  }
                },
                onOpen: _loading
                    ? null
                    : (open) {
                        setState(() {
                          _stateExpanded = open;
                          _cityExpanded = false;
                        });
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _call(TopicParticipant participant) {
    _showPanel(
      dragIndicatorColor: Colors.white,
      builder: (context) {
        return _RingingBox(
          participant: participant,
          onCallEnded: (reason) => _onCallEnded(participant.uid, reason),
        );
      },
    );
  }

  void _onCallEnded(String uid, EndCallReason reason) {
    switch (reason) {
      case EndCallReason.timeUp:
        // Panel will pop itself after timer
        break;
      case EndCallReason.hangUp:
        Navigator.of(context).pop();
        break;
      case EndCallReason.report:
        Navigator.of(context).pop();
        Navigator.of(context).pushNamed(
          'call-report',
          arguments: ReportScreenArguments(uid: uid),
        );
        break;
      case EndCallReason.remoteHangUpOrDisconnect:
        // Panel will pop itself after timer
        break;
    }
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
  final DateTime endTime;
  final VoidCallback onTimeUp;
  final TextStyle? style;
  const _CountdownTimer({
    Key? key,
    required this.endTime,
    required this.onTimeUp,
    this.style,
  }) : super(key: key);

  @override
  State<_CountdownTimer> createState() => __CountdownTimerState();
}

class __CountdownTimerState extends State<_CountdownTimer> {
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
    if (oldWidget.endTime != widget.endTime) {
      _restart();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _restart() {
    _update();
    _startPeriodicTimer();
  }

  void _startPeriodicTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _update(),
    );
  }

  void _update() {
    final remaining = widget.endTime.difference(DateTime.now());
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

  String _formatDuration(Duration d) {
    if (d.inHours > 1) {
      return '${(d.inHours % 24).toString().padLeft(2, '0')}:${(d.inMinutes % 60).toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
    }
    return '${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _formatDuration(_remaining),
      style: widget.style ??
          Theming.of(context).text.body.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w300,
              color: const Color.fromRGBO(0x7B, 0x7B, 0x7B, 1.0)),
    );
  }
}

class _ParticipantTile extends StatelessWidget {
  final TopicParticipant participant;
  final VoidCallback onPressed;
  final VoidCallback onBlock;
  const _ParticipantTile({
    Key? key,
    required this.participant,
    required this.onPressed,
    required this.onBlock,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 223,
      height: 267,
      margin: const EdgeInsets.only(left: 8, right: 8, top: 12, bottom: 24),
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(20)),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: Offset(0.0, 4.0),
            color: Color.fromRGBO(0x00, 0x00, 0x00, 0.25),
          ),
        ],
      ),
      child: Button(
        onPressed: onPressed,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    participant.photo,
                    fit: BoxFit.cover,
                    frameBuilder: fadeInFrameBuilder,
                    loadingBuilder: circularProgressLoadingBuilder,
                    errorBuilder: iconErrorBuilder,
                  ),
                  Positioned(
                    left: 17,
                    top: 12,
                    width: 200,
                    child: AutoSizeText(
                      participant.name,
                      style: Theming.of(context).text.body.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w300,
                        shadows: [
                          const Shadow(
                            blurRadius: 8,
                            color: Color.fromRGBO(0x00, 0x00, 0x00, 0.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    top: 0,
                    child: _ReportBlockPopupMenu(
                      uid: participant.uid,
                      name: participant.name,
                      onBlock: onBlock,
                    ),
                  ),
                  Positioned(
                    right: 17,
                    bottom: 8,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.access_time_filled,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        _CountdownTimer(
                          endTime: participant.endTime,
                          onTimeUp: () {},
                          style: Theming.of(context).text.body.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w300,
                            shadows: [
                              const Shadow(
                                blurRadius: 8,
                                color: Color.fromRGBO(0x00, 0x00, 0x00, 0.5),
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
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                children: [
                  Text(
                    participant.statusText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theming.of(context).text.body.copyWith(
                        fontSize: 15,
                        color: Colors.black,
                        fontWeight: FontWeight.w300),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParticipantCallTile extends StatelessWidget {
  final TopicParticipant participant;
  final VoidCallback onCall;
  final VoidCallback onBlock;
  const _ParticipantCallTile({
    Key? key,
    required this.participant,
    required this.onCall,
    required this.onBlock,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(20)),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: Offset(0.0, 4.0),
            color: Color.fromRGBO(0x00, 0x00, 0x00, 0.25),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  participant.photo,
                  fit: BoxFit.cover,
                  frameBuilder: fadeInFrameBuilder,
                  loadingBuilder: circularProgressLoadingBuilder,
                  errorBuilder: iconErrorBuilder,
                ),
                Positioned(
                  left: 16,
                  top: 10,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AutoSizeText(
                        participant.name,
                        style: Theming.of(context).text.body.copyWith(
                          fontSize: 32,
                          fontWeight: FontWeight.w300,
                          shadows: [
                            const Shadow(
                              blurRadius: 8,
                              color: Color.fromRGBO(0x00, 0x00, 0x00, 0.5),
                            ),
                          ],
                        ),
                      ),
                      for (var interest
                          in participant.interests
                            ..sort((a, b) => a.compareTo(b)))
                        Text(
                          interest,
                          style: Theming.of(context).text.body.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w300,
                            shadows: [
                              const Shadow(
                                blurRadius: 8,
                                color: Color.fromRGBO(0x00, 0x00, 0x00, 0.5),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: _ReportBlockPopupMenu(
                      uid: participant.uid,
                      name: participant.name,
                      onBlock: () {
                        Navigator.of(context).pop();
                        onBlock();
                      }),
                ),
                Positioned(
                  right: 17,
                  bottom: 8,
                  child: _CountdownTimer(
                    endTime: participant.endTime,
                    onTimeUp: () {},
                    style: Theming.of(context).text.body.copyWith(
                      fontSize: 32,
                      fontWeight: FontWeight.w300,
                      shadows: [
                        const Shadow(
                          blurRadius: 8,
                          color: Color.fromRGBO(0x00, 0x00, 0x00, 0.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Text(
              participant.statusText,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theming.of(context).text.body.copyWith(
                  fontSize: 15,
                  color: Colors.black,
                  fontWeight: FontWeight.w300),
            ),
          ),
          Button(
            onPressed: onCall,
            child: Container(
              height: 69,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color.fromRGBO(0x26, 0xEF, 0x3A, 1.0),
                    Color.fromRGBO(0x0A, 0x98, 0x18, 1.0),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Lottie.asset(
                      'assets/images/call.json',
                      fit: BoxFit.contain,
                      width: 30,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'call',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theming.of(context)
                          .text
                          .body
                          .copyWith(fontSize: 18, fontWeight: FontWeight.w300),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportBlockPopupMenu extends ConsumerWidget {
  final String uid;
  final String name;
  final VoidCallback onBlock;
  const _ReportBlockPopupMenu({
    Key? key,
    required this.uid,
    required this.name,
    required this.onBlock,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton(
      icon: const IconWithShadow(Icons.more_horiz),
      onSelected: (value) {
        if (value == 'block') {
          showDialog(
            context: context,
            builder: (context) {
              return CupertinoTheme(
                data: const CupertinoThemeData(brightness: Brightness.dark),
                child: CupertinoAlertDialog(
                  title: Text('Block $name?'),
                  content: Text(
                      '$name will be unable to see or call you, and you will not be able to see or call $name.'),
                  actions: [
                    CupertinoDialogAction(
                      onPressed: Navigator.of(context).pop,
                      child: const Text('Cancel'),
                    ),
                    CupertinoDialogAction(
                      onPressed: () async {
                        final myUid = ref.read(userProvider).uid;
                        final api = GetIt.instance.get<Api>();
                        await api.blockUser(myUid, uid);
                        onBlock();
                      },
                      isDestructiveAction: true,
                      child: const Text('Block'),
                    ),
                  ],
                ),
              );
            },
          );
        } else if (value == 'report') {
          Navigator.of(context).pushNamed(
            'call-report',
            arguments: ReportScreenArguments(uid: uid),
          );
        }
      },
      itemBuilder: (context) {
        return [
          const PopupMenuItem(
            child: ListTile(
              title: Text('Block user'),
              trailing: Icon(Icons.block),
              contentPadding: EdgeInsets.zero,
            ),
            value: 'block',
          ),
          const PopupMenuItem(
            child: ListTile(
              title: Text('Report user'),
              trailing: Icon(Icons.flag_outlined),
              contentPadding: EdgeInsets.zero,
            ),
            value: 'report',
          ),
        ];
      },
    );
  }
}

/*
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
                        ),*/
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
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.w300,
            shadows: [
              const Shadow(
                blurRadius: 8,
                color: Color.fromRGBO(0x00, 0x00, 0x00, 0.5),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _Selector extends StatefulWidget {
  final String label;
  final double? width;
  final bool open;
  final List<String> items;
  final String selected;
  final void Function(int index) onSelected;
  final void Function(bool open)? onOpen;

  const _Selector({
    Key? key,
    required this.label,
    this.width,
    required this.open,
    required this.items,
    required this.selected,
    required this.onSelected,
    required this.onOpen,
  }) : super(key: key);

  @override
  State<_Selector> createState() => _SelectorState();
}

class _SelectorState extends State<_Selector>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final _scrollController = ScrollController();

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
  void didUpdateWidget(covariant _Selector oldWidget) {
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
      width: widget.width ?? 280,
      alignment: Alignment.center,
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(
        color: Colors.white,
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
                padding: const EdgeInsets.only(left: 24, right: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theming.of(context).text.body.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w300,
                            color: const Color.fromRGBO(0x34, 0x34, 0x34, 1.0)),
                      ),
                    ),
                    const Icon(
                      Icons.location_pin,
                      color: Color.fromRGBO(0xFF, 0x00, 0x00, 1.0),
                      size: 42,
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
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 224),
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: MediaQuery.removePadding(
                    context: context,
                    removeTop: true,
                    child: Scrollbar(
                      controller: _scrollController,
                      isAlwaysShown: true,
                      trackVisibility: true,
                      thickness: 8,
                      radius: const Radius.circular(4),
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: widget.items.length,
                        itemBuilder: (context, index) {
                          final item = widget.items[index];
                          return Container(
                            height: 32,
                            margin: const EdgeInsets.only(right: 20),
                            child: Button(
                              onPressed: () {
                                widget.onSelected(index);
                                _controller.reverse();
                                widget.onOpen?.call(false);
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    left: 40.0, right: 13),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theming.of(context)
                                            .text
                                            .body
                                            .copyWith(
                                                fontSize: 18,
                                                fontWeight:
                                                    widget.selected == item
                                                        ? FontWeight.w700
                                                        : FontWeight.w500,
                                                color: widget.selected == item
                                                    ? Colors.black
                                                    : const Color.fromRGBO(
                                                        0x7B, 0x7B, 0x7B, 1.0)),
                                      ),
                                    ),
                                    Text(
                                      '',
                                      textAlign: TextAlign.right,
                                      style: Theming.of(context)
                                          .text
                                          .body
                                          .copyWith(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w500,
                                              color: const Color.fromRGBO(
                                                  0x00, 0xC2, 0x36, 1.0)),
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
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBox extends ConsumerStatefulWidget {
  final String state;
  final String city;
  final String? status;
  final Topic? topic;
  final Completer<_StatusResult?> resultCompleter;

  const _StatusBox({
    Key? key,
    required this.state,
    required this.city,
    this.status,
    this.topic,
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

  bool _page2 = false;
  late Topic _topic;

  @override
  void initState() {
    super.initState();
    final status = widget.status;
    _topic = widget.topic ?? Topic.moved;
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
    if (!_page2) {
      return Column(
        children: [
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: Text(
              'Create your status',
              style: Theming.of(context).text.body.copyWith(
                    color: Colors.black,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.only(left: 27, right: 27, bottom: 26, top: 10),
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Your status will be up for an',
                    style: Theming.of(context).text.body.copyWith(
                        color: const Color.fromRGBO(0x69, 0x69, 0x69, 1.0),
                        fontSize: 15,
                        fontWeight: FontWeight.w500),
                  ),
                  TextSpan(
                    text: ' hour ',
                    style: Theming.of(context).text.body.copyWith(
                        color: const Color.fromRGBO(0xFF, 0x00, 0x00, 1.0),
                        fontSize: 15,
                        fontWeight: FontWeight.w500),
                  ),
                  TextSpan(
                    text:
                        'only, during that time anyone can call you. Without a status you will not recieve any calls.',
                    style: Theming.of(context).text.body.copyWith(
                        color: const Color.fromRGBO(0x69, 0x69, 0x69, 1.0),
                        fontSize: 15,
                        fontWeight: FontWeight.w500),
                  ),
                ],
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
                    onSubmitted: _statusController.text.isEmpty || _deleting
                        ? null
                        : (_) => setState(() => _page2 = true),
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
                        onPressed: (widget.status == null || _posting)
                            ? null
                            : _delete,
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
          const SizedBox(height: 26),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Button(
                onPressed: _statusController.text.isEmpty || _deleting
                    ? null
                    : () => setState(() => _page2 = true),
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(
                    Icons.arrow_forward,
                    color: Color.fromRGBO(0xB0, 0xB0, 0xB0, 1.0),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      return WillPopScope(
        onWillPop: () {
          if (!_posting) {
            setState(() => _page2 = false);
          }
          return Future.value(false);
        },
        child: Column(
          children: [
            const SizedBox(height: 28),
            Stack(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: Button(
                      onPressed: _posting
                          ? null
                          : () => setState(() => _page2 = false),
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.arrow_back,
                          color: Color.fromRGBO(0xB0, 0xB0, 0xB0, 1.0),
                        ),
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Pick a category',
                      style: Theming.of(context).text.body.copyWith(
                            color: Colors.black,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(
                  left: 27, right: 27, bottom: 4, top: 10),
              child: Text(
                'Categories let others know why you’re here and will make it easier to meet those with similarities in ${widget.city}.',
                style: Theming.of(context).text.body.copyWith(
                    color: const Color.fromRGBO(0x69, 0x69, 0x69, 1.0),
                    fontSize: 15,
                    fontWeight: FontWeight.w500),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CheckboxTile(
                        label: _topicToTitle(Topic.moved),
                        value: _topic == Topic.moved,
                        onChanged: (_) => setState(() => _topic = Topic.moved),
                      ),
                      CheckboxTile(
                        label: _topicToTitle(Topic.outing),
                        value: _topic == Topic.outing,
                        onChanged: (_) => setState(() => _topic = Topic.outing),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CheckboxTile(
                        label: _topicToTitle(Topic.vacation),
                        value: _topic == Topic.vacation,
                        onChanged: (_) =>
                            setState(() => _topic = Topic.vacation),
                      ),
                      CheckboxTile(
                        label: _topicToTitle(Topic.business),
                        value: _topic == Topic.business,
                        onChanged: (_) =>
                            setState(() => _topic = Topic.business),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CheckboxTile(
                        label: _topicToTitle(Topic.school),
                        value: _topic == Topic.school,
                        onChanged: (_) => setState(() => _topic = Topic.school),
                      ),
                      CheckboxTile(
                        label: _topicToTitle(Topic.friends),
                        value: _topic == Topic.friends,
                        onChanged: (_) =>
                            setState(() => _topic = Topic.friends),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
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
        ),
      );
    }
  }

  void _submit() async {
    setState(() => _posting = true);
    final uid = ref.read(userProvider).uid;
    final status = _statusController.text;
    final api = GetIt.instance.get<Api>();
    if (_statusController.text.isNotEmpty) {
      final result = await api.updateStatus(
          uid, widget.state, widget.city, _topic, status);
      if (!mounted) {
        return;
      }
      result.fold(
        (l) {
          displayError(context, l);
          setState(() => _posting = false);
        },
        (r) {
          print('updated to $r');
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

class CheckboxTile extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged onChanged;
  const CheckboxTile({
    Key? key,
    required this.label,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Button(
      onPressed: () => onChanged(true),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomPaint(
              painter: _CheckboxPainter(value),
              size: const Size(20, 20),
            ),
            const SizedBox(width: 13),
            Text(
              label,
              style: Theming.of(context).text.body.copyWith(
                  color: Colors.black,
                  fontSize: 15,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckboxPainter extends CustomPainter {
  final bool value;

  _CheckboxPainter(this.value);

  @override
  void paint(Canvas canvas, Size size) {
    if (value) {
      canvas.drawCircle(
        size.center(Offset.zero),
        10,
        Paint()..color = const Color.fromRGBO(0x0B, 0xFF, 0x6C, 1.0),
      );
    }
    canvas.drawCircle(
      size.center(Offset.zero),
      10,
      Paint()
        ..color = const Color.fromRGBO(0x8B, 0x8B, 0x8B, 1.0)
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_CheckboxPainter oldDelegate) => false;

  @override
  bool shouldRebuildSemantics(_CheckboxPainter oldDelegate) => false;
}

class _RingingBox extends ConsumerStatefulWidget {
  final TopicParticipant participant;
  final void Function(EndCallReason reason) onCallEnded;

  const _RingingBox({
    Key? key,
    required this.participant,
    required this.onCallEnded,
  }) : super(key: key);

  @override
  _RingingBoxState createState() => _RingingBoxState();
}

class _RingingBoxState extends ConsumerState<_RingingBox> {
  ActiveCall? _activeCall;
  bool _callEngaged = false;

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
          if (l is ApiClientError && l.error is ClientErrorConflict) {
            setState(() => _callEngaged = true);
            Future.delayed(const Duration(seconds: 4)).whenComplete(() {
              if (mounted) {
                Navigator.of(context).pop();
              }
            });
            return;
          }
          var message = errorToMessage(l);
          message = l.when(
            network: (_) => message,
            client: (client) => client.when(
              badRequest: () => 'Failed to get users',
              unauthorized: () => message,
              notFound: () => 'Unable to find topic participants',
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
          Navigator.of(context).pop();
        },
        (rid) {
          final uid = ref.read(userProvider).uid;
          ActiveCall? activeCall;
          if (Platform.isAndroid) {
            throw UnimplementedError();
          } else if (Platform.isIOS) {
            activeCall = ios_voip.createActiveCall(
              uid,
              rid,
              SimpleProfile(
                uid: widget.participant.uid,
                name: widget.participant.name,
                photo: widget.participant.photo,
              ),
            );
          }
          if (activeCall != null) {
            setState(() => _activeCall = activeCall);
          }
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeCall = _activeCall;
    if (activeCall != null) {
      return CallPanel(
        activeCall: activeCall,
        onCallEnded: widget.onCallEnded,
        rekindles: const [],
      );
    }
    if (_callEngaged) {
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(
              '${widget.participant.name} is already in a call',
              style: Theming.of(context).text.body.copyWith(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700),
            ),
            Button(
              onPressed: Navigator.of(context).pop,
              child: Text(
                'OK',
                style: Theming.of(context).text.body.copyWith(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
    }
    return _RingingUi(
      name: widget.participant.name,
      animate: false,
      onClose: Navigator.of(context).pop,
    );
  }
}

class _RingingUi extends StatelessWidget {
  final String name;
  final bool animate;
  final VoidCallback onClose;

  const _RingingUi({
    Key? key,
    required this.name,
    this.animate = true,
    required this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
              onPressed: onClose,
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
                animate: animate,
                width: 90,
              ),
              const SizedBox(width: 16),
              AutoSizeText(
                'Calling $name',
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
  final bool isInitiator;
  final bool hasSentTimeRequest;
  final DateTime? endTime;
  final bool muted;
  final bool speakerphone;
  final VoidCallback onTimeUp;
  final VoidCallback onHangUp;
  final VoidCallback onSendTimeRequest;
  final void Function(String uid) onConnect;
  final void Function(String uid) onReport;
  final ValueChanged onMuteChanged;
  final ValueChanged onSpeakerphoneChanged;

  const MiniVoiceCallScreenContent({
    Key? key,
    required this.users,
    required this.isInitiator,
    required this.hasSentTimeRequest,
    required this.endTime,
    required this.muted,
    required this.speakerphone,
    required this.onTimeUp,
    required this.onHangUp,
    required this.onSendTimeRequest,
    required this.onConnect,
    required this.onReport,
    required this.onMuteChanged,
    required this.onSpeakerphoneChanged,
  }) : super(key: key);

  @override
  _MiniVoiceCallScreenContentState createState() =>
      _MiniVoiceCallScreenContentState();
}

class _MiniVoiceCallScreenContentState
    extends ConsumerState<MiniVoiceCallScreenContent> {
  bool _showReportUi = false;

  DateTime _endTime = DateTime.now().add(const Duration(minutes: 5));
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _updateConnectionState(widget.users.first.connectionState);
  }

  @override
  void didUpdateWidget(covariant MiniVoiceCallScreenContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.users.first.connectionState !=
        oldWidget.users.first.connectionState) {
      _updateConnectionState(widget.users.first.connectionState);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateConnectionState(PhoneConnectionState state) {
    if (state == PhoneConnectionState.declined ||
        state == PhoneConnectionState.complete ||
        state == PhoneConnectionState.missing) {
      _timer?.cancel();
      _timer = Timer(
        const Duration(seconds: 2),
        () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        },
      );
    }

    if (state == PhoneConnectionState.connected) {
      _endTime = DateTime.now().add(const Duration(minutes: 5));
    }
  }

  @override
  Widget build(BuildContext context) {
    final firstUser = widget.users.first;
    final profile = firstUser.profile;
    final myProfile = ref.watch(userProvider).profile;

    if (_showReportUi) {
      return _ReportCallBox(
        name: profile.name,
        onReport: () => widget.onReport(profile.uid),
        onCancel: () => setState(() => _showReportUi = false),
      );
    }

    final state = firstUser.connectionState;
    if (widget.isInitiator &&
        (state == PhoneConnectionState.none ||
            state == PhoneConnectionState.waiting)) {
      return _RingingUi(
        name: firstUser.profile.name,
        onClose: Navigator.of(context).pop,
      );
    }

    if (state == PhoneConnectionState.declined) {
      return DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromRGBO(0xE4, 0x23, 0x23, 1.0),
              Color.fromRGBO(0x7D, 0x00, 0x00, 1.0),
            ],
          ),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                'assets/images/call.json',
                animate: false,
                fit: BoxFit.contain,
                width: 90,
              ),
              const SizedBox(width: 16),
              Text(
                'Declined',
                style: Theming.of(context).text.body.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    if (state == PhoneConnectionState.missing) {
      return Center(
        child: Text(
          'The call has already ended',
          style: Theming.of(context).text.body.copyWith(
              color: const Color.fromRGBO(0xB0, 0xB0, 0xB0, 1.0),
              fontSize: 20,
              fontWeight: FontWeight.w700),
        ),
      );
    }

    if (state == PhoneConnectionState.complete) {
      return Center(
        child: Text(
          'Call complete',
          style: Theming.of(context).text.body.copyWith(
              color: const Color.fromRGBO(0xB0, 0xB0, 0xB0, 1.0),
              fontSize: 20,
              fontWeight: FontWeight.w700),
        ),
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
                text: (state == PhoneConnectionState.none ||
                        state == PhoneConnectionState.waiting ||
                        state == PhoneConnectionState.connecting)
                    ? 'Connecting to '
                    : 'You are talking to ',
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
                if (state == PhoneConnectionState.connected ||
                    state == PhoneConnectionState.complete)
                  _CountdownTimer(
                    endTime: _endTime,
                    onTimeUp: widget.onHangUp,
                  ),
              ],
            ),
            const SizedBox(width: 33),
            Container(
              clipBehavior: Clip.hardEdge,
              decoration: const BoxDecoration(shape: BoxShape.circle),
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
              onPressed: () =>
                  widget.onSpeakerphoneChanged(!widget.speakerphone),
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
              onPressed: () => widget.onMuteChanged(!widget.muted),
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

class _StatusResult {
  final Status? status;

  _StatusResult(this.status);
}

String _topicToTitle(Topic topic) {
  switch (topic) {
    case Topic.moved:
      return 'Just moved';
    case Topic.outing:
      return 'Going out';
    case Topic.vacation:
      return 'On vacation';
    case Topic.business:
      return 'Talk business';
    case Topic.school:
      return 'School';
    case Topic.friends:
      return 'New friends';
  }
}

String _topicToDescription(Topic topic) {
  switch (topic) {
    case Topic.moved:
      return 'An area where people who moved come to meet';
    case Topic.outing:
      return 'Need someone to go out with tonight?';
    case Topic.vacation:
      return 'Going on vacation?';
    case Topic.business:
      return 'All things business';
    case Topic.school:
      return 'Want to study or chat about school?';
    case Topic.friends:
      return 'A place to make new friends';
  }
}
