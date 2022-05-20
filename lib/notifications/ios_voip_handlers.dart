import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_voximplant/flutter_callkit_voximplant.dart';
import 'package:flutter_voip_push_notification/flutter_voip_push_notification.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/lobby/lobby_api.dart';
import 'package:openup/api/users/profile.dart';
import 'package:openup/lobby_list_page.dart';
import 'package:openup/notifications/notification_comms.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

FCXPlugin? _plugin;
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

void initIosVoipHandlers({
  required GlobalKey key,
  required bool Function(StartWithCall call) joinCall,
}) async {
  _plugin = FCXPlugin();
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
    print(e);
  }

  _provider?.performAnswerCallAction = (action) async {
    final rid = action.callUuid.toLowerCase();
    final profile = await _deserializeIncomingCallProfile();

    final context = key.currentContext;
    if (kProfileMode) {
      final text =
          'Context ${context != null} Profile ${profile != null}, nav handled? $_callHandled';
      print(text);

      if (context != null) {
        try {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(text),
          ));
        } catch (e) {
          print(e);
        }
      }
    }
    if (profile != null) {
      // In foreground or background launch
      final startWithCall = StartWithCall(
        rid: rid,
        profile: profile,
      );

      final joined = joinCall(startWithCall);
      if (joined) {
        // In foreground, on the lobby page
        action.fulfill();
      } else if (context != null) {
        // In foreground, but not on the call page
        Navigator.of(context).popUntil((p) => p.isFirst);
        Navigator.of(context).pushReplacementNamed(
          'lobby-list',
          arguments: startWithCall,
        );
        _callHandled = true;
        action.fulfill();
      } else {
        // Background launch, FCXPlugin.didDisplayIncomingCall ran sucessfully
        final backgroundCallNotification = BackgroundCallNotification(
          rid: rid,
          profile: profile,
          video: false,
          purpose: Purpose.friends,
          group: false,
        );
        await serializeBackgroundCallNotification(backgroundCallNotification);
      }
    } else {
      action.fail();
    }
  };

  _provider?.performEndCallAction = (action) async {
    Api.rejectCall('', action.callUuid.toLowerCase(), '');
    await removeBackgroundCallNotification();
    action.fulfill();
  };
}

// Future<void> displayIncomingCall({
//   required String rid,
//   required SimpleProfile profile,
//   required bool video,
//   bool appIsBackgrounded = false,
// }) async {
//   final update = FCXCallUpdate(localizedCallerName: profile.name);
//   await _provider?.reportNewIncomingCall(rid, update);
// }

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
  print('Incoming call file should be at ${incomingCallFile.path}');
  if (await incomingCallFile.exists()) {
    final data = await incomingCallFile.readAsString();
    print('Existed with data $data');
    return _parseProfileIos(data);
  }
  print('Does not exist');
  return null;
}

Future<void> _removeIncomingCallProfile() async {
  final documentsDir = await getApplicationDocumentsDirectory();
  final incomingCallFile =
      File(path.join(documentsDir.path, 'incoming_call.txt'));
  await incomingCallFile.delete();
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
