import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:openup/api/signaling/phone.dart';
import 'package:openup/api/signaling/signaling.dart';
import 'package:openup/api/signaling/socket_io_signaling_channel.dart';
import 'package:openup/api/users/profile.dart';
import 'package:openup/api/users/rekindle.dart';
import 'package:openup/api/users/users_api.dart';
import 'package:openup/rekindle_screen.dart';
import 'package:openup/video_call_screen_content.dart';
import 'package:openup/voice_call_screen_content.dart';

part 'call_screen.freezed.dart';

/// Page on which the [Phone] is used to do voice and video calls. Calls
/// start, proceed and end here.
class CallScreen extends ConsumerStatefulWidget {
  final String rid;
  final String host;
  final int socketPort;
  final bool video;
  final List<PublicProfile> profiles;
  final List<Rekindle> rekindles;

  const CallScreen({
    Key? key,
    required this.rid,
    required this.host,
    required this.socketPort,
    required this.video,
    required this.profiles,
    required this.rekindles,
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

  @override
  void initState() {
    super.initState();

    final auth = FirebaseAuth.instance;
    final uid = auth.currentUser?.uid;
    if (uid == null) {
      throw 'User is not logged in';
    }

    _signalingChannel = SocketIoSignalingChannel(
      host: widget.host,
      port: widget.socketPort,
      uid: uid,
      rid: widget.rid,
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
        onDisconnected: _navigateToRekindleOrPop,
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
      );
      final userConnection = UserConnection(
        profile: profile,
        rekindle: widget.rekindles.firstWhereOrNull(
          (r) => r.uid == profile.uid,
        ),
        localVideoRenderer: null,
        videoRenderer: null,
        connectionState: PhoneConnectionState.none,
      );
      _users[profile.uid] = CallData(
        phone: phone,
        userConnection: userConnection,
      );
    }

    _unrequestedConnections.addAll(widget.rekindles);

    _endTime = DateTime.now().add(const Duration(seconds: 90));

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
      }));
    }
    _users.values.first.phone
        .join(initiator: _isInitiator(uid, _users.keys.first));
  }

  @override
  void dispose() {
    _signalingChannel.dispose();
    _connectionStateSubscriptions.map((s) => s.cancel()).toList();
    _users.values.map((e) {
      e.phone.dispose();
    }).toList();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.video) {
      return VideoCallScreenContent(
        localRenderer: _users.values.first.userConnection.localVideoRenderer,
        users: _users.values.map((data) => data.userConnection).toList(),
        hasSentTimeRequest: _hasSentTimeRequest,
        endTime: widget.rekindles.isEmpty ? null : _endTime,
        muted: _muted,
        onTimeUp: _navigateToRekindleOrPop,
        onHangUp: () {
          _signalingChannel.send(const HangUp());
          _navigateToRekindleOrPop();
        },
        onConnect: _connect,
        onReport: _report,
        onSendTimeRequest: _sendTimeRequest,
        onToggleMute: () =>
            _users.values.forEach((element) => element.phone.toggleMute()),
      );
    } else {
      return VoiceCallScreenContent(
        users: _users.values.map((data) => data.userConnection).toList(),
        hasSentTimeRequest: _hasSentTimeRequest,
        endTime: widget.rekindles.isEmpty ? null : _endTime,
        muted: _muted,
        speakerphone: _speakerphone,
        onTimeUp: _navigateToRekindleOrPop,
        onHangUp: () {
          _signalingChannel.send(const HangUp());
          _navigateToRekindleOrPop();
        },
        onConnect: _connect,
        onReport: _report,
        onSendTimeRequest: _sendTimeRequest,
        onToggleMute: () =>
            _users.values.forEach((element) => element.phone.toggleMute()),
        onToggleSpeakerphone: () => _users.values
            .forEach((element) => element.phone.toggleSpeakerphone()),
      );
    }
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

  void _connect(String uid) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) {
      return;
    }

    final usersApi = ref.read(usersApiProvider);
    usersApi.addConnectionRequest(myUid, uid);
    final callData = _users[uid];
    if (callData != null) {
      setState(() {
        _users[uid] = callData.copyWith.userConnection(rekindle: null);
      });
    }
    setState(() => _unrequestedConnections.removeWhere((r) => r.uid == uid));
  }

  void _report(String uid) {
    // TODO
  }

  void _navigateToRekindleOrPop() {
    if (_unrequestedConnections.isEmpty) {
      Navigator.pop(context);
    } else {
      Navigator.of(context).pushReplacementNamed(
        'precached-rekindle',
        arguments: PrecachedRekindleScreenArguments(
          rekindles: _unrequestedConnections.toList(),
          title: 'meet people',
        ),
      );
    }
  }

  bool _isInitiator(String myUid, String theirUid) =>
      myUid.compareTo(theirUid) < 0;
}

String connectionStateText({
  required PhoneConnectionState connectionState,
  required String name,
}) {
  switch (connectionState) {
    case PhoneConnectionState.none:
      return '';

    case PhoneConnectionState.waiting:
      return 'Waiting for $name';

    case PhoneConnectionState.declined:
      return '$name did not join';

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
    required PublicProfile profile,
    required Rekindle? rekindle,
    required RTCVideoRenderer? localVideoRenderer,
    required RTCVideoRenderer? videoRenderer,
    required PhoneConnectionState connectionState,
  }) = _UserConnection;
}

class CallPageArguments {
  final String rid;
  final List<PublicProfile> profiles;
  final List<Rekindle> rekindles;

  CallPageArguments({
    required this.rid,
    required this.profiles,
    required this.rekindles,
  });
}
