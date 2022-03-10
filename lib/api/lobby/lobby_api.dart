import 'dart:async';
import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:openup/api/users/profile.dart';
import 'package:openup/api/users/rekindle.dart';
import 'package:rxdart/rxdart.dart';
import 'package:socket_io_client/socket_io_client.dart';

part 'lobby_api.freezed.dart';
part 'lobby_api.g.dart';

/// Handle callbacks to participate in a call, dispose to leave the lobby.
class LobbyApi {
  late final Socket _socket;
  final _eventController = BehaviorSubject<LobbyEvent>();

  LobbyApi({
    required String host,
    required int socketPort,
    required String uid,
    required bool video,
    required bool serious,
    required Purpose purpose,
  }) {
    _socket = io(
      'http://$host:$socketPort/lobby',
      OptionBuilder()
          .setTimeout(1500)
          .setTransports(['websocket'])
          .enableForceNew()
          .disableAutoConnect()
          .setQuery({
            'uid': uid,
            'lobby_type': purpose == Purpose.friends ? 'friends' : 'dating',
            'video': video,
            'serious': serious,
          })
          .build(),
    );

    _socket.onConnectError((_) {
      _eventController.add(const _ConnectionError());
    });

    _socket.onDisconnect((_) {
      _eventController.add(const _Disconnected());
    });

    _socket.on('message', (message) {
      final messageList = message as List<dynamic>;
      final payload = messageList[1];
      _handleMessage(payload);
    });
  }

  void connect() {
    _socket.connect();
  }

  Future<void> dispose() {
    _socket.dispose();
    return _eventController.close();
  }

  Stream<LobbyEvent> get eventStream => _eventController.stream;

  void _handleMessage(String message) {
    final json = jsonDecode(message);
    final lobbyEvent = LobbyEvent.fromJson(json);
    _eventController.add(lobbyEvent);
  }
}

@freezed
class LobbyEvent with _$LobbyEvent {
  const factory LobbyEvent.connectionError() = _ConnectionError;

  const factory LobbyEvent.disconnected() = _Disconnected;

  const factory LobbyEvent.penalized({
    required int minutes,
  }) = _Penalized;

  const factory LobbyEvent.joinCall({
    required String rid,
    required List<Profile> profiles,
    required List<Rekindle> rekindles,
  }) = _JoinCall;

  factory LobbyEvent.fromJson(Map<String, dynamic> json) =>
      _$LobbyEventFromJson(json);
}

enum Purpose {
  friends,
  dating,
}
