import 'package:freezed_annotation/freezed_annotation.dart';

part 'signaling.freezed.dart';
part 'signaling.g.dart';

/// Commands used for signaling.
@freezed
class Signal with _$Signal {
  const factory Signal.sessionDescription({
    String? sdp,
    String? type,
  }) = SessionDescription;

  const factory Signal.iceCandidates(
    List<IceCandidate> iceCandidates,
  ) = IceCandidates;

  factory Signal.fromJson(Map<String, dynamic> json) => _$SignalFromJson(json);
}

@freezed
class IceCandidate with _$IceCandidate {
  const factory IceCandidate({
    String? candidate,
    String? sdpMid,
    int? sdpMLineIndex,
  }) = _IceCandidate;

  factory IceCandidate.fromJson(Map<String, dynamic> json) =>
      _$IceCandidateFromJson(json);
}

/// Interface for performing WebRTC signaling.
abstract class SignalingChannel {
  Future<void> dispose();
  Stream<Signal> get signals;
  void send(Signal signal);
}
