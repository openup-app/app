import 'package:freezed_annotation/freezed_annotation.dart';

part 'signaling.freezed.dart';
part 'signaling.g.dart';

/// Commands used for signaling.
@freezed
class Signal with _$Signal {
  const factory Signal.registerClient({
    required String nickname,
  }) = RegisterClient;

  const factory Signal.startCall({
    required String nickname,
  }) = StartCall;

  const factory Signal.answerCall() = AnswerCall;

  const factory Signal.endCall() = EndCall;

  const factory Signal.sessionDescription({
    String? sdp,
    String? type,
  }) = SessionDescription;

  const factory Signal.iceCandidate({
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
