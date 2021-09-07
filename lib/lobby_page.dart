import 'dart:math';

import 'package:flutter/material.dart';
import 'package:openup/call_api.dart';
import 'package:openup/call_page.dart';

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

  @override
  void initState() {
    super.initState();
    _uid = Random().nextInt(1000000).toString().padLeft(7, '0');
    _callApi = CallApi(
      host: widget.applicationHost,
      uid: _uid,
      onMakeCall: () => _startCall(initiator: true),
      onReceiveCall: () => _startCall(initiator: false),
    );
  }

  @override
  void dispose() {
    _callApi.dispose();
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

  void _startCall({required bool initiator}) async {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return CallPage(
            uid: _uid,
            signalingHost: widget.signalingHost,
            initiator: initiator,
          );
        },
      ),
    );
  }
}
