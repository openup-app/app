import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:openup/signaling/signaling.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

/// Concrete implementation of a WebRTC signaling channel using
/// WebSockets as the transport.
class WebSocketsSignalingChannel implements SignalingChannel {
  final _controller = StreamController<Signal>.broadcast();

  late final WebSocketChannel _channel;

  WebSocketsSignalingChannel({
    required String host,
  }) {
    _channel = WebSocketChannel.connect(Uri.parse('ws://$host'));
    _channel.stream.listen(_handleSignal);
  }

  @override
  Future<void> dispose() => _channel.sink.close(status.goingAway);

  @override
  Stream<Signal> get signals => _controller.stream;

  @override
  void send(Signal signal) => _channel.sink.add(jsonEncode(signal.toJson()));

  void _handleSignal(dynamic message) {
    message = message is Uint8List ? String.fromCharCodes(message) : message;
    final json = jsonDecode(message);
    final signal = Signal.fromJson(json);
    _controller.add(signal);
  }
}
