import 'dart:io';

import 'package:connectycube_flutter_call_kit/connectycube_flutter_call_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/lobby/lobby_api.dart';
import 'package:openup/api/users/profile.dart';
import 'package:openup/lobby_list_page.dart';
import 'package:openup/notifications/notification_comms.dart';

bool _callKitInit = false;

Future<String?> getVoipPushNotificationToken() {
  return ConnectycubeFlutterCallKit.getToken();
}

void initIncomingCallHandlers({
  required GlobalKey scaffoldKey,
  required GlobalKey<LobbyListPageState> callPanelKey,
}) {
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
        final context = scaffoldKey.currentContext;
        final uid = event.userInfo?['uid'];
        final photo = event.userInfo?['photo'];
        if (uid != null && photo != null) {
          final startWithCall = StartWithCall(
            rid: event.sessionId,
            profile: SimpleProfile(
              uid: uid,
              name: event.callerName,
              photo: photo,
            ),
          );
          if (callPanelKey.currentState != null) {
            callPanelKey.currentState?.joinCall(startWithCall);
          } else if (context != null) {
            Navigator.of(context).popUntil((p) => p.isFirst);
            Navigator.of(context).pushReplacementNamed(
              'lobby-list',
              arguments: startWithCall,
            );
          }
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
  required String callerUid,
  required String callerName,
  required String callerPhoto,
  required bool video,
  bool appIsBackgrounded = false,
  @Deprecated('Unused by ConnectyCube') required void Function() onCallAccepted,
  @Deprecated('Unused by ConnectyCube') required void Function() onCallRejected,
}) async {
  CallEvent callEvent = CallEvent(
    sessionId: rid,
    callType: video ? 1 : 0,
    callerId: 1,
    callerName: callerName,
    opponentsIds: const {0, 1},
    userInfo: {
      'uid': callerUid,
      'photo': callerPhoto,
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
  if (uid != null && photo != null) {
    final video = callEvent.callType == 1;
    final backgroundCallNotification = BackgroundCallNotification(
      rid: callEvent.sessionId,
      profile: SimpleProfile(
        uid: uid,
        name: callEvent.callerName,
        photo: photo,
      ),
      video: video,
      purpose: Purpose.friends,
      group: false,
    );
    await serializeBackgroundCallNotification(backgroundCallNotification);
  }
}

Future<void> _onCallRejectedWhenTerminated(CallEvent event) {
  // TODO: Need to pass uid and authToken, but failed to retrieve data from Firebase Auth with no message
  Api.rejectCall('', event.sessionId, '');
  return Future.value();
}
