import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:socket_io_client/socket_io_client.dart';

part 'chat_api.freezed.dart';
part 'chat_api.g.dart';

/// Handle chatrooms, dispose to leave the chatroom.
class ChatApi {
  late final Socket _socket;
  final void Function(ChatMessage message) onMessage;
  final VoidCallback onConnectionError;

  ChatApi({
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
    final chatEvent = _ChatEvent.fromJson(data);
    chatEvent.map(
      chatMessage: (event) => onMessage(event),
    );
  }
}

@freezed
class _ChatEvent with _$_ChatEvent {
  const factory _ChatEvent.chatMessage({
    @Default(null) String? messageId,
    required String uid,
    required DateTime date,
    required ChatType type,
    required String content,
  }) = ChatMessage;

  factory _ChatEvent.fromJson(Map<String, dynamic> json) =>
      _$_ChatEventFromJson(json);
}

enum ChatType {
  audio,
}
