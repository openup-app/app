import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

part 'call_api.freezed.dart';
part 'call_api.g.dart';

/// Application level calling API. Handle call related events sent on [events].
class CallApi {
  late final WebSocketChannel _channel;

  final _eventController = StreamController<CallEvent>.broadcast();

  CallApi({required String host}) {
    _channel = WebSocketChannel.connect(Uri.parse('ws://$host'));
    _channel.stream.listen(_handleMessage);
  }

  Future<void> dispose() async {
    await _channel.sink.close(status.goingAway);
    await _eventController.close();
  }

  Stream<CallEvent> get events => _eventController.stream;

  void register(String uid) => _send(_Register(uid));

  void _handleMessage(dynamic message) {
    message = message is Uint8List ? String.fromCharCodes(message) : message;
    final json = jsonDecode(message);
    final callEvent = CallEvent.fromJson(json);
    _eventController.add(callEvent);
  }

  void _send(_ClientMessage message) =>
      _channel.sink.add(jsonEncode(message.toJson()));
}

@freezed
class _ClientMessage with _$_ClientMessage {
  const factory _ClientMessage.register(String uid) = _Register;

  const factory _ClientMessage.hangUp() = _HangUp;

  factory _ClientMessage.fromJson(Map<String, dynamic> json) =>
      _$_ClientMessageFromJson(json);
}

@freezed
class CallEvent with _$CallEvent {
  const factory CallEvent.makeCall() = MakeCall;

  const factory CallEvent.answerCall() = AnswerCall;

  const factory CallEvent.callEnded() = CallEnded;

  factory CallEvent.fromJson(Map<String, dynamic> json) =>
      _$CallEventFromJson(json);
}
