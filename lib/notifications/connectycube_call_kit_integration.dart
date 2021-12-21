import 'package:connectycube_flutter_call_kit/connectycube_flutter_call_kit.dart';

Future<void> displayIncomingCall({
  required String rid,
  required String callerName,
  required bool video,
  bool appIsBackgrounded = false,
  required void Function() onCallAccepted,
  required void Function() onCallRejected,
}) async {
  ConnectycubeFlutterCallKit.instance.init(
    onCallAccepted: (
      String sessionId,
      int callType,
      int callerId,
      String callerName,
      Set<int> opponentsIds,
      Map<String, String>? userInfo,
    ) async {
      onCallAccepted();
    },
    onCallRejected: (
      String sessionId,
      int callType,
      int callerId,
      String callerName,
      Set<int> opponentsIds,
      Map<String, String>? userInfo,
    ) async {
      onCallRejected();
    },
  );

  await ConnectycubeFlutterCallKit.setOnLockScreenVisibility(isVisible: true);
  ConnectycubeFlutterCallKit.onCallAcceptedWhenTerminated = (
    String sessionId,
    int callType,
    int callerId,
    String callerName,
    Set<int> opponentsIds,
    Map<String, String>? userInfo,
  ) {
    onCallAccepted();
  };

  return ConnectycubeFlutterCallKit.showCallNotification(
    sessionId: rid,
    callType: video ? 1 : 0,
    callerId: 1,
    callerName: callerName,
    opponentsIds: {1, 2},
    userInfo: {},
  );
}
