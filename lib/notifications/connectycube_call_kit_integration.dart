import 'package:connectycube_flutter_call_kit/connectycube_flutter_call_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:openup/api/lobby/lobby_api.dart';
import 'package:openup/api/users/profile.dart';
import 'package:openup/call_screen.dart';
import 'package:openup/notifications/notification_comms.dart';

bool _callKitInit = false;

Future<String?> getVoidPushNotificationToken() {
  return ConnectycubeFlutterCallKit.getToken();
}

void initIncomingCallHandlers({required GlobalKey key}) {
  ConnectycubeFlutterCallKit.onCallAcceptedWhenTerminated =
      _onCallAcceptedWhenTerminated;
  ConnectycubeFlutterCallKit.onCallRejectedWhenTerminated =
      _onCallRejectedWhenTerminated;

  if (!_callKitInit) {
    _callKitInit = true;
    ConnectycubeFlutterCallKit.instance.init(
      ringtone: "Apex",
      icon: "AppIcon",
      onCallAccepted: (callEvent) async {
        final context = key.currentContext;
        final uid = callEvent.userInfo?['uid'];
        if (context != null && uid != null) {
          final video = callEvent.callType == 1;
          final route = video ? 'friends-video-call' : 'friends-voice-call';
          final profile = SimpleProfile(
            uid: uid,
            name: callEvent.callerName,
            photo: callEvent.userInfo?['photo'],
          );
          Navigator.of(context).pushNamed(
            route,
            arguments: CallPageArguments(
              rid: callEvent.sessionId,
              profiles: [profile],
              rekindles: [],
              serious: false,
            ),
          );
        }
      },
      onCallRejected: (callEvent) {
        print('Call rejected ${callEvent.sessionId}');
        // TODO: Send call rejection API request
        return Future.value();
      },
    );
  }
}

Future<void> displayIncomingCall({
  required String rid,
  required String callerUid,
  required String callerName,
  required String? callerPhoto,
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
    opponentsIds: const {},
    userInfo: {
      'uid': callerUid,
      ...{if (callerPhoto != null) 'photo': callerPhoto},
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
  if (uid != null) {
    final video = callEvent.callType == 1;
    final backgroundCallNotification = BackgroundCallNotification(
      rid: callEvent.sessionId,
      profile: SimpleProfile(
        uid: uid,
        name: callEvent.callerName,
        photo: callEvent.userInfo?['photo'],
      ),
      video: video,
      purpose: Purpose.friends,
      group: false,
    );
    await serializeBackgroundCallNotification(backgroundCallNotification);
  }
}

Future<void> _onCallRejectedWhenTerminated(CallEvent event) {
  // TODO: Send call rejected API request
  return Future.value();
}
