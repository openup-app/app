import 'dart:async';
import 'dart:convert';

import 'package:flutter/rendering.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:openup/api/users/profile.dart';
import 'package:openup/api/users/rekindle.dart';
import 'package:socket_io_client/socket_io_client.dart';

part 'lobby_api.freezed.dart';
part 'lobby_api.g.dart';

/// Handle callbacks to participate in a call, dispose to leave the lobby.
class LobbyApi {
  late final Socket _socket;
  final void Function(
          String rid, List<PublicProfile> public, List<Rekindle> rekindles)
      onJoinCall;
  final VoidCallback onConnectionError;

  LobbyApi({
    required String host,
    required int socketPort,
    required String uid,
    required bool video,
    required Purpose purpose,
    required this.onJoinCall,
    required this.onConnectionError,
  }) {
    _socket = io(
      'http://$host:$socketPort/lobby',
      OptionBuilder()
          .setTimeout(1500)
          .setTransports(['websocket'])
          .enableForceNew()
          .disableReconnection()
          .setQuery({
            'uid': uid,
            'lobby_type': purpose == Purpose.friends ? 'friends' : 'dating',
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
      joinCall: (event) =>
          onJoinCall(event.rid, event.profiles, event.rekindles),
    );
  }
}

@freezed
class _LobbyEvent with _$_LobbyEvent {
  const factory _LobbyEvent.joinCall({
    required String rid,
    required List<PublicProfile> profiles,
    required List<Rekindle> rekindles,
  }) = _JoinCall;

  factory _LobbyEvent.fromJson(Map<String, dynamic> json) =>
      _$_LobbyEventFromJson(json);
}

enum Purpose {
  friends,
  dating,
}
