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
    required String uid,
    required String chatroomId,
    required this.onMessage,
    required this.onConnectionError,
  }) {
    _socket = io(
      'http://$host',
      OptionBuilder()
          .setTimeout(1500)
          .setTransports(['websocket'])
          .setPath('/chat')
          .enableForceNew()
          .disableReconnection()
          .setQuery({'uid': uid, 'chatroomId': chatroomId})
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

  void sendMessage(ChatType type, String content) {
    _socket.emit(
      'chat_message',
      jsonEncode({
        'type': describeEnum(type),
        'content': content,
      }),
    );
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
    required String uid,
    required DateTime date,
    required ChatType type,
    required String content,
  }) = ChatMessage;

  factory _ChatEvent.fromJson(Map<String, dynamic> json) =>
      _$_ChatEventFromJson(json);
}

enum ChatType {
  emoji,
  image,
  video,
  audio,
}
