import 'dart:math';

import 'package:flutter/material.dart';
import 'package:openup/call_api.dart';
import 'package:openup/call_page.dart';
import 'package:openup/phone.dart';
import 'package:openup/signaling/signaling.dart';
import 'package:openup/signaling/web_sockets_signaling_channel.dart';

/// Page on which you wait to be matched with another user.
class LobbyPage extends StatefulWidget {
  final String applicationHost;
  final String signalingHost;

  const LobbyPage({
    Key? key,
    required this.applicationHost,
    required this.signalingHost,
  }) : super(key: key);

  @override
  _LobbyPageState createState() => _LobbyPageState();
}

class _LobbyPageState extends State<LobbyPage> {
  late final String _uid;
  late final CallApi _callApi;
  Phone? _phone;
  SignalingChannel? _signalingChannel;

  @override
  void initState() {
    super.initState();
    _uid = Random().nextInt(1000000).toString().padLeft(7, '0');
    _callApi = CallApi(host: widget.applicationHost);
    _callApi.events.listen(_handleCallEvent);
    _callApi.register(_uid);
  }

  @override
  void dispose() {
    _callApi.dispose();
    _disposePhone();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: Navigator.of(context).pop,
        ),
      ),
      body: const Center(
        child: Text('Waiting for another user...'),
      ),
    );
  }

  void _handleCallEvent(CallEvent event) {
    event.map(
      makeCall: (_) => _startCall(initiator: true),
      answerCall: (_) => _startCall(initiator: false),
      callEnded: (_) {
        Navigator.of(context).pop();
        return _disposePhone();
      },
    );
  }

  void _startCall({required bool initiator}) {
    final signalingChannel = WebSocketsSignalingChannel(
      host: widget.signalingHost,
    );
    final phone = Phone(
      signalingChannel: signalingChannel,
      uid: _uid,
    );

    setState(() {
      _signalingChannel = _signalingChannel;
      _phone = phone;
    });

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return CallPage(
            phone: phone,
            initiator: initiator,
          );
        },
      ),
    );
  }

  Future<void> _disposePhone() async {
    _phone?.dispose().then((value) => setState(() {}));
    _signalingChannel?.dispose().then((value) => setState(() {}));
  }
}
