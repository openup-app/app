import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:list_diff/list_diff.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/api/users/profile.dart';
import 'package:openup/notifications/ios_voip_handlers.dart' as ios_voip;
import 'package:openup/profile_screen.dart';
import 'package:openup/report_screen.dart';
import 'package:openup/util/location_service.dart';
import 'package:openup/util/page_transition.dart';
import 'package:openup/widgets/audio_bio.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/icon_with_shadow.dart';
import 'package:openup/widgets/play_button.dart';
import 'package:openup/widgets/profile_button.dart';
import 'package:openup/widgets/profile_photo.dart';
import 'package:openup/widgets/theming.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:tuple/tuple.dart';

import 'main.dart';

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
  bool _nearbyOnly = false;

  bool _loading = false;
  Status? _status;
  var _topicStatuses = <Tuple2<Topic, List<TopicParticipant>>>[];
  late final Timer _refreshTimer;
  int _userCount = 0;

  Topic? _selectedTopic;
  bool _slideToRight = true;

  Key _myStatusKey = UniqueKey();

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

    // Location
    const LocationService().getLatLong().then((latLong) {
      if (latLong != null) {
        final api = GetIt.instance.get<Api>();
        api.updateLocation(
          ref.read(userProvider).uid,
          latLong,
        );
      }
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
  }

  @override
  void dispose() {
    super.dispose();
    _refreshTimer.cancel();
  }

  Future<void> _fetchParticipants() async {
    final myUid = ref.read(userProvider).uid;
    final api = GetIt.instance.get<Api>();
    final topicParticipants = await api.getStatuses(myUid, _nearbyOnly);
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

          setState(() {
            _userCount =
                topicStatuses.fold<int>(0, (p, e) => p + e.item2.length);
            _topicStatuses = topicStatuses;
          });
        },
      );
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
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.fromRGBO(0x00, 0x2B, 0x44, 1.0),
            Color.fromRGBO(0x00, 0x00, 0x00, 1.0),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              _PageHeader(
                loading: _loading,
                userCount: _userCount,
                nearbyOnly: _nearbyOnly,
                onNearbyOnlyChanged: (value) {
                  if (_nearbyOnly != value) {
                    setState(() => _nearbyOnly = value);
                    _fetchParticipants();
                  }
                },
              ),
              if (_loading)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              if (!_loading)
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) {
                      if (_slideToRight) {
                        if (child.key == const Key('multiple')) {
                          return slideLeftToRightPageTransition(
                            context,
                            animation,
                            const AlwaysStoppedAnimation(0.0),
                            child,
                          );
                        } else {
                          return slideRightToLeftPageTransition(
                            context,
                            animation,
                            const AlwaysStoppedAnimation(0.0),
                            child,
                          );
                        }
                      } else {
                        if (child.key == const Key('multiple')) {
                          return slideRightToLeftPageTransition(
                            context,
                            animation,
                            const AlwaysStoppedAnimation(0.0),
                            child,
                          );
                        } else {
                          return slideLeftToRightPageTransition(
                            context,
                            animation,
                            const AlwaysStoppedAnimation(0.0),
                            child,
                          );
                        }
                      }
                    },
                    child: _selectedTopic == null
                        ? _MultipleTopicList(
                            key: const Key('multiple'),
                            topicStatuses: _topicStatuses,
                            onTopicSelected: (topic, slideToRight) {
                              setState(() {
                                _selectedTopic = topic;
                                _slideToRight = slideToRight;
                              });
                            },
                          )
                        : WillPopScope(
                            onWillPop: () {
                              setState(() => _selectedTopic = null);
                              return Future.value(false);
                            },
                            child: _SingleTopicList(
                              topic: _selectedTopic!,
                              reverseHeader: !_slideToRight,
                              participants: _topicStatuses
                                  .firstWhere(
                                    (element) =>
                                        element.item1 == _selectedTopic,
                                    orElse: () => Tuple2(_selectedTopic!, []),
                                  )
                                  .item2,
                              pop: () => setState(() => _selectedTopic = null),
                            ),
                          ),
                  ),
                ),
            ],
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 212,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),
          if (_status != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 106,
              height: 66,
              child: _StatusBanner(
                key: _myStatusKey,
                status: _status!,
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 16,
            child: _StatusField(
              loading: _loading,
              status: _status,
              onStatus: (status) {
                setState(() {
                  // URL stays the same, so we need to refresh the UI with new key
                  _myStatusKey = UniqueKey();
                  _status = status;
                });
              },
            ),
          ),
          Positioned(
            right: 24,
            top: MediaQuery.of(context).padding.top + 16,
            child: const ProfileButton(),
          ),
        ],
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  final bool loading;
  final int userCount;
  final bool nearbyOnly;
  final ValueChanged<bool> onNearbyOnlyChanged;

  const _PageHeader({
    Key? key,
    required this.loading,
    required this.userCount,
    required this.nearbyOnly,
    required this.onNearbyOnlyChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).padding.top + 122,
      padding: const EdgeInsets.only(left: 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.fromRGBO(0x01, 0x39, 0x59, 1.0),
            Color.fromRGBO(0x00, 0x15, 0x20, 1.0),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: MediaQuery.of(context).padding.top + 16,
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Button(
              onPressed: () => _showSettingsDialog(context),
              child: const Icon(
                Icons.settings,
                size: 40,
              ),
            ),
          ),
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'People Available : ',
                  style: Theming.of(context).text.body.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w300,
                      ),
                ),
                TextSpan(
                  text: loading ? '' : userCount.toString(),
                  style: Theming.of(context).text.body.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w300,
                      color: const Color.fromRGBO(0x00, 0xFF, 0x47, 1.0)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => SettingsDialog(nearbyOnly: nearbyOnly),
    );

    if (result != null) {
      onNearbyOnlyChanged(result);
    }
  }
}

class SettingsDialog extends StatefulWidget {
  final bool nearbyOnly;
  const SettingsDialog({
    Key? key,
    required this.nearbyOnly,
  }) : super(key: key);

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late bool value;

  @override
  void initState() {
    super.initState();
    value = widget.nearbyOnly;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(41),
        ),
      ),
      clipBehavior: Clip.hardEdge,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromRGBO(0x03, 0x2A, 0x42, 1.0),
              Color.fromRGBO(0x00, 0x06, 0x0B, 1.0),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: WillPopScope(
            onWillPop: () {
              Navigator.of(context).pop(value);
              return Future.value(false);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: 12.0,
                      top: 16,
                      bottom: 16,
                    ),
                    child: Icon(
                      Icons.settings,
                      color: Color.fromRGBO(0x95, 0x95, 0x95, 1.0),
                      size: 36,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.business,
                    color: Color.fromRGBO(0xAE, 0xAE, 0xAE, 1.0),
                    size: 32,
                  ),
                  trailing: Switch.adaptive(
                    value: value,
                    onChanged: (v) => setState(() => value = v),
                  ),
                  horizontalTitleGap: 12,
                  title: Text(
                    'See my city only',
                    style: Theming.of(context)
                        .text
                        .body
                        .copyWith(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  subtitle: AutoSizeText(
                    'Shows people only in your current city',
                    style: Theming.of(context).text.body.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: const Color.fromRGBO(0xAE, 0xAE, 0xAE, 1.0)),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: 263,
                  height: 40,
                  child: Button(
                    onPressed: () => Navigator.of(context).pop(value),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: const Color.fromRGBO(0x9C, 0x9A, 0x9A, 1.0)),
                        borderRadius: const BorderRadius.all(
                          Radius.circular(32),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Cancel',
                          style: Theming.of(context).text.body.copyWith(
                              fontSize: 20, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: 36,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(
                      Radius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final Status status;
  const _StatusBanner({
    Key? key,
    required this.status,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(11)),
        color: Color.fromRGBO(0x00, 0x00, 0x00, 0.85),
        boxShadow: [
          BoxShadow(
            blurRadius: 4,
            offset: Offset(0.0, 4.0),
            color: Color.fromRGBO(0x00, 0x00, 0x00, 0.25),
          ),
        ],
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Consumer(
            builder: (context, ref, child) {
              final name = ref.watch(userProvider).profile?.name ?? '';
              final photo = ref.watch(userProvider).profile?.photo ?? '';
              return Row(
                children: [
                  const SizedBox(width: 11),
                  SizedBox(
                    width: 44,
                    height: 53,
                    child: Container(
                      clipBehavior: Clip.hardEdge,
                      decoration: const BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(5))),
                      child: ProfilePhoto(
                        url: photo,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AutoSizeText(
                          name,
                          style: Theming.of(context).text.body.copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        AutoSizeText(
                          status.location,
                          style: Theming.of(context).text.body.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                  ),
                  PlayButton(
                    url: status.audioUrl,
                    builder: (context, state) {
                      return PlayStopArrow(
                        state: state,
                        size: 36,
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _StatusField extends StatelessWidget {
  final bool loading;
  final Status? status;
  final ValueChanged<Status?> onStatus;
  const _StatusField({
    Key? key,
    required this.loading,
    required this.status,
    required this.onStatus,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading
          ? null
          : () async {
              // Bug in Flutter not letting showBottomPanel return a result: https://github.com/flutter/flutter/issues/66837
              Status? output = status;
              await _showPanel(
                context: context,
                builder: (context) {
                  return _StatusBox(
                    status: status,
                    statusUpdated: (s) => output = s,
                  );
                },
              );

              onStatus(output);
            },
      child: Container(
        height: 54,
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
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
        child: Stack(
          children: [
            Center(
              child: Text(
                'Why are you here today?',
                textAlign: status == null ? TextAlign.center : TextAlign.start,
                overflow: TextOverflow.ellipsis,
                style: Theming.of(context).text.body.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: const Color.fromRGBO(0x46, 0x46, 0x46, 1.0),
                    ),
              ),
            ),
            const Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(
                  Icons.settings_voice,
                  color: Color.fromRGBO(0x46, 0x46, 0x46, 1.0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<T?> _showPanel<T>({
  required BuildContext context,
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
        child: LayoutBuilder(
          builder: (context, c) {
            final width = c.maxWidth;
            return SizedBox(
              width: width,
              child: _PanelDragIndicator(
                child: builder(context),
              ),
            );
          },
        ),
      );
    },
  );
  return result.closed;
}

class _PanelDragIndicator extends StatelessWidget {
  final Widget child;
  const _PanelDragIndicator({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      alignment: Alignment.center,
      children: [
        child,
        const Positioned(
          top: 10,
          width: 34,
          height: 4,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Color.fromRGBO(0x85, 0x7A, 0x7A, 1.0),
              borderRadius: BorderRadius.all(Radius.circular(2)),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusBox extends ConsumerStatefulWidget {
  final Status? status;
  final ValueChanged<Status?> statusUpdated;

  const _StatusBox({
    Key? key,
    this.status,
    required this.statusUpdated,
  }) : super(key: key);

  @override
  _StatusBoxState createState() => _StatusBoxState();
}

class _StatusBoxState extends ConsumerState<_StatusBox> {
  bool _posting = false;
  bool _deleting = false;

  bool _page2 = false;

  late final AudioBioController _audioBioController;
  Uint8List? _audio;
  String? _audioUrl;
  String? _audioPath;
  Status? _status;
  late Topic _topic;

  @override
  void initState() {
    super.initState();
    _topic = widget.status?.topic ?? Topic.lonely;
    _audioUrl = widget.status?.audioUrl;
    _status = widget.status;
    _audioBioController = AudioBioController(
      onRecordingComplete: (data) async {
        final dir = await getTemporaryDirectory();
        final file = File(path.join(dir.path, 'audio.m4a'));
        await file.writeAsBytes(data);
        setState(() {
          _audioUrl = null;
          _audio = data;
          _audioPath = file.path;
        });
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
    _audioBioController.dispose();
  }

  bool get _recorded => _audio != null || _audioUrl != null;

  @override
  Widget build(BuildContext context) {
    if (!_page2) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: Text(
              'Why are you here today?',
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
            child: DefaultTextStyle(
              style: Theming.of(context).text.body.copyWith(
                  color: const Color.fromRGBO(0x69, 0x69, 0x69, 1.0),
                  fontSize: 16,
                  fontWeight: FontWeight.w500),
              child: Builder(
                builder: (context) {
                  return RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'To ',
                          style: DefaultTextStyle.of(context).style,
                        ),
                        TextSpan(
                          text: 'receive',
                          style: DefaultTextStyle.of(context).style.copyWith(
                              color: Colors.black, fontWeight: FontWeight.w700),
                        ),
                        TextSpan(
                          text:
                              ' calls, you must tell everyone why you are here today. Once you post your voice status, any one who sees it can call you. Limited to ',
                          style: DefaultTextStyle.of(context).style,
                        ),
                        TextSpan(
                          text: '10 seconds.',
                          style: DefaultTextStyle.of(context).style.copyWith(
                              color: Colors.black, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          if (!_recorded)
            AudioBioRecordButton(
              controller: _audioBioController,
              micBuilder: (context, recording, size) {
                if (recording) {
                  return Container(
                    width: size,
                    height: size,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Color.fromRGBO(0xFF, 0x00, 0x00, 1.0),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.stop,
                      size: 48,
                      color: Colors.white,
                    ),
                  );
                } else {
                  return const Icon(
                    Icons.settings_voice,
                    size: 64,
                    color: Color.fromRGBO(0xFF, 0x00, 0x00, 1.0),
                  );
                }
              },
            )
          else
            PlayButton(
              url: _audioUrl,
              path: _audioPath,
              builder: (context, state) {
                return Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: PlayStopArrow(
                    state: state,
                    color: Colors.black,
                  ),
                );
              },
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _deleting
                    ? const SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(),
                      )
                    : Button(
                        onPressed: (!_recorded || _posting) ? null : _delete,
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(
                            Icons.delete,
                            color: Color.fromRGBO(0xFF, 0x00, 0x00, 1.0),
                          ),
                        ),
                      ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'You must delete your status if you don\'t want to recieve calls anymore.',
                      style: Theming.of(context).text.body.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: const Color.fromRGBO(0x69, 0x69, 0x69, 1.0),
                          ),
                    ),
                  ),
                ),
                Button(
                  onPressed: !_recorded || _deleting
                      ? null
                      : () => setState(() => _page2 = true),
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(
                      Icons.arrow_forward,
                      color: Color.fromRGBO(0x78, 0x78, 0x78, 1.0),
                    ),
                  ),
                ),
              ],
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
          mainAxisSize: MainAxisSize.min,
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
                          color: Color.fromRGBO(0x78, 0x78, 0x78, 1.0),
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
                left: 27,
                right: 27,
                bottom: 4,
                top: 10,
              ),
              child: Text(
                'Categories let others know why you’re here and will make it easier to meet those with similarities.',
                style: Theming.of(context).text.body.copyWith(
                    color: const Color.fromRGBO(0x69, 0x69, 0x69, 1.0),
                    fontSize: 15,
                    fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CheckboxTile(
                        label: _topicToTitle(Topic.lonely),
                        value: _topic == Topic.lonely,
                        onChanged: (_) => setState(() => _topic = Topic.lonely),
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
                        label: _topicToTitle(Topic.sleep),
                        value: _topic == Topic.sleep,
                        onChanged: (_) => setState(() => _topic = Topic.sleep),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Button(
              onPressed: _deleting ? null : (_recorded ? _submit : null),
              child: _posting
                  ? const Padding(
                      padding: EdgeInsets.only(bottom: 10.0),
                      child: CircularProgressIndicator(),
                    )
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
            const SizedBox(height: 24),
          ],
        ),
      );
    }
  }

  void _submit() async {
    setState(() => _posting = true);
    final uid = ref.read(userProvider).uid;
    final api = GetIt.instance.get<Api>();
    if (_audio != null || _status?.audioUrl != null) {
      final result = await api.updateStatus(uid, _topic, _audio);
      if (!mounted) {
        return;
      }
      result.fold(
        (l) {
          displayError(context, l);
          setState(() => _posting = false);
        },
        (r) {
          widget.statusUpdated(r);
          Navigator.of(context).pop();
        },
      );
    }
  }

  void _delete() async {
    setState(() {
      _audio = null;
      _status = null;
      _deleting = true;
    });
    widget.statusUpdated(null);

    if (_audioUrl == null) {
      setState(() => _deleting = false);
      return;
    }

    setState(() => _audioUrl = null);
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
        setState(() => _deleting = false);
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
    return SizedBox(
      height: 44,
      child: Button(
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

Future<CallProfileAction?> _displayCallProfile(
  BuildContext context,
  TopicParticipant participant,
  Topic topic,
) {
  return Navigator.of(context).pushNamed<CallProfileAction>(
    'call-profile',
    arguments: CallProfileScreenArguments(
      Profile(
        uid: participant.uid,
        name: participant.name,
        photo: participant.photo,
        gallery: participant.gallery,
      ),
      Status(
        topic: topic,
        audioUrl: participant.audioUrl,
        location: participant.location,
        endTime: DateTime.now(),
      ),
      _topicToTitle(topic),
    ),
  );
}

class _MultipleTopicList extends StatefulWidget {
  final List<Tuple2<Topic, List<TopicParticipant>>> topicStatuses;
  final void Function(Topic topic, bool slideToRight) onTopicSelected;
  const _MultipleTopicList({
    Key? key,
    required this.topicStatuses,
    required this.onTopicSelected,
  }) : super(key: key);

  @override
  State<_MultipleTopicList> createState() => _MultipleTopicListState();
}

class _MultipleTopicListState extends State<_MultipleTopicList> {
  late List<Tuple2<Topic, List<TopicParticipant>>> _topicStatuses;
  final _listKeys = Map.fromEntries(
      Topic.values.map((e) => MapEntry(e, GlobalKey<AnimatedListState>())));

  @override
  void initState() {
    super.initState();
    _topicStatuses = widget.topicStatuses;
  }

  @override
  void didUpdateWidget(covariant _MultipleTopicList oldWidget) {
    super.didUpdateWidget(oldWidget);
    updateList(oldWidget.topicStatuses, widget.topicStatuses);
  }

  void updateList(
    List<Tuple2<Topic, List<TopicParticipant>>> oldData,
    List<Tuple2<Topic, List<TopicParticipant>>> newData,
  ) async {
    final operations = <Tuple2<Topic, Operation<TopicParticipant>>>[];
    for (final tuple in newData) {
      final topic = tuple.item1;
      final participants = tuple.item2;
      final topicStatuses = oldData.firstWhere(
        (e) => e.item1 == topic,
        orElse: () => Tuple2(topic, []),
      );
      final differences = await diff(
        topicStatuses.item2,
        participants,
        areEqual: (a, b) =>
            (a as TopicParticipant).uid == (b as TopicParticipant).uid,
        getHashCode: (a) => a.hashCode,
      );
      for (final difference in differences) {
        operations.add(Tuple2(topic, difference));
      }
    }

    setState(() => _topicStatuses = widget.topicStatuses);

    for (final operation in operations) {
      final topic = operation.item1;
      final difference = operation.item2;
      final state = _listKeys[topic]?.currentState;
      if (state != null) {
        switch (difference.type) {
          case OperationType.insertion:
            state.insertItem(
              difference.index,
              duration: const Duration(milliseconds: 400),
            );
            break;
          case OperationType.deletion:
            state.removeItem(
              difference.index,
              (c, a) => _animatedRemoveBuilder(c, a, difference.item),
              duration: const Duration(milliseconds: 400),
            );
            break;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_topicStatuses.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 16, bottom: 120),
          child: _NoUsers(),
        ),
      );
    }
    return ListView.builder(
      itemCount: _topicStatuses.length,
      padding: const EdgeInsets.only(top: 16, bottom: 150),
      itemBuilder: (context, index) {
        final topic = _topicStatuses[index].item1;
        final participants = _topicStatuses[index].item2;
        final reverseHeader = index.isOdd;
        // Only possible to occur when just blocked a user
        if (participants.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Directionality(
              textDirection:
                  reverseHeader ? TextDirection.rtl : TextDirection.ltr,
              child: _TopicHeader(
                topic: topic,
                onPressed: () => widget.onTopicSelected(topic, !reverseHeader),
              ),
            ),
            SizedBox(
              height: 360,
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
                          CurveTween(curve: Curves.easeOut).animate(animation),
                      child: SizedBox(
                        width: 280,
                        height: 342,
                        child: _ParticipantTile(
                          participant: participant,
                          onPressed: () async {
                            final action = await Navigator.of(context)
                                .pushNamed<CallProfileAction>(
                              'call-profile',
                              arguments: CallProfileScreenArguments(
                                Profile(
                                  uid: participant.uid,
                                  name: participant.name,
                                  photo: participant.photo,
                                  gallery: participant.gallery,
                                ),
                                Status(
                                  topic: topic,
                                  audioUrl: participant.audioUrl,
                                  location: participant.location,
                                  endTime: DateTime.now(),
                                ),
                                _topicToTitle(topic),
                              ),
                            );
                            if (action != null) {
                              switch (action) {
                                case CallProfileAction.call:
                                  if (mounted) {
                                    callSystemKey.currentState?.call(
                                      context,
                                      SimpleProfile(
                                        uid: participant.uid,
                                        name: participant.name,
                                        photo: participant.photo,
                                      ),
                                    );
                                  }
                                  break;
                                case CallProfileAction.block:
                                  final item = participants.removeAt(index);
                                  setState(() {});
                                  _listKeys[topic]?.currentState?.removeItem(
                                        index,
                                        (c, a) =>
                                            _animatedRemoveBuilder(c, a, item),
                                        duration:
                                            const Duration(milliseconds: 400),
                                      );
                                  break;
                                case CallProfileAction.report:
                                  break;
                              }
                            }
                          },
                          onBlock: () {
                            Navigator.of(context).pop();
                            final item = participants.removeAt(index);
                            setState(() {});
                            _listKeys[topic]?.currentState?.removeItem(
                                  index,
                                  (c, a) => _animatedRemoveBuilder(c, a, item),
                                  duration: const Duration(milliseconds: 400),
                                );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
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
        child: SizedBox(
          width: 280,
          height: 342,
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
      ),
    );
  }
}

class _SingleTopicList extends StatefulWidget {
  final Topic topic;
  final List<TopicParticipant> participants;
  final bool reverseHeader;
  final VoidCallback pop;

  const _SingleTopicList({
    Key? key,
    required this.topic,
    required this.participants,
    this.reverseHeader = false,
    required this.pop,
  }) : super(key: key);

  @override
  State<_SingleTopicList> createState() => _SingleTopicListState();
}

class _SingleTopicListState extends State<_SingleTopicList> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        Directionality(
          textDirection:
              widget.reverseHeader ? TextDirection.rtl : TextDirection.ltr,
          child: _TopicHeader(
            topic: widget.topic,
            centerText: true,
            onPressed: widget.pop,
          ),
        ),
        if (widget.participants.isEmpty)
          const Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: 120),
              child: _NoUsers(),
            ),
          )
        else
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.only(bottom: 150),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3 / 4,
              ),
              itemCount: widget.participants.length,
              itemBuilder: (context, index) {
                final participant = widget.participants[index];
                return _ParticipantTile(
                  participant: participant,
                  onPressed: () async {
                    final action = await _displayCallProfile(
                        context, participant, widget.topic);
                    if (action == null) {
                      return;
                    }
                    switch (action) {
                      case CallProfileAction.call:
                        if (mounted) {
                          callSystemKey.currentState?.call(
                            context,
                            SimpleProfile(
                              uid: participant.uid,
                              name: participant.name,
                              photo: participant.photo,
                            ),
                          );
                        }
                        break;
                      case CallProfileAction.block:
                        break;
                      case CallProfileAction.report:
                        break;
                    }
                  },
                  onBlock: () {},
                );
              },
            ),
          ),
      ],
    );
  }
}

class _TopicHeader extends StatelessWidget {
  final Topic topic;
  final bool centerText;
  final VoidCallback onPressed;

  const _TopicHeader({
    Key? key,
    required this.topic,
    this.centerText = false,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: !centerText
          ? Directionality.of(context)
          : (Directionality.of(context) == TextDirection.ltr
              ? TextDirection.rtl
              : TextDirection.ltr),
      child: Button(
        onPressed: onPressed,
        child: Row(
          children: [
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: centerText
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start,
                crossAxisAlignment: centerText
                    ? CrossAxisAlignment.stretch
                    : CrossAxisAlignment.start,
                children: [
                  Text(
                    _topicToTitle(topic),
                    textAlign: centerText ? TextAlign.center : null,
                    style: Theming.of(context).text.body.copyWith(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      shadows: [
                        const Shadow(
                          blurRadius: 8,
                          color: Color.fromRGBO(0x00, 0x00, 0x00, 0.25),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  AutoSizeText(
                    _topicToDescription(topic),
                    maxLines: 1,
                    textAlign: centerText ? TextAlign.center : null,
                    style: Theming.of(context).text.body.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w300,
                      shadows: [
                        const Shadow(
                          blurRadius: 8,
                          color: Color.fromRGBO(0x00, 0x00, 0x00, 0.25),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 48,
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}

class _NoUsers extends StatelessWidget {
  const _NoUsers({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.only(left: 16.0, top: 16, right: 16, bottom: 72),
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
    );
  }
}

class CallProfileScreen extends StatelessWidget {
  final Profile profile;
  final Status status;
  final String title;
  const CallProfileScreen({
    Key? key,
    required this.profile,
    required this.status,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.fromRGBO(0x00, 0x2B, 0x44, 1.0),
            Color.fromRGBO(0x00, 0x00, 0x00, 1.0),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        top: true,
        child: Column(
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Button(
                    onPressed: Navigator.of(context).pop,
                    child: const Icon(Icons.keyboard_arrow_down, size: 36),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        title,
                        style: Theming.of(context).text.body.copyWith(
                            fontSize: 20, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  _ReportBlockPopupMenu(
                    uid: profile.uid,
                    name: profile.name,
                    onBlock: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop(CallProfileAction.block);
                    },
                  ),
                ],
              ),
            ),
            Flexible(
              fit: FlexFit.loose,
              child: Container(
                constraints: const BoxConstraints(
                  maxWidth: 346,
                  maxHeight: 390,
                  minHeight: 200,
                ),
                clipBehavior: Clip.hardEdge,
                margin: const EdgeInsets.all(28),
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 18,
                      offset: Offset(0.0, 4.0),
                      color: Color.fromRGBO(0x00, 0x00, 0x00, 0.25),
                    ),
                  ],
                ),
                child: Gallery(
                  slideshow: true,
                  gallery: profile.gallery,
                  withWideBlur: false,
                ),
              ),
            ),
            AutoSizeText(
              profile.name,
              style: Theming.of(context).text.body.copyWith(
                    fontSize: 32,
                    fontWeight: FontWeight.w400,
                  ),
            ),
            AutoSizeText(
              status.location,
              style: Theming.of(context).text.body.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w300,
                  ),
            ),
            const SizedBox(height: 26),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                PlayButton(
                  url: status.audioUrl,
                  builder: (context, state) {
                    return Container(
                      width: 80,
                      height: 80,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: PlayStopArrow(
                        state: state,
                        color: Colors.black,
                        size: 32,
                      ),
                    );
                  },
                ),
                Button(
                  onPressed: () {
                    Navigator.of(context).pop(CallProfileAction.call);
                  },
                  child: Container(
                    width: 80,
                    height: 80,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: const Icon(
                      Icons.call,
                      size: 48,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 26.0),
              child: Text(
                  'if you want to be friends with ${profile.name}\nyou must have a conversation with them first',
                  style: Theming.of(context)
                      .text
                      .body
                      .copyWith(fontSize: 16, fontWeight: FontWeight.w400)),
            ),
          ],
        ),
      ),
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
      child: Stack(
        fit: StackFit.expand,
        children: [
          Button(
            onPressed: onPressed,
            child: IgnorePointer(
              child: Gallery(
                gallery: participant.gallery,
                slideshow: true,
                withWideBlur: false,
              ),
            ),
          ),
          Positioned(
            left: 17,
            right: 0,
            top: 14,
            child: Row(
              children: [
                Expanded(
                  child: AutoSizeText(
                    participant.name,
                    maxLines: 1,
                    style: Theming.of(context).text.body.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      shadows: [
                        const Shadow(
                          blurRadius: 8,
                          color: Color.fromRGBO(0x00, 0x00, 0x00, 0.5),
                        ),
                      ],
                    ),
                  ),
                ),
                _ReportBlockPopupMenu(
                  uid: participant.uid,
                  name: participant.name,
                  onBlock: onBlock,
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: PlayButton(
                url: participant.audioUrl,
                builder: (context, state) {
                  return SizedBox(
                    width: 70,
                    height: 70,
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color.fromRGBO(0x00, 0x00, 0x00, 0.5),
                      ),
                      child: Center(
                        child: PlayStopArrow(
                          state: state,
                          size: 36,
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
      icon: const IconWithShadow(Icons.more_horiz, size: 32),
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
            value: 'block',
            child: ListTile(
              title: Text('Block user'),
              trailing: Icon(Icons.block),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const PopupMenuItem(
            value: 'report',
            child: ListTile(
              title: Text('Report user'),
              trailing: Icon(Icons.flag_outlined),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ];
      },
    );
  }
}

String _topicToTitle(Topic topic) {
  switch (topic) {
    case Topic.lonely:
      return 'I\'m Lonely';
    case Topic.friends:
      return 'Need Friends';
    case Topic.moved:
      return 'Just Moved';
    case Topic.sleep:
      return 'Can\'t Sleep';
  }
}

String _topicToDescription(Topic topic) {
  switch (topic) {
    case Topic.lonely:
      return 'People who are in need of some company';
    case Topic.friends:
      return 'For those who are looking to make new friends';
    case Topic.moved:
      return 'Others who also moved to a new area';
    case Topic.sleep:
      return 'Talk to someone who is also having a hard time sleeping';
  }
}

class CallProfileScreenArguments {
  final Profile profile;
  final Status status;
  final String title;

  CallProfileScreenArguments(this.profile, this.status, this.title);
}

enum CallProfileAction { call, block, report }
