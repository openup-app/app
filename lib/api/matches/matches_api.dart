import 'dart:async';
import 'dart:convert';

import 'package:flutter/rendering.dart';
import 'package:openup/api/users/preferences.dart';
import 'package:rxdart/subjects.dart';
import 'package:socket_io_client/socket_io_client.dart';

/// Information about how many matching users are online.
class MatchesApi {
  late final Socket _socket;
  final _countController = BehaviorSubject<int>();

  MatchesApi({
    required String host,
    required int port,
    required Preferences preferences,
    required VoidCallback onConnectionError,
  }) {
    _socket = io(
      'http://$host:$port/matches',
      OptionBuilder()
          .setTimeout(1500)
          .setTransports(['websocket'])
          .enableForceNew()
          .setQuery({'preferences': jsonEncode(preferences)})
          .build(),
    );

    _socket.onConnectError((_) {
      onConnectionError();
    });

    _socket.on('message', (message) {
      final payload = Map<String, dynamic>.of(message);
      final count = payload['count'];
      print('count is $count');
      _countController.add(count);
    });
  }

  Future<void> dispose() {
    _socket.dispose();
    _countController.close();
    return Future.value();
  }

  Stream<int> get countStream => _countController.stream;

  void sendPreferences(Preferences preferences) {
    _socket.emit('message', jsonEncode(preferences.toJson()));
  }
}
