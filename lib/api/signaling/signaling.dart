import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:openup/api/users/profile.dart';

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

  const factory Signal.hangUpReport({
    @Default('room') String recipient,
    required String uidToReport,
  }) = HangUpReport;

  const factory Signal.reject({
    @Default('room') String recipient,
    required String rid,
  }) = Reject;

  const factory Signal.roomNotFound({
    @Default('room') String recipient,
    required String rid,
  }) = RoomNotFound;

  const factory Signal.groupCallLobbyReady({
    @Default('room') String recipient,
    required bool ready,
  }) = GroupCallLobbyReady;

  const factory Signal.groupCallLobbyReadyStates({
    @Default('room') String recipient,
    required Map<String, bool> readyStates,
  }) = _GroupCallLobbyReadyStates;

  const factory Signal.joinCall({
    @Default('room') String recipient,
    required String rid,
    required List<SimpleProfile> profiles,
  }) = _JoinCall;

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
