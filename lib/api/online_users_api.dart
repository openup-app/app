import 'dart:async';

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
  }) {
    _socket = io(
      'http://$host:$port/online_users',
      OptionBuilder()
          .setTimeout(3000)
          .setTransports(['websocket'])
          .enableForceNew()
          .setQuery({'uid': uid})
          .build(),
    );
    _socket.onConnectError((_) {
      onConnectionError();
    });
  }

  Future<void> dispose() {
    _socket.dispose();
    return Future.value();
  }
}
