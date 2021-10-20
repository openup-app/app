import 'dart:async';
import 'dart:convert';

import 'package:flutter/rendering.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:openup/api/users/profile.dart';
import 'package:socket_io_client/socket_io_client.dart';

part 'lobby_api.freezed.dart';
part 'lobby_api.g.dart';

/// Handle callbacks to participate in a call, dispose to leave the lobby.
class LobbyApi {
  late final Socket _socket;
  final void Function(List<PublicProfile> profiles) onMakeCall;
  final void Function(List<PublicProfile> profile) onReceiveCall;
  final VoidCallback onConnectionError;

  LobbyApi({
    required String host,
    required String uid,
    required bool video,
    required this.onMakeCall,
    required this.onReceiveCall,
    required this.onConnectionError,
  }) {
    _socket = io(
      'http://$host',
      OptionBuilder()
          .setTimeout(1500)
          .setTransports(['websocket'])
          .setPath('/lobby')
          .enableForceNew()
          .disableReconnection()
          .setQuery({
            'uid': uid,
            'lobby_type': 'friends',
            'video': video,
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
    final lobbyEvent = _LobbyEvent.fromJson(json);
    lobbyEvent.map(
      makeCall: (event) => onMakeCall(event.profiles),
      answerCall: (event) => onReceiveCall(event.profiles),
    );
  }
}

@freezed
class _LobbyEvent with _$_LobbyEvent {
  const factory _LobbyEvent.makeCall({
    required List<PublicProfile> profiles,
  }) = _MakeCall;

  const factory _LobbyEvent.answerCall({
    required List<PublicProfile> profiles,
  }) = _AnswerCall;

  factory _LobbyEvent.fromJson(Map<String, dynamic> json) =>
      _$_LobbyEventFromJson(json);
}
