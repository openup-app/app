import 'dart:async';
import 'dart:convert';

import 'package:flutter/rendering.dart';
import 'package:socket_io_client/socket_io_client.dart';

/// Socket connection for the duration of being opened and logged into the app.
class OnlineUsersApi {
  late final Socket _socket;

  OnlineUsersApi({
    required String host,
    required int port,
    required String uid,
    required VoidCallback onConnectionError,
    required void Function(String uid, bool online) onOnlineStatusChanged,
  }) {
    _socket = io(
      'http://$host:$port/online_users',
      OptionBuilder()
          .setTimeout(1500)
          .setTransports(['websocket'])
          .enableForceNew()
          .setQuery({'uid': uid})
          .build(),
    );

    _socket.onConnectError((_) {
      onConnectionError();
    });

    _socket.on('message', (message) {
      final json = jsonDecode(message as String);
      final type = json['type'];
      if (type == 'online_status') {
        final online = json['online'];
        final uid = json['uid'];
        onOnlineStatusChanged(uid, online);
      }
    });
  }

  void subscribeToOnlineStatus(String uid) {
    _socket.emit(
      'message',
      jsonEncode({
        'type': 'online_status_subscribe',
        'uid': uid,
      }),
    );
  }

  void unsubscribeToOnlineStatus(String uid) {
    _socket.emit(
      'message',
      jsonEncode({
        'type': 'online_status_unsubscribe',
        'uid': uid,
      }),
    );
  }

  Future<void> dispose() {
    _socket.dispose();
    return Future.value();
  }
}
