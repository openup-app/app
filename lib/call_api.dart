import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/rendering.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

part 'call_api.freezed.dart';
part 'call_api.g.dart';

/// Application level calling API. Handle callbacks to make and receive calls.
class CallApi {
  late final WebSocketChannel _channel;
  final VoidCallback onMakeCall;
  final VoidCallback onReceiveCall;

  CallApi({
    required String host,
    required String uid,
    required this.onMakeCall,
    required this.onReceiveCall,
  }) {
    _channel = WebSocketChannel.connect(Uri.parse('ws://$host/?uid=$uid'));
    _channel.stream.listen(_handleMessage);
  }

  Future<void> dispose() async {
    await _channel.sink.close(status.goingAway);
  }

  void _handleMessage(dynamic message) {
    message = message is Uint8List ? String.fromCharCodes(message) : message;
    final json = jsonDecode(message);
    final callEvent = _CallEvent.fromJson(json);
    callEvent.map(
      makeCall: (_) => onMakeCall(),
      answerCall: (_) => onReceiveCall(),
    );
  }
}

@freezed
class _CallEvent with _$_CallEvent {
  const factory _CallEvent.makeCall() = _MakeCall;

  const factory _CallEvent.answerCall() = _AnswerCall;

  factory _CallEvent.fromJson(Map<String, dynamic> json) =>
      _$_CallEventFromJson(json);
}
