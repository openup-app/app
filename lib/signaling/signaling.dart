import 'package:freezed_annotation/freezed_annotation.dart';

part 'signaling.freezed.dart';
part 'signaling.g.dart';

/// Commands used for signaling.
@freezed
class Signal with _$Signal {
  const factory Signal.beginSignaling({
    required String uid,
  }) = BeginSignaling;

  const factory Signal.sessionDescription({
    required String uid,
    String? sdp,
    String? type,
  }) = SessionDescription;

  const factory Signal.iceCandidate({
    required String uid,
    String? candidate,
    String? sdpMid,
    int? sdpMLineIndex,
  }) = IceCandidate;

  factory Signal.fromJson(Map<String, dynamic> json) => _$SignalFromJson(json);
}

/// Interface for performing WebRTC signaling.
abstract class SignalingChannel {
  Future<void> dispose();
  Stream<Signal> get signals;
  void send(Signal signal);
}
