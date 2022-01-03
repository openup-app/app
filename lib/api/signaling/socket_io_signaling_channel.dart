import 'dart:async';
import 'dart:convert';

import 'package:openup/api/signaling/signaling.dart';
import 'package:socket_io_client/socket_io_client.dart';

class SocketIoSignalingChannel implements SignalingChannel {
  final _controller = StreamController<Signal>();

  late final Socket _socket;

  SocketIoSignalingChannel({
    required String host,
    required int port,
    required String uid,
    required String rid,
  }) {
    _socket = io(
      'http://$host:$port/call',
      OptionBuilder()
          .setTimeout(1500)
          .setTransports(['websocket'])
          .enableForceNew()
          .disableReconnection()
          .setQuery({'uid': uid, 'rid': uid})
          .build(),
    );
    _socket.onConnectError((_) {
      print('Connection error');
    });
    _socket.onDisconnect((_) {
      print('Disconnect');
    });
    _socket.on('message', (message) {
      final payload = message as String;
      _handleSignal(payload);
    });
  }

  @override
  Future<void> dispose() async {
    _socket.dispose();
    await _controller.close();
  }

  @override
  Stream<Signal> get signals => _controller.stream;

  @override
  void send(Signal signal) =>
      _socket.emit('message', jsonEncode(signal.toJson()));

  void _handleSignal(String message) {
    final json = jsonDecode(message);
    final signal = Signal.fromJson(json);
    _controller.add(signal);
  }
}
