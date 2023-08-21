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
    required DateTime date,
    required String uid,
    required Map<String, ReactionType> reactions,
    required MessageContent content,
  }) = _ChatMessage;

  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);
}

enum ReactionType { laugh, love, shock }

@freezed
class MessageContent with _$MessageContent {
  const factory MessageContent.audio({
    required ChatType type,
    required String url,
    @Default(Duration(seconds: 1))
    @JsonKey(name: "durationMicros")
    @DurationConverter()
    Duration duration,
    @Default(null) AudioMessageWaveform? waveform,
  }) = _AudioMessageContent;

  factory MessageContent.fromJson(Map<String, dynamic> json) =>
      _$MessageContentFromJson(json);
}

@freezed
class AudioMessageWaveform with _$AudioMessageWaveform {
  const factory AudioMessageWaveform({
    required List<double> values,
  }) = _AudioMessageWaveform;

  factory AudioMessageWaveform.fromJson(Map<String, dynamic> json) =>
      _$AudioMessageWaveformFromJson(json);
}

class DurationConverter implements JsonConverter<Duration, int> {
  const DurationConverter();

  @override
  Duration fromJson(int durationMicros) =>
      Duration(microseconds: durationMicros);

  @override
  int toJson(Duration duration) => duration.inMicroseconds;
}

enum ChatType {
  audio,
}
