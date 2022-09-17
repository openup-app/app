import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:get_it/get_it.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/signaling/phone.dart';
import 'package:openup/api/signaling/signaling.dart';
import 'package:openup/api/signaling/socket_io_signaling_channel.dart';
import 'package:openup/api/users/profile.dart';
import 'package:openup/main.dart';
import 'package:openup/notifications/android_voip_handlers.dart'
    as android_voip;
import 'package:openup/notifications/ios_voip_handlers.dart' as ios_voip;
import 'package:rxdart/subjects.dart';

part 'call_manager.freezed.dart';

/// Provides the mechanism to perform and display calls.
class CallManager {
  final _controller = BehaviorSubject<CallState>.seeded(const CallStateNone());
  final _callPageController = BehaviorSubject<bool>.seeded(false);
  StreamSubscription? _connectionStateSubscription;

  ActiveCall? _activeCall;
  set activeCall(ActiveCall value) {
    _activeCall = value;
    debugPrint('[Calling] Setting active call');
    _controller.add(CallStateActive(activeCall: value));

    _connectionStateSubscription?.cancel();
    _connectionStateSubscription =
        value.phone.connectionStateStream.listen((state) {
      if (state == PhoneConnectionState.complete) {
        _controller.add(CallState.ended(profile: value.profile));
        _disposeCurrentCall();
      }
    });
  }

  Stream<CallState> get callState => _controller.stream;

  /// Informs others whether the call page is being displayed
  set callPageActive(bool value) => _callPageController.add(value);

  /// Whether or not the UI is displaying the call page
  Stream<bool> get callPageActiveStream => _callPageController.stream;

  void hangUp() {
    // _activeCall?.signalingChannel.send(const HangUp());
    _disposeCurrentCall();
  }

  void _disposeCurrentCall() {
    debugPrint('[Calling] Disposing any call');
    _controller.add(const CallState.none());
    _activeCall?.controller.dispose();
    _activeCall?.phone.dispose();
    _activeCall?.signalingChannel.dispose();
    _activeCall = null;
    _connectionStateSubscription?.cancel();
    _connectionStateSubscription = null;
  }

  void call({
    required BuildContext context,
    required String uid,
    required SimpleProfile otherProfile,
    required bool video,
  }) async {
    _controller.add(CallStateInitializing(
      profile: otherProfile,
      outgoing: true,
      video: video,
    ));

    final api = GetIt.instance.get<Api>();
    // final isFriend = await _checkIsFriend(profile.uid);
    final result = await api.call(otherProfile.uid, video, group: false);
    result.fold(
      (l) {
        if (l is ApiClientError && l.error is ClientErrorConflict) {
          _controller.add(CallStateEngaged(
            profile: otherProfile,
            video: video,
          ));
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
        _disposeCurrentCall();
      },
      (rid) {
        final newActiveCall = createActiveCall(uid, rid, otherProfile, video);
        newActiveCall.phone.join();
        activeCall = newActiveCall;
      },
    );
  }
}

ActiveCall createActiveCall(
  String myUid,
  String rid,
  SimpleProfile profile,
  bool video,
) {
  final signalingChannel = SocketIoSignalingChannel(
    host: host,
    port: socketPort,
    uid: myUid,
    rid: rid,
    serious: true,
  );

  final PlatformVoipCallbacks platformVoipCallbacks;
  if (Platform.isAndroid) {
    platformVoipCallbacks =
        android_voip.createPlatformVoipCallbacks(rid, false);
  } else if (Platform.isIOS) {
    platformVoipCallbacks = ios_voip.createPlatformVoipCallbacks(rid, false);
  } else {
    throw UnsupportedError('Calling is only supported on Android and iOS');
  }

  Phone? phone;
  final phoneController = PhoneController();
  PhoneValue oldPhoneValue = phoneController.value;
  StreamSubscription? connectionStateSubscription;
  phone = Phone(
    controller: phoneController,
    signalingChannel: signalingChannel,
    uid: myUid,
    partnerUid: profile.uid,
    useVideo: video,
    onMediaRenderers: (localRenderer, remoteRenderer) {
      // Unused
    },
    onRemoteStream: (stream) {
      // Unused
    },
    onAddTimeRequest: () {
      // TODO
    },
    onAddTime: (_) {},
    onDisconnected: () {
      print('########### onDisconnected');
      connectionStateSubscription?.cancel();
      phoneController.dispose();
      platformVoipCallbacks.reportCallEnded();
      signalingChannel.dispose();
      phone?.dispose();
    },
    onGroupCallLobbyStates: (_) {
      // Unused
    },
    onJoinGroupCall: (rid, profiles) {
      // Unused
    },
  );
  connectionStateSubscription = phone.connectionStateStream.listen((state) {
    if (state == PhoneConnectionState.connected) {
      phoneController.startTime = DateTime.now();
    }
  });
  phoneController.addListener(() {
    // Informs CallKit to update state based on user interactions
    if (oldPhoneValue.mute != phoneController.muted) {
      platformVoipCallbacks.reportCallMuted(phoneController.muted);
    }

    if (oldPhoneValue.speakerphone != phoneController.speakerphone) {
      platformVoipCallbacks
          .reportCallSpeakerphone(phoneController.speakerphone);
    }

    oldPhoneValue = phoneController.value.copyWith();
  });

  return ActiveCall(
    rid: rid,
    profile: profile,
    signalingChannel: signalingChannel,
    phone: phone,
    controller: phoneController,
  );
}

@freezed
class CallState with _$CallState {
  const factory CallState.none() = CallStateNone;

  const factory CallState.initializing({
    required SimpleProfile profile,
    required bool outgoing,
    required bool video,
  }) = CallStateInitializing;

  const factory CallState.engaged({
    required SimpleProfile profile,
    required bool video,
  }) = CallStateEngaged;

  const factory CallState.active({
    required ActiveCall activeCall,
  }) = CallStateActive;

  const factory CallState.ended({
    required SimpleProfile profile,
  }) = CallStateEnded;
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

class PlatformVoipCallbacks {
  final void Function() reportCallEnded;
  final void Function(bool muted) reportCallMuted;
  final void Function(bool speakerphone) reportCallSpeakerphone;

  const PlatformVoipCallbacks({
    required this.reportCallEnded,
    required this.reportCallMuted,
    required this.reportCallSpeakerphone,
  });
}
