import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:openup/api/signaling/phone.dart';
import 'package:openup/api/signaling/signaling.dart';
import 'package:openup/api/users/profile.dart';
import 'package:rxdart/subjects.dart';

part 'call_state.freezed.dart';

class CallState {
  final _infoController = BehaviorSubject<CallInfo>.seeded(const NoCall());

  set callInfo(CallInfo value) => _infoController.add(value);

  CallInfo get callInfo => _infoController.value;

  Stream<CallInfo> get callInfoStream => _infoController.stream;
}

@freezed
class CallInfo with _$CallInfo {
  const factory CallInfo.active({
    required String rid,
    required SimpleProfile profile,
    required SignalingChannel signalingChannel,
    required Phone phone,
    required PhoneController controller,
  }) = ActiveCall;

  const factory CallInfo.none() = NoCall;
}
