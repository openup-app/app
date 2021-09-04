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
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _preparing
                          ? const Center(
                              child: CircularProgressIndicator(),
                            )
                          : Container(
                              decoration: BoxDecoration(border: Border.all()),
                              child: _localRenderer != null
                                  ? RTCVideoView(_localRenderer!, mirror: true)
                                  : null,
                            ),
                    ),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(border: Border.all()),
                        child: _remoteRenderer != null
                            ? RTCVideoView(_remoteRenderer!)
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
