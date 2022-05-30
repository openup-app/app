import 'dart:async';
import 'dart:io';

import 'package:connectycube_flutter_call_kit/connectycube_flutter_call_kit.dart'
    hide CallState;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/call_state.dart';
import 'package:openup/api/lobby/lobby_api.dart';
import 'package:openup/api/signaling/phone.dart';
import 'package:openup/api/signaling/socket_io_signaling_channel.dart';
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

        if (myUid != null && uid != null && photo != null) {
          final profile = SimpleProfile(
            uid: uid,
            name: event.callerName,
            photo: photo,
          );
          final activeCall = createActiveCall(myUid, rid, profile);
          activeCall.phone.join();
          GetIt.instance.get<CallState>().callInfo = activeCall;
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
      // Unused
    },
    onAddTime: (_) {
      // Unused
    },
    onDisconnected: () {
      connectionStateSubscription?.cancel();
      signalingChannel.dispose();
      phone?.dispose();
    },
    onMuteChanged: (mute) {
      // TODO
    },
    onToggleSpeakerphone: (enabled) {
      // Unused
    },
    onGroupCallLobbyStates: (_) {
      // Unused
    },
    onJoinGroupCall: (rid, profiles, rekindles) {
      // Unused
    },
  );
  connectionStateSubscription = phone.connectionStateStream.listen((state) {
    if (state == PhoneConnectionState.connected) {
      controller.startTime = DateTime.now();
    }
  });
  return ActiveCall(
    rid: rid,
    profile: profile,
    signalingChannel: signalingChannel,
    phone: phone,
    controller: controller,
  );
}
