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
      icon: Platform.isIOS ? "AppIcon" : null,
      onCallAccepted: (callEvent) async {
        final context = scaffoldKey.currentContext;
        final uid = callEvent.userInfo?['uid'];
        final photo = callEvent.userInfo?['photo'];
        if (uid != null && photo != null) {
          final startWithCall = StartWithCall(
            rid: callEvent.sessionId,
            profile: SimpleProfile(
              uid: uid,
              name: callEvent.callerName,
              photo: photo,
            ),
          );
          if (callPanelKey.currentState != null) {
            callPanelKey.currentState?.notificationCall(startWithCall);
          } else if (context != null) {
            Navigator.of(context).pushReplacementNamed(
              'lobby-list',
              arguments: startWithCall,
            );
          }
        }
      },
      onCallRejected: (callEvent) {
        final uid = callEvent.userInfo?['uid'];
        if (uid != null) {
          Api.rejectCall(uid, callEvent.sessionId);
        }
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
  required void Function() onCallAccepted,
  required void Function() onCallRejected,
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
  final uid = event.userInfo?['uid'];
  if (uid != null) {
    Api.rejectCall(uid, event.sessionId);
  }
  return Future.value();
}
