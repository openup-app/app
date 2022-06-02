import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_callkit_voximplant/flutter_callkit_voximplant.dart';
import 'package:flutter_voip_push_notification/flutter_voip_push_notification.dart';
import 'package:get_it/get_it.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/call_state.dart';
import 'package:openup/api/signaling/phone.dart';
import 'package:openup/api/signaling/socket_io_signaling_channel.dart';
import 'package:openup/api/users/profile.dart';
import 'package:openup/main.dart';
import 'package:openup/notifications/notification_comms.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

FCXProvider? _provider;
FCXCallController? _callController;
bool _callHandled = false;

Future<String?> getVoipPushNotificationToken() {
  return FlutterVoipPushNotification().onTokenRefresh.first;
}

bool checkAndClearCallHandledFlag() {
  final callHandled = _callHandled;
  _callHandled = false;
  return callHandled;
}

void initIosVoipHandlers() async {
  _provider = FCXProvider();
  _callController = FCXCallController();
  try {
    await _callController?.configure();
    await _provider?.configure(
      FCXProviderConfiguration(
        'ExampleLocalizedName',
        includesCallsInRecents: false,
        supportedHandleTypes: {
          FCXHandleType.Generic,
        },
      ),
    );
  } catch (e) {
    debugPrint(e.toString());
  }

  Phone? phone;
  _provider?.performAnswerCallAction = (action) async {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    final rid = action.callUuid.toLowerCase();
    final profile = await _deserializeIncomingCallProfile();

    if (myUid != null && profile != null) {
      final activeCall = createActiveCall(myUid, rid, profile);
      phone = activeCall.phone;
      phone?.join();
      GetIt.instance.get<CallState>().callInfo = activeCall;
      action.fulfill();
    } else {
      action.fail();
    }
  };

  _provider?.performEndCallAction = (action) async {
    Api.rejectCall('', action.callUuid.toLowerCase(), '');
    await removeBackgroundCallNotification();
    GetIt.instance.get<CallState>().callInfo = const NoCall();
    action.fulfill();
  };

  _provider?.performSetMutedCallAction = (action) async {
    phone?.mute = action.muted;
    action.fulfill();
  };
}

ActiveCall createActiveCall(String myUid, String rid, SimpleProfile profile) {
  final signalingChannel = SocketIoSignalingChannel(
    host: host,
    port: socketPort,
    uid: myUid,
    rid: rid,
    serious: true,
  );

  Phone? phone;
  final controller = PhoneController();
  PhoneValue oldPhoneValue = controller.value;
  StreamSubscription? connectionStateSubscription;
  phone = Phone(
    controller: controller,
    signalingChannel: signalingChannel,
    uid: myUid,
    partnerUid: profile.uid,
    useVideo: false,
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
      connectionStateSubscription?.cancel();
      controller.dispose();
      _provider?.reportCallEnded(rid, null, FCXCallEndedReason.remoteEnded);
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
      controller.startTime = DateTime.now();
    }
  });
  controller.addListener(() {
    // Informs CallKit to update state based on user changes
    if (oldPhoneValue.mute != controller.muted) {
      _callController?.requestTransactionWithAction(
          FCXSetMutedCallAction(rid, controller.muted));
    }

    if (oldPhoneValue.speakerphone != controller.speakerphone) {
      // TODO: How to do inform CarlKit about this action?
    }

    oldPhoneValue = controller.value.copyWith();
  });
  return ActiveCall(
    rid: rid,
    profile: profile,
    signalingChannel: signalingChannel,
    phone: phone,
    controller: controller,
  );
}

Future<void> reportCallStarted(String rid, bool video) async {
  await _provider?.reportOutgoingCallConnected(rid, null);
}

void reportCallEnded(String rid) {
  _provider?.reportCallEnded(rid, null, FCXCallEndedReason.remoteEnded);
}

Future<SimpleProfile?> _deserializeIncomingCallProfile() async {
  final documentsDir = await getApplicationDocumentsDirectory();
  final incomingCallFile =
      File(path.join(documentsDir.path, 'incoming_call.txt'));
  if (await incomingCallFile.exists()) {
    final data = await incomingCallFile.readAsString();
    return _parseProfileIos(data);
  }
  return null;
}

SimpleProfile? _parseProfileIos(String value) {
  final tokens = value.split('#_');
  if (tokens.length >= 2) {
    final uid = tokens[0];
    final photo = tokens[1];
    final name = tokens.sublist(2).join('#_');
    return SimpleProfile(
      uid: uid,
      photo: photo,
      name: name,
    );
  }
  return null;
}
