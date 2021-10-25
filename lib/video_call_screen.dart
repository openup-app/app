import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:openup/api/signaling/signaling.dart';
import 'package:openup/api/signaling/socket_io_signaling_channel.dart';
import 'package:openup/api/users/profile.dart';
import 'package:openup/rekindle_screen.dart';
import 'package:openup/widgets/app_lifecycle.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/api/signaling/phone.dart';
import 'package:openup/widgets/theming.dart';
import 'package:openup/widgets/time_remaining.dart';

/// Page on which the [Phone] is used. Calls start, proceed and end here.
class VideoCallScreen extends StatefulWidget {
  final String uid;
  final String signalingHost;
  final bool initiator;
  final List<PublicProfile> profiles;

  const VideoCallScreen({
    Key? key,
    required this.uid,
    required this.signalingHost,
    required this.initiator,
    required this.profiles,
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

  bool _showingControls = true;

  @override
  void initState() {
    _signalingChannel = SocketIoSignalingChannel(
      host: widget.signalingHost,
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
            child: AppLifecycle(
              onResumed: () => _phone.videoEnabled = true,
              onPaused: () => _phone.videoEnabled = false,
              child: GestureDetector(
                onTap: () =>
                    setState(() => _showingControls = !_showingControls),
                child: RTCVideoView(
                  _remoteRenderer!,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                ),
              ),
            ),
          ),
        AnimatedPositioned(
          left: _showingControls ? 16.0 : -(56.0 + 16.0),
          top: MediaQuery.of(context).padding.top + 32.0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
          child: _CallControlButton(
            onPressed: () {},
            scrimColor: const Color.fromARGB(0xFF, 0xFF, 0x00, 0x00),
            size: 56,
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
                      onTimeUp: _navigateToRekindle,
                      builder: (context, remaining) {
                        return Text(
                          remaining,
                          style: Theming.of(context).text.body.copyWith(
                            fontWeight: FontWeight.normal,
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
        AnimatedPositioned(
          left: 0.0,
          right: 0.0,
          bottom: _showingControls
              ? MediaQuery.of(context).padding.bottom + 16.0
              : -(60.0 + 16),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
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
                        Radius.circular(32),
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
                    _CallControlButton(
                      onPressed: _phone.toggleMute,
                      size: 56,
                      child: _muted
                          ? const Icon(Icons.mic_off)
                          : const Icon(Icons.mic),
                    ),
                    _CallControlButton(
                      onPressed: () {
                        _signalingChannel.send(const HangUp());
                        _navigateToRekindle();
                      },
                      scrimColor: const Color.fromARGB(0xFF, 0xFF, 0x00, 0x00),
                      gradientColor:
                          const Color.fromARGB(0xFF, 0xFF, 0x88, 0x88),
                      size: 66,
                      child: const Icon(
                        Icons.call_end,
                        size: 40,
                      ),
                    ),
                    _CallControlButton(
                      onPressed: () {},
                      size: 56,
                      child: const Icon(Icons.person_add),
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

  void _navigateToRekindle() {
    Navigator.of(context).pushReplacementNamed(
      'rekindle',
      arguments: RekindleScreenArguments(
        profiles: widget.profiles,
        index: 0,
      ),
    );
  }
}

class _CallControlButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Color scrimColor;
  final Color? gradientColor;
  final double size;
  final Widget child;

  const _CallControlButton({
    Key? key,
    required this.onPressed,
    this.scrimColor = Colors.white,
    this.gradientColor,
    required this.size,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Button(
      onPressed: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Theming.of(context).shadow,
              offset: const Offset(0.0, 4.0),
              blurRadius: 1.0,
            ),
          ],
          gradient: gradientColor == null
              ? null
              : RadialGradient(
                  colors: [
                    scrimColor,
                    gradientColor!,
                  ],
                  stops: const [0.7, 1.0],
                ),
          color: scrimColor.withOpacity(0.4),
        ),
        child: IconTheme(
          data: IconTheme.of(context).copyWith(
            color: Colors.white,
            size: 32,
          ),
          child: child,
        ),
      ),
    );
  }
}

class CallPageArguments {
  final String uid;
  final bool initiator;
  final List<PublicProfile> profiles;

  CallPageArguments({
    required this.uid,
    required this.initiator,
    required this.profiles,
  });
}
