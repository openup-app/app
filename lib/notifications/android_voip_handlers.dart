import 'dart:async';
import 'dart:io';

import 'package:connectycube_flutter_call_kit/connectycube_flutter_call_kit.dart'
    hide CallState;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/call_manager.dart';
import 'package:openup/api/users/profile.dart';
import 'package:openup/main.dart';
import 'package:openup/notifications/notification_comms.dart';

bool _callKitInit = false;

Future<String?> getVoipPushNotificationToken() {
  return ConnectycubeFlutterCallKit.getToken();
}

void initAndroidVoipHandlers() {
  ConnectycubeFlutterCallKit.onCallAcceptedWhenTerminated =
      _onCallAcceptedWhenTerminated;
  ConnectycubeFlutterCallKit.onCallRejectedWhenTerminated =
      _onCallRejectedWhenTerminated;

  if (!_callKitInit) {
    _callKitInit = true;
    ConnectycubeFlutterCallKit.instance.init(
      ringtone: Platform.isIOS ? "Apex" : null,
      icon: Platform.isIOS ? "AppIcon" : "call_icon",
      onCallAccepted: (event) async {
        final myUid = FirebaseAuth.instance.currentUser?.uid;
        final rid = event.sessionId;
        final uid = event.userInfo?['uid'];
        final photo = event.userInfo?['photo'];
        final blurPhotos =
            event.userInfo?['blurPhotos']?.toLowerCase() == 'true';

        if (myUid != null && uid != null && photo != null) {
          final profile = SimpleProfile(
              uid: uid,
              name: event.callerName,
              photo: photo,
              blurPhotos: blurPhotos);
          final activeCall = createActiveCall(myUid, rid, profile, false);
          activeCall.phone.join();
          GetIt.instance.get<CallManager>().activeCall = activeCall;
          rootNavigatorKey.currentState?.pushNamed('call');
        }
      },
      onCallRejected: (event) {
        // TODO: Need to pass uid and authToken, but failed to retrieve data from Firebase Auth with no message
        Api.rejectCall('', event.sessionId, '');
        return Future.value();
      },
    );
  }
}

Future<void> displayIncomingCall({
  required String rid,
  required SimpleProfile profile,
  required bool video,
  bool appIsBackgrounded = false,
}) async {
  CallEvent callEvent = CallEvent(
    sessionId: rid,
    callType: video ? 1 : 0,
    callerId: 1,
    callerName: profile.name,
    opponentsIds: const {0, 1},
    userInfo: {
      'uid': profile.uid,
      'photo': profile.photo,
    },
  );
  ConnectycubeFlutterCallKit.showCallNotification(callEvent);

  await ConnectycubeFlutterCallKit.setOnLockScreenVisibility(isVisible: true);
}

Future<void> reportCallStarted(String rid, bool video) {
  return ConnectycubeFlutterCallKit.reportCallAccepted(
    sessionId: rid,
    callType: video ? 1 : 0,
  );
}

void reportCallEnded(String rid) {
  ConnectycubeFlutterCallKit.reportCallEnded(sessionId: rid);
  ConnectycubeFlutterCallKit.clearCallData(sessionId: rid);
}

Future<void> _onCallAcceptedWhenTerminated(CallEvent callEvent) async {
  final uid = callEvent.userInfo?['uid'];
  final photo = callEvent.userInfo?['photo'];
  final video = callEvent.callType == 1;
  final blurPhotos = callEvent.userInfo?['blurPhotos']?.toLowerCase() == 'true';
  if (uid != null && photo != null) {
    final backgroundCallNotification = BackgroundCallNotification(
      rid: callEvent.sessionId,
      profile: SimpleProfile(
        uid: uid,
        name: callEvent.callerName,
        photo: photo,
        blurPhotos: blurPhotos,
      ),
      video: video,
    );
    await serializeBackgroundCallNotification(backgroundCallNotification);
  }
}

Future<void> _onCallRejectedWhenTerminated(CallEvent event) {
  // TODO: Need to pass uid and authToken, but failed to retrieve data from Firebase Auth with no message
  Api.rejectCall('', event.sessionId, '');
  return Future.value();
}

PlatformVoipCallbacks createPlatformVoipCallbacks(String rid, bool video) {
  return PlatformVoipCallbacks(
    reportCallEnded: () {
      // TODO: Inform ConnectionService of updates
    },
    reportCallMuted: (muted) {
      // TODO: Inform ConnectionService of updates
    },
    reportCallSpeakerphone: (speakerphone) {
      // TODO: Inform ConnectionService of updates
    },
  );
}
