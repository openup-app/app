import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:flutter_apns/flutter_apns.dart';

typedef DeepLinkCallback = void Function(String path);
ApnsPushConnector? _apnsPushConnector;
StreamController<String?>? _iosNotificationTokenController;
StreamSubscription? _iosEventChannelTokenSubscription;

Future<void> initializeNotifications() async {
  _iosNotificationTokenController = StreamController<String?>.broadcast();
  if (Platform.isIOS) {
    _apnsPushConnector = ApnsPushConnector();
  }
}

void disposeNotifications() {
  _iosNotificationTokenController?.close();
  _iosNotificationTokenController = null;
  _iosEventChannelTokenSubscription?.cancel();
  _iosEventChannelTokenSubscription = null;
  if (Platform.isIOS) {
    _apnsPushConnector = null;
  }
}

Stream<String?> get onNotificationMessagingToken async* {
  if (Platform.isAndroid) {
    yield await FirebaseMessaging.instance.getToken();
    yield* FirebaseMessaging.instance.onTokenRefresh;
  } else if (Platform.isIOS) {
    final status = await _apnsPushConnector?.getAuthorizationStatus();
    if (status != ApnsAuthorizationStatus.authorized) {
      await _apnsPushConnector
          ?.requestNotificationPermissions(const IosNotificationSettings());
    }

    if (await _apnsPushConnector?.getAuthorizationStatus() ==
        ApnsAuthorizationStatus.authorized) {
      // APNSPushConnector is receving a null token, so manually get it ourselves
      const eventChannel = EventChannel('com.openupdating/notification_tokens');
      _iosEventChannelTokenSubscription =
          eventChannel.receiveBroadcastStream().listen((token) {
        _iosNotificationTokenController?.add(token);
      });
      yield _apnsPushConnector?.token.value;
      // _apnsPushConnector?.token.addListener(() {
      //   // Seems to always be a null token
      //   _iosNotificationTokenController?.add(_apnsPushConnector?.token.value);
      // });
    }
    if (_iosNotificationTokenController != null) {
      yield* _iosNotificationTokenController!.stream;
    }
  }
}
