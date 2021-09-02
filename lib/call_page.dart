import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:openup/phone.dart';
import 'package:openup/phone_status.dart';
import 'package:openup/signaling/signaling.dart';
import 'package:openup/signaling/web_sockets_signaling_channel.dart';

/// Start and stop calls from this page.
class CallPage extends StatefulWidget {
  final String host;

  const CallPage({
    Key? key,
    required this.host,
  }) : super(key: key);

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  late final SignalingChannel _signalingChannel;
  late final Phone _phone;

  bool _preparing = false;
  bool _remoteReady = false;
  RTCVideoRenderer? _localRenderer;
  RTCVideoRenderer? _remoteRenderer;

  late final String _nickname;
  final _nicknameController = TextEditingController();

  @override
  void initState() {
    _nickname = DateTime.now().microsecond.toString().padLeft(3, '0');

    _signalingChannel = WebSocketsSignalingChannel(
      host: widget.host,
    );
    _phone = Phone(
      signalingChannel: _signalingChannel,
      nickname: _nickname,
    );
    _phone.status.listen(_handlePhoneStatus);
    super.initState();

    _nicknameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _phone.hangUp().then((_) => _signalingChannel.dispose());
    _nicknameController.dispose();
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
          setState(() {
            _remoteRenderer?.srcObject = remoteStreamReady.stream;
            _remoteReady = true;
          });
        }
      },
      ended: (_) {
        if (mounted) {
          setState(() => _remoteReady = false);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Call prototype'),
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
              const SizedBox(height: 8),
              Text('Your number is: $_nickname'),
              const SizedBox(height: 8),
              SizedBox(
                width: 200,
                child: TextField(
                  controller: _nicknameController,
                  keyboardType: TextInputType.number,
                  maxLength: 3,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    hintText: 'Enter number to call',
                    counterText: '',
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    label: const Text('Call'),
                    icon: const Icon(Icons.call),
                    onPressed: _nicknameController.text.isEmpty
                        ? null
                        : () {
                            final nickname = _nicknameController.text;
                            _phone.call(nickname);
                          },
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    label: const Text('End call'),
                    icon: const Icon(Icons.call_end),
                    onPressed: _remoteReady ? _phone.hangUp : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
