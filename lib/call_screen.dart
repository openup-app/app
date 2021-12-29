import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:openup/api/signaling/signaling.dart';
import 'package:openup/api/signaling/socket_io_signaling_channel.dart';
import 'package:openup/api/users/profile.dart';
import 'package:openup/api/users/rekindle.dart';
import 'package:openup/rekindle_screen.dart';
import 'package:openup/video_call_screen_content.dart';
import 'package:openup/voice_call_screen_content.dart';
import 'package:openup/api/signaling/phone.dart';

/// Page on which the [Phone] is used to do voice and video calls. Calls
/// start, proceed and end here.
class CallScreen extends StatefulWidget {
  final String uid;
  final String host;
  final int socketPort;
  final bool initiator;
  final bool video;
  final List<PublicProfile> profiles;
  final List<Rekindle> rekindles;

  const CallScreen({
    Key? key,
    required this.uid,
    required this.host,
    required this.socketPort,
    required this.initiator,
    required this.video,
    required this.profiles,
    required this.rekindles,
  }) : super(key: key);

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  late final SignalingChannel _signalingChannel;
  late final Phone _phone;

  RTCVideoRenderer? _localRenderer;
  RTCVideoRenderer? _remoteRenderer;
  bool _muted = false;
  bool _speakerphone = false;

  bool _hasSentTimeRequest = false;
  late DateTime _endTime;

  @override
  void initState() {
    _signalingChannel = SocketIoSignalingChannel(
      host: widget.host,
      port: widget.socketPort,
      uid: widget.uid,
    );
    _phone = Phone(
      useVideo: true,
      signalingChannel: _signalingChannel,
      onMediaRenderers: (localRenderer, remoteRenderer) {
        setState(() {
          _localRenderer = localRenderer;
          _remoteRenderer = remoteRenderer;
        });
      },
      onRemoteStream: (stream) {
        setState(() => _remoteRenderer?.srcObject = stream);
      },
      onAddTimeRequest: () {
        setState(() => _hasSentTimeRequest = false);
      },
      onAddTime: _addTime,
      onDisconnected: _navigateToRekindle,
      onToggleMute: (muted) => setState(() => _muted = muted),
      onToggleSpeakerphone: (enabled) =>
          setState(() => _speakerphone = enabled),
    );

    if (widget.initiator) {
      _phone.call();
    } else {
      _phone.answer();
    }

    _endTime = DateTime.now().add(const Duration(seconds: 90));

    super.initState();
  }

  @override
  void dispose() {
    _signalingChannel.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.video) {
      return VideoCallScreenContent(
        localRenderer: _localRenderer,
        remoteRenderer: _remoteRenderer,
        hasSentTimeRequest: _hasSentTimeRequest,
        endTime: _endTime,
        muted: _muted,
        onTimeUp: _navigateToRekindle,
        onHangUp: () {
          _signalingChannel.send(const HangUp());
          _navigateToRekindle();
        },
        onSendTimeRequest: _sendTimeRequest,
        onToggleMute: _phone.toggleMute,
      );
    } else {
      return VoiceCallScreenContent(
        profiles: widget.profiles,
        hasSentTimeRequest: _hasSentTimeRequest,
        endTime: _endTime,
        muted: _muted,
        speakerphone: _speakerphone,
        onTimeUp: _navigateToRekindle,
        onHangUp: () {
          _signalingChannel.send(const HangUp());
          _navigateToRekindle();
        },
        onSendTimeRequest: _sendTimeRequest,
        onToggleMute: _phone.toggleMute,
        onToggleSpeakerphone: _phone.toggleSpeakerphone,
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
      _endTime = _endTime.add(duration);
      _hasSentTimeRequest = false;
    });
  }

  void _navigateToRekindle() {
    if (widget.rekindles.isEmpty) {
      Navigator.pop(context);
    } else {
      Navigator.of(context).pushReplacementNamed(
        'precached-rekindle',
        arguments: PrecachedRekindleScreenArguments(
          rekindles: widget.rekindles,
          title: 'meet people',
        ),
      );
    }
  }
}

class CallPageArguments {
  final String uid;
  final bool initiator;
  final List<PublicProfile> profiles;
  final List<Rekindle> rekindles;

  CallPageArguments({
    required this.uid,
    required this.initiator,
    required this.profiles,
    required this.rekindles,
  });
}
