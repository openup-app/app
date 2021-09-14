import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:openup/button.dart';
import 'package:openup/phone.dart';
import 'package:openup/signaling/signaling.dart';
import 'package:openup/signaling/web_sockets_signaling_channel.dart';
import 'package:openup/theming.dart';
import 'package:openup/time_remaining.dart';

/// Page on which the [Phone] is used. Calls start, proceed and end here.
class VideoCallScreen extends StatefulWidget {
  final String uid;
  final String signalingHost;
  final bool initiator;

  const VideoCallScreen({
    Key? key,
    required this.uid,
    required this.signalingHost,
    required this.initiator,
  }) : super(key: key);

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  late final SignalingChannel _signalingChannel;
  late final Phone _phone;

  RTCVideoRenderer? _localRenderer;
  RTCVideoRenderer? _remoteRenderer;
  bool _muted = false;

  bool _hasSentTimeRequest = false;
  late DateTime _endTime;

  @override
  void initState() {
    _signalingChannel = WebSocketsSignalingChannel(
      host: widget.signalingHost,
      uid: widget.uid,
    );
    _phone = Phone(
      video: true,
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
      onDisconnected: Navigator.of(context).pop,
      onToggleMute: (muted) => setState(() => _muted = muted),
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
    return Stack(
      children: [
        if (_remoteRenderer != null)
          Positioned.fill(
            child: RTCVideoView(
              _remoteRenderer!,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            ),
          ),
        Align(
          alignment: Alignment.topLeft,
          child: SafeArea(
            top: true,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Button(
                onPressed: () {},
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Theming.of(context).shadow,
                        offset: const Offset(0.0, 4.0),
                        blurRadius: 1.0,
                      ),
                    ],
                    color: const Color.fromARGB(0xFF, 0xDC, 0x5C, 0x5A),
                  ),
                  child: Center(
                    child: Text(
                      'R',
                      style: Theming.of(context).text.body.copyWith(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: SafeArea(
            top: true,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Button(
                onPressed: _hasSentTimeRequest ? null : _sendTimeRequest,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.alarm_add),
                    TimeRemaining(
                      endTime: _endTime,
                      onTimeUp: Navigator.of(context).pop,
                      builder: (context, remaining) {
                        return Text(
                          remaining,
                          style: Theming.of(context).text.body.copyWith(
                            shadows: [
                              Shadow(color: Theming.of(context).shadow)
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (_localRenderer != null)
                Container(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    alignment: Alignment.bottomRight,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.all(
                        Radius.circular(16),
                      ),
                    ),
                    clipBehavior: Clip.hardEdge,
                    constraints: const BoxConstraints(
                      maxWidth: 100,
                      maxHeight: 200,
                    ),
                    child: Opacity(
                      opacity: 0.5,
                      child: RTCVideoView(
                        _localRenderer!,
                        mirror: true,
                        objectFit:
                            RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _ScrimIconButton(
                      onPressed: _phone.toggleMute,
                      icon: _muted
                          ? const Icon(Icons.mic_off)
                          : const Icon(Icons.mic),
                    ),
                    _ScrimIconButton(
                      onPressed: () {
                        _signalingChannel.send(const HangUp());
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.call_end),
                      scrimColor: Colors.red,
                    ),
                    _ScrimIconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.person_add),
                    ),
                  ],
                ),
              )
            ],
          ),
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
      _endTime = _endTime.add(duration);
      _hasSentTimeRequest = false;
    });
  }
}

class _ScrimIconButton extends StatelessWidget {
  final Icon icon;
  final VoidCallback onPressed;
  final Color scrimColor;

  const _ScrimIconButton({
    Key? key,
    required this.icon,
    required this.onPressed,
    this.scrimColor = Colors.white,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: const AlwaysStoppedAnimation(1.1),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(32)),
          color: scrimColor.withOpacity(0.4),
        ),
        child: IconButton(
          onPressed: onPressed,
          icon: icon,
          color: Colors.white,
        ),
      ),
    );
  }
}

class CallPageArguments {
  final String uid;
  final bool initiator;

  CallPageArguments({
    required this.uid,
    required this.initiator,
  });
}
