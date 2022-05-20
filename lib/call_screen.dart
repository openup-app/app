import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:get_it/get_it.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/signaling/phone.dart';
import 'package:openup/api/signaling/signaling.dart';
import 'package:openup/api/signaling/socket_io_signaling_channel.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/api/users/profile.dart';
import 'package:openup/api/users/rekindle.dart';
import 'package:openup/lobby_list_page.dart';
import 'package:openup/report_screen.dart';
import 'package:openup/video_call_screen_content.dart';
import 'package:openup/voice_call_screen_content.dart';
import 'package:openup/widgets/end_call_report.dart';

import 'notifications/notifications.dart';

part 'call_screen.freezed.dart';

enum EndCallReason {
  timeUp,
  hangUp,
  report,
  remoteHangUpOrDisconnect,
}

/// Page on which the [Phone] is used to do voice and video calls. Calls
/// start, proceed and end here.
class CallScreen extends ConsumerStatefulWidget {
  final String rid;
  final String host;
  final int socketPort;
  final bool video;
  final bool mini;
  final bool isInitiator;
  final bool serious;
  final List<SimpleProfile> profiles;
  final List<Rekindle> rekindles;
  final bool groupLobby;
  final void Function(EndCallReason reason) onCallEnded;

  const CallScreen({
    Key? key,
    required this.rid,
    required this.host,
    required this.socketPort,
    required this.video,
    this.mini = false,
    required this.isInitiator,
    required this.serious,
    required this.profiles,
    required this.rekindles,
    required this.groupLobby,
    required this.onCallEnded,
  }) : super(key: key);

  @override
  _CallScreenState createState() => _CallScreenState();
}

class _CallScreenState extends ConsumerState<CallScreen> {
  late final SignalingChannel _signalingChannel;
  bool _muted = false;
  bool _speakerphone = false;

  bool _hasSentTimeRequest = false;
  DateTime? _endTime;

  final _unrequestedConnections = <Rekindle>{};

  final _users = <String, CallData>{};
  final _connectionStateSubscriptions = <StreamSubscription>[];
  bool _readyForGroupCall = false;

  String? _showReportOverlayForUid;

  @override
  void initState() {
    super.initState();
    final uid = ref.read(userProvider).uid;
    _signalingChannel = SocketIoSignalingChannel(
      host: widget.host,
      port: widget.socketPort,
      uid: uid,
      rid: widget.rid,
      serious: widget.serious,
    );

    for (var i = 0; i < widget.profiles.length; i++) {
      final profile = widget.profiles[i];
      final phone = Phone(
        signalingChannel: _signalingChannel,
        partnerUid: profile.uid,
        useVideo: widget.video,
        onMediaRenderers: (localRenderer, remoteRenderer) {
          final callData = _users[profile.uid];
          setState(() {
            if (callData != null) {
              _users[profile.uid] = callData.copyWith.userConnection(
                localVideoRenderer: localRenderer,
                videoRenderer: remoteRenderer,
              );
            }
          });
        },
        onRemoteStream: (stream) {
          final callData = _users[profile.uid];
          if (callData != null) {
            setState(() =>
                callData.userConnection.videoRenderer?.srcObject = stream);
          }
        },
        onAddTimeRequest: () {
          setState(() => _hasSentTimeRequest = false);
        },
        onAddTime: _addTime,
        onDisconnected: () =>
            widget.onCallEnded(EndCallReason.remoteHangUpOrDisconnect),
        onToggleMute: (muted) {
          if (_muted != muted) {
            setState(() => _muted = muted);
          }
        },
        onToggleSpeakerphone: (enabled) {
          if (_speakerphone != enabled) {
            setState(() => _speakerphone = enabled);
          }
        },
        onGroupCallLobbyStates: (states) {
          final myReadyState = states[uid];
          if (myReadyState != null) {
            setState(() => _readyForGroupCall = myReadyState);
          }
          for (var entry in states.entries) {
            if (entry.key == uid) {
              setState(() => _readyForGroupCall = entry.value);
            } else {
              final user = _users[entry.key];
              if (user != null) {
                setState(() => _users[entry.key] = user.copyWith
                    .userConnection(readyForGroupCall: entry.value));
              }
            }
          }
        },
        onJoinGroupCall: (rid, profiles, rekindles) {
          final route = ModalRoute.of(context)?.settings.name;
          if (route != null) {
            Navigator.of(context).pushNamed(
              route,
              arguments: CallPageArguments(
                rid: rid,
                profiles: profiles,
                rekindles: rekindles,
                serious: widget.serious,
                groupLobby: false,
              ),
            );
          }
        },
      );
      final userConnection = UserConnection(
        profile: profile,
        rekindle: widget.rekindles.firstWhereOrNull(
          (r) => r.uid == profile.uid,
        ),
        localVideoRenderer: null,
        videoRenderer: null,
        connectionState: PhoneConnectionState.none,
        readyForGroupCall: false,
      );
      _users[profile.uid] = CallData(
        phone: phone,
        userConnection: userConnection,
      );
    }

    _unrequestedConnections.addAll(widget.rekindles);

    for (var call in _users.entries) {
      final otherUid = call.key;
      _connectionStateSubscriptions
          .add(call.value.phone.connectionStateStream.listen((state) {
        final latestData = _users[otherUid];
        if (latestData != null) {
          setState(() {
            _users[otherUid] =
                latestData.copyWith.userConnection(connectionState: state);
          });
        }

        if (state == PhoneConnectionState.connected && _endTime == null) {
          setState(
              () => _endTime = DateTime.now().add(const Duration(minutes: 5)));
        }
      }));
    }
    _users.values.first.phone
        .join(initiator: _isInitiator(uid, _users.keys.first));

    reportCallStarted(widget.rid);
  }

  @override
  void dispose() {
    // Temporary to ensure hiding mini panel hangs up the call on the other end
    _signalingChannel.send(const HangUp());

    reportCallEnded(widget.rid);
    _signalingChannel.dispose();
    _connectionStateSubscriptions.map((s) => s.cancel()).toList();
    _users.values.map((e) => e.phone.dispose()).toList();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ImageFiltered(
          imageFilter: ImageFilter.blur(
            sigmaX: _showReportOverlayForUid == null ? 0.0 : 8.0,
            sigmaY: _showReportOverlayForUid == null ? 0.0 : 8.0,
          ),
          child: Stack(
            children: [
              if (widget.mini)
                MiniVoiceCallScreenContent(
                  users:
                      _users.values.map((data) => data.userConnection).toList(),
                  isInitiator: widget.isInitiator,
                  hasSentTimeRequest: _hasSentTimeRequest,
                  endTime: widget.rekindles.isEmpty ? null : _endTime,
                  muted: _muted,
                  speakerphone: _speakerphone,
                  onTimeUp: () => widget.onCallEnded(EndCallReason.timeUp),
                  onHangUp: () {
                    _signalingChannel.send(const HangUp());
                    widget.onCallEnded(EndCallReason.hangUp);
                  },
                  onConnect: _connect,
                  onReport: (uid) {
                    _signalingChannel.send(HangUpReport(uidToReport: uid));
                    widget.onCallEnded(EndCallReason.report);
                  },
                  onSendTimeRequest: _sendTimeRequest,
                  onToggleMute: () => _users.values
                      .forEach((element) => element.phone.toggleMute()),
                  onToggleSpeakerphone: () => _users.values
                      .forEach((element) => element.phone.toggleSpeakerphone()),
                )
              else if (widget.video)
                VideoCallScreenContent(
                  localRenderer:
                      _users.values.first.userConnection.localVideoRenderer,
                  users:
                      _users.values.map((data) => data.userConnection).toList(),
                  hasSentTimeRequest: _hasSentTimeRequest,
                  endTime: widget.rekindles.isEmpty ? null : _endTime,
                  muted: _muted,
                  isGroupLobby: widget.groupLobby,
                  readyForGroupCall: _readyForGroupCall,
                  onTimeUp: _navigateToRekindleOrLobby,
                  onHangUp: () {
                    _signalingChannel.send(const HangUp());
                    _navigateToRekindleOrLobby();
                  },
                  onConnect: _connect,
                  onReport: _report,
                  onSendTimeRequest: _sendTimeRequest,
                  onToggleMute: () => _users.values
                      .forEach((element) => element.phone.toggleMute()),
                  onSendReadyForGroupCall: () =>
                      _users.values.first.phone.signalingChannel.send(
                    const GroupCallLobbyReady(ready: true),
                  ),
                )
              else
                VoiceCallScreenContent(
                  users:
                      _users.values.map((data) => data.userConnection).toList(),
                  hasSentTimeRequest: _hasSentTimeRequest,
                  endTime: widget.rekindles.isEmpty ? null : _endTime,
                  muted: _muted,
                  speakerphone: _speakerphone,
                  onTimeUp: _navigateToRekindleOrLobby,
                  onHangUp: () {
                    _signalingChannel.send(const HangUp());
                    _navigateToRekindleOrLobby();
                  },
                  onConnect: _connect,
                  onReport: _report,
                  onSendTimeRequest: _sendTimeRequest,
                  onToggleMute: () => _users.values
                      .forEach((element) => element.phone.toggleMute()),
                  onToggleSpeakerphone: () => _users.values
                      .forEach((element) => element.phone.toggleSpeakerphone()),
                ),
            ],
          ),
        ),
        if (_showReportOverlayForUid != null)
          EndCallReport(
            backgroundGradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.fromRGBO(0xFF, 0x8E, 0x8E, 0.9),
                Color.fromRGBO(0xBD, 0x20, 0x20, 0.66),
              ],
            ),
            thumbIconColor: const Color.fromRGBO(0x9E, 0x00, 0x00, 1.0),
            onHangUp: () {
              _signalingChannel
                  .send(HangUpReport(uidToReport: _showReportOverlayForUid!));
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacementNamed(
                'call-report',
                arguments: ReportScreenArguments(
                  uid: _showReportOverlayForUid!,
                ),
              );
            },
            onCancel: () {
              setState(() => _showReportOverlayForUid = null);
            },
          ),
      ],
    );
  }

  void _sendTimeRequest() {
    if (!_hasSentTimeRequest) {
      setState(() => _hasSentTimeRequest = true);
      _signalingChannel.send(const AddTimeRequest());
    }
  }

  void _addTime(Duration duration) {
    setState(() {
      _endTime = _endTime?.add(duration);
      _hasSentTimeRequest = false;
    });
  }

  void _connect(String uid) async {
    final myUid = ref.read(userProvider).uid;
    final api = GetIt.instance.get<Api>();
    final callData = _users[uid];
    if (callData != null) {
      setState(() {
        _users[uid] = callData.copyWith.userConnection(rekindle: null);
      });
    }
    final result = await api.addConnectionRequest(myUid, uid);
    if (mounted & result.isRight()) {
      setState(() => _unrequestedConnections.removeWhere((r) => r.uid == uid));
    }
  }

  void _report(String uid) {
    setState(() => _showReportOverlayForUid = uid);
  }

  void _navigateToRekindleOrLobby() {
    Navigator.of(context).popAndPushNamed('lobby-list');
  }

  bool _isInitiator(String myUid, String theirUid) =>
      myUid.compareTo(theirUid) < 0;
}

String connectionStateText(
  PhoneConnectionState connectionState,
) {
  switch (connectionState) {
    case PhoneConnectionState.none:
      return '';

    case PhoneConnectionState.missing:
      return 'The call has already ended';

    case PhoneConnectionState.waiting:
      return 'Waiting for your match';

    case PhoneConnectionState.declined:
      return 'Your match did not join';

    case PhoneConnectionState.connecting:
      return 'Connecting';

    case PhoneConnectionState.connected:
      return 'Connected';

    case PhoneConnectionState.complete:
      return 'Disconnected';
  }
}

@freezed
class CallData with _$CallData {
  const factory CallData({
    required Phone phone,
    required UserConnection userConnection,
  }) = _CallData;
}

@freezed
class UserConnection with _$UserConnection {
  const factory UserConnection({
    required SimpleProfile profile,
    required Rekindle? rekindle,
    required RTCVideoRenderer? localVideoRenderer,
    required RTCVideoRenderer? videoRenderer,
    required PhoneConnectionState connectionState,
    required bool readyForGroupCall,
  }) = _UserConnection;
}

class CallPageArguments {
  final String rid;
  final List<SimpleProfile> profiles;
  final List<Rekindle> rekindles;
  final bool serious;
  final bool groupLobby;

  CallPageArguments({
    required this.rid,
    required this.profiles,
    required this.rekindles,
    required this.serious,
    this.groupLobby = false,
  });
}
