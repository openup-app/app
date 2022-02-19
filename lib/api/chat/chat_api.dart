import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart';

part 'chat_api.freezed.dart';
part 'chat_api.g.dart';

/// Handle chatrooms, dispose to leave the chatroom.
class ChatApi {
  final _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  late final Socket _socket;
  final void Function(ChatMessage message) onMessage;
  final VoidCallback onConnectionError;
  final String _urlBase;

  ChatApi({
    required String host,
    required int webPort,
    required int socketPort,
    required String authToken,
    required String uid,
    required String chatroomId,
    required this.onMessage,
    required this.onConnectionError,
  }) : _urlBase = 'http://$host:$webPort' {
    _headers['Authorization'] = 'Bearer $authToken';

    _socket = io(
      'http://$host:$socketPort/chats',
      OptionBuilder()
          .setTimeout(1500)
          .setTransports(['websocket'])
          .enableForceNew()
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

  void _handleMessage(String message) {
    final json = jsonDecode(message);
    final data = json['message'];
    final chatEvent = _ChatEvent.fromJson(data);
    chatEvent.map(
      chatMessage: (event) => onMessage(event),
    );
  }

  Future<ChatMessage> sendMessage(
    String uid,
    String chatroomId,
    ChatType type,
    String content,
  ) async {
    final uri = Uri.parse('$_urlBase/chats/$chatroomId');
    final int statusCode;
    final String body;
    switch (type) {
      case ChatType.emoji:
        final response = await http.post(
          uri,
          headers: _headers,
          body: jsonEncode({
            'uid': uid,
            'type': type.name,
            'content': content,
          }),
        );
        statusCode = response.statusCode;
        body = response.body;
        break;
      case ChatType.image:
      case ChatType.video:
      case ChatType.audio:
        final request = http.MultipartRequest('POST', uri);
        request.headers.addAll(_headers);
        request.fields['uid'] = uid;
        request.fields['type'] = type.name;
        request.files.add(
          await http.MultipartFile.fromPath(
            'media',
            content,
          ),
        );
        final response = await request.send();
        statusCode = response.statusCode;
        body = await response.stream.bytesToString();
        break;
    }

    if (statusCode != 200) {
      if (statusCode == 400) {
        return Future.error('Failed to get send message $body');
      }
      print('Error $statusCode: $body');
      return Future.error('Failure');
    }

    return ChatMessage.fromJson(jsonDecode(body));
  }

  Future<List<ChatMessage>> getMessages(
    String chatroomId, {
    DateTime? startDate,
    int limit = 10,
  }) async {
    final query =
        '${startDate == null ? '' : 'startDate=${startDate.toIso8601String()}&'}limit=$limit';
    final response = await http.get(
      Uri.parse('$_urlBase/chats/$chatroomId?$query'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      if (response.statusCode == 400) {
        return Future.error('Failed to get connections');
      }
      print('Error ${response.statusCode}: ${response.body}');
      return Future.error('Failure');
    }

    final list = jsonDecode(response.body) as List<dynamic>;
    return List<ChatMessage>.from(list.map((e) => ChatMessage.fromJson(e)));
  }
}

@freezed
class _ChatEvent with _$_ChatEvent {
  const factory _ChatEvent.chatMessage({
    String? messageId,
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
