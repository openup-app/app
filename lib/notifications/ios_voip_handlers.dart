import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_callkit_voximplant/flutter_callkit_voximplant.dart';
import 'package:flutter_voip_push_notification/flutter_voip_push_notification.dart';
import 'package:get_it/get_it.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/call_manager.dart';
import 'package:openup/api/phone.dart';
import 'package:openup/notifications/notification_comms.dart';
import 'package:openup/notifications/notifications.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

FCXProvider? _provider;
FCXCallController? _callController;

Future<String?> getVoipPushNotificationToken() async {
  final notifications = FlutterVoipPushNotification();
  await notifications.requestNotificationPermissions();
  return notifications.getToken();
}

void initIosVoipHandlers(DeepLinkCallback onDeepLink) async {
  _provider = FCXProvider();
  _callController = FCXCallController();
  try {
    await _callController?.configure();
    await _provider?.configure(
      FCXProviderConfiguration(
        'ExampleLocalizedName',
        includesCallsInRecents: false,
        iconTemplateImageName: 'Icon-CallKit',
        supportsVideo: false,
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
      final activeCall = createActiveCall(myUid, rid, profile, false);
      phone = activeCall.phone;
      phone?.join();
      GetIt.instance.get<CallManager>().activeCall = activeCall;
      action.fulfill();
      onDeepLink('/friendships/${profile.uid}/call');
    } else {
      action.fail();
    }
  };

  _provider?.performEndCallAction = (action) async {
    Api.rejectCall('', action.callUuid.toLowerCase(), '');
    await removeBackgroundCallNotification();
    GetIt.instance.get<CallManager>().hangUp();
    action.fulfill();
  };

  _provider?.performSetMutedCallAction = (action) async {
    phone?.mute = action.muted;
    action.fulfill();
  };
}

PlatformVoipCallbacks createPlatformVoipCallbacks(String rid, bool video) {
  // Informs CallKit to update state based on user interactions
  return PlatformVoipCallbacks(
    reportCallEnded: () {
      _provider?.reportCallEnded(rid, null, FCXCallEndedReason.remoteEnded);
    },
    reportCallMuted: (muted) {
      _callController
          ?.requestTransactionWithAction(FCXSetMutedCallAction(rid, muted));
    },
    reportCallSpeakerphone: (speakerphone) {
      // TODO: How to do inform CallKit about this action?
    },
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
      blurPhotos: true,
    );
  }
  return null;
}
