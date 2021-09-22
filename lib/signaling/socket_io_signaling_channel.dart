import 'dart:async';
import 'dart:convert';

import 'package:openup/signaling/signaling.dart';
import 'package:socket_io_client/socket_io_client.dart';

class SocketIoSignalingChannel implements SignalingChannel {
  final _controller = StreamController<Signal>.broadcast();

  late final Socket _socket;

  SocketIoSignalingChannel({
    required String host,
    required String uid,
  }) {
    _socket = io(
      'http://$host',
      OptionBuilder()
          .setTimeout(1500)
          .setTransports(['websocket'])
          .setPath('/call')
          .enableForceNew()
          .disableReconnection()
          .setQuery({'uid': uid})
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
