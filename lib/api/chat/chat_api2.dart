import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:socket_io_client/socket_io_client.dart';

part 'chat_api2.freezed.dart';
part 'chat_api2.g.dart';

/// Handle chatrooms, dispose to leave the chatroom.
class ChatApi2 {
  late final Socket _socket;
  final void Function(ChatMessage2 message) onMessage;
  final VoidCallback onConnectionError;

  ChatApi2({
    required String host,
    required int socketPort,
    required String uid,
    required String otherUid,
    required this.onMessage,
    required this.onConnectionError,
  }) {
    _socket = io(
      'http://$host:$socketPort/chats',
      OptionBuilder()
          .setTimeout(1500)
          .setTransports(['websocket'])
          .enableForceNew()
          .setQuery({
            'uid': uid,
            'otherUid': otherUid,
          })
          .build(),
    );

    _socket.onConnectError((_) {
      onConnectionError();
    });

    _socket.on('message', (message) {
      final messageList = message as List<dynamic>;
      final payload = messageList[1];
      _handleMessage(payload);
    });
  }

  Future<void> dispose() {
    _socket.dispose();
    return Future.value();
  }

  void _handleMessage(String message) {
    final json = jsonDecode(message);
    final data = json['message'];
    final chatEvent = _ChatEvent2.fromJson(data);
    chatEvent.map(
      chatMessage: (event) => onMessage(event),
    );
  }
}

@freezed
class _ChatEvent2 with _$_ChatEvent2 {
  const factory _ChatEvent2.chatMessage({
    @Default(null) String? messageId,
    required String uid,
    required DateTime date,
    required ChatType2 type,
    required String content,
  }) = ChatMessage2;

  factory _ChatEvent2.fromJson(Map<String, dynamic> json) =>
      _$_ChatEvent2FromJson(json);
}

enum ChatType2 {
  audio,
}
