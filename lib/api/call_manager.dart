import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:get_it/get_it.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/signaling/phone.dart';
import 'package:openup/api/signaling/signaling.dart';
import 'package:openup/api/users/profile.dart';
import 'package:openup/notifications/android_voip_handlers.dart'
    as android_voip;
import 'package:openup/notifications/ios_voip_handlers.dart' as ios_voip;
import 'package:rxdart/subjects.dart';

part 'call_manager.freezed.dart';

class CallManager {
  final _controller = BehaviorSubject<CallState>.seeded(const CallStateNone());
  final _callPageController = BehaviorSubject<bool>.seeded(false);

  ActiveCall? _activeCall;

  Timer? _endCallSoonTimer;

  set activeCall(ActiveCall value) {
    _activeCall = value;
    _controller.add(CallStateActive(activeCall: value));
  }

  set callPageActive(bool value) => _callPageController.add(value);

  Stream<CallState> get callState => _controller.stream;

  Stream<bool> get callPageActiveStream => _callPageController.stream;

  void endCall() {
    _disposeCurrentCall();
  }

  void _endCallSoon() {
    _endCallSoonTimer?.cancel();
    _endCallSoonTimer = Timer(
      const Duration(seconds: 3),
      () {
        _disposeCurrentCall();
      },
    );
  }

  void _disposeCurrentCall() {
    _endCallSoonTimer?.cancel();
    _endCallSoonTimer = null;

    _activeCall?.controller.dispose();
    _activeCall?.phone.dispose();
    _activeCall?.signalingChannel.dispose();
  }

  void call(BuildContext context, String myUid, SimpleProfile profile) async {
    _disposeCurrentCall();

    _controller.add(const CallStateInitializing(outgoing: true));

    final api = GetIt.instance.get<Api>();
    // final isFriend = await _checkIsFriend(profile.uid);
    final result = await api.call(profile.uid, false, group: false);
    result.fold(
      (l) {
        if (l is ApiClientError && l.error is ClientErrorConflict) {
          _controller.add(const CallStateEngaged());
        } else {
          var message = errorToMessage(l);
          message = l.when(
            network: (_) => message,
            client: (client) => client.when(
              badRequest: () => 'Failed to get users',
              unauthorized: () => message,
              notFound: () => 'Unable to find topic participants',
              forbidden: () => message,
              conflict: () => message,
            ),
            server: (_) => message,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
            ),
          );
        }
        _endCallSoon();
      },
      (rid) {
        final uid = myUid;
        final ActiveCall activeCall;
        if (Platform.isAndroid) {
          activeCall = android_voip.createActiveCall(uid, rid, profile);
        } else if (Platform.isIOS) {
          activeCall = ios_voip.createActiveCall(uid, rid, profile);
        } else {
          throw UnsupportedError('Calling only supported on Android and iOS');
        }

        activeCall.phone.join();
        _controller.add(
          CallStateActive(
            activeCall: ActiveCall(
              rid: activeCall.rid,
              phone: activeCall.phone,
              signalingChannel: activeCall.signalingChannel,
              profile: activeCall.profile,
              controller: activeCall.controller,
            ),
          ),
        );
      },
    );
  }
}

@freezed
class CallState with _$CallState {
  const factory CallState.none() = CallStateNone;

  const factory CallState.initializing({
    required bool outgoing,
  }) = CallStateInitializing;

  const factory CallState.engaged() = CallStateEngaged;

  const factory CallState.active({
    required ActiveCall activeCall,
  }) = CallStateActive;

  const factory CallState.ended() = CallStateEnded;
}

@freezed
class ActiveCall with _$ActiveCall {
  const factory ActiveCall({
    required String rid,
    required SimpleProfile profile,
    required SignalingChannel signalingChannel,
    required Phone phone,
    required PhoneController controller,
  }) = _ActiveCall;
}
