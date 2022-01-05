import 'package:freezed_annotation/freezed_annotation.dart';

part 'signaling.freezed.dart';
part 'signaling.g.dart';

/// Commands used for signaling.
@freezed
class Signal with _$Signal {
  const factory Signal.sessionDescription({
    required String recipient,
    String? sdp,
    String? type,
  }) = SessionDescription;

  const factory Signal.iceCandidates({
    required String recipient,
    required List<IceCandidate> iceCandidates,
  }) = IceCandidates;

  const factory Signal.addTimeRequest({
    @Default('room') String recipient,
  }) = AddTimeRequest;

  const factory Signal.addTime({
    @Default('room') String recipient,
    required int seconds,
  }) = AddTime;

  const factory Signal.hangUp({
    @Default('room') String recipient,
  }) = HangUp;

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
