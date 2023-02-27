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
    final chatMessage = ChatMessage.fromJson(data);
    onMessage(chatMessage);
  }
}

@freezed
class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    @Default(null) String? messageId,
    required String uid,
    required DateTime date,
    required ChatType type,
    required String content,
    @JsonKey(name: "durationMillis")
    @DurationConverter()
        required Duration duration,
    required List<double> waveform,
  }) = _ChatMessage;

  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);
}

class DurationConverter implements JsonConverter<Duration, int> {
  const DurationConverter();

  @override
  Duration fromJson(int durationMillis) =>
      Duration(milliseconds: durationMillis);

  @override
  int toJson(Duration duration) => duration.inMilliseconds;
}

enum ChatType {
  audio,
}
