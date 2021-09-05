import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:openup/phone.dart';
import 'package:openup/phone_status.dart';

/// Page on which the [Phone] is used. Calls start, proceed and end here.
class CallPage extends StatefulWidget {
  final Phone phone;
  final bool initiator;

  const CallPage({
    Key? key,
    required this.phone,
    required this.initiator,
  }) : super(key: key);

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  bool _preparing = false;
  RTCVideoRenderer? _localRenderer;
  RTCVideoRenderer? _remoteRenderer;

  @override
  void initState() {
    widget.phone.status.listen(_handlePhoneStatus);
    if (widget.initiator) {
      widget.phone.call();
    } else {
      widget.phone.answer();
    }

    super.initState();
  }

  @override
  void dispose() {
    widget.phone.hangUp();
    super.dispose();
  }

  void _handlePhoneStatus(PhoneStatus status) {
    status.map(
      preparingMedia: (_) {
        if (mounted) {
          setState(() => _preparing = true);
        }
      },
      mediaReady: (media) {
        if (mounted) {
          setState(() {
            _preparing = false;
            _localRenderer = media.localVideo;
            _remoteRenderer = media.remoteVideo;
          });
        }
      },
      remoteStreamReady: (remoteStreamReady) {
        if (mounted) {
          setState(() => _remoteRenderer?.srcObject = remoteStreamReady.stream);
        }
      },
      ended: (_) => Navigator.of(context).pop(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ongoing call'),
      ),
      body: Center(
        child: Stack(
          children: [
            if (_remoteRenderer != null)
              Positioned.fill(
                child: RTCVideoView(
                  _remoteRenderer!,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
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
                          color: Colors.blue,
                          borderRadius: BorderRadius.all(
                            Radius.circular(16),
                          ),
                        ),
                        clipBehavior: Clip.hardEdge,
                        constraints: const BoxConstraints(
                          maxWidth: 100,
                          maxHeight: 200,
                        ),
                        child: RTCVideoView(
                          _localRenderer!,
                          mirror: true,
                          objectFit:
                              RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _ScrimIconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.mic_off),
                        ),
                        _ScrimIconButton(
                          onPressed: () {
                            widget.phone.hangUp();
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
        ),
      ),
    );
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
