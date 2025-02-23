import 'dart:async';
import 'dart:convert';

import 'package:socket_io_client/socket_io_client.dart';

/// Socket connection for push messages from the server while app is open.
class InAppNotificationsApi {
  late final Socket _socket;

  InAppNotificationsApi({
    required String host,
    required int port,
    required String uid,
    required void Function(String collectionId) onCollectionReady,
    required void Function(int count) onUnreadCountUpdated,
  }) {
    _socket = io(
      'http://$host:$port/notifications',
      OptionBuilder()
          .setTimeout(1500)
          .setTransports(['websocket'])
          .enableForceNew()
          .setQuery({'uid': uid})
          .build(),
    );

    _socket.on('message', (message) {
      final json = jsonDecode(message as String);
      final type = json['type'];
      if (type == 'collection_ready') {
        final collectionId = json['collectionId'] as String;
        onCollectionReady(collectionId);
      } else if (type == 'unread_chats_count') {
        final unreadCount = json['count'] as int;
        onUnreadCountUpdated(unreadCount);
      }
    });
  }

  Future<void> dispose() {
    _socket.dispose();
    return Future.value();
  }
}
