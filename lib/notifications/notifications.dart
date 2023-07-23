import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_apns/flutter_apns.dart';
import 'package:openup/api/api.dart';

typedef DeepLinkCallback = void Function(String path);

class NotificationManager {
  final Api? api;
  ApnsPushConnector? _apnsPushConnector;
  StreamController<String?>? _iosNotificationTokenController;
  StreamSubscription? _iosEventChannelTokenSubscription;

  NotificationManager({
    required this.api,
  }) {
    if (Platform.isIOS) {
      _apnsPushConnector = ApnsPushConnector();
      _apnsPushConnector?.shouldPresent = (_) => Future.value(true);
      _apnsPushConnector?.configureApns();
      _iosNotificationTokenController = StreamController<String?>.broadcast();
    }
    _tokenStream.listen(_onNotificationToken);
  }

  void _onNotificationToken(String? token) {
    debugPrint('On notification token: $token');
    if (token != null) {
      final isIOS = Platform.isIOS;
      api?.addNotificationTokens(
        fcmMessagingAndVoipToken: isIOS ? null : token,
        apnMessagingToken: isIOS ? token : null,
      );
    }
  }

  void dispose() => _disposeNotifications();

  void _disposeNotifications() {
    _iosEventChannelTokenSubscription?.cancel();
    _iosNotificationTokenController?.close();
    if (Platform.isIOS) {
      _apnsPushConnector = null;
    }
  }

  Stream<String?> get _tokenStream async* {
    if (Platform.isAndroid) {
      yield await FirebaseMessaging.instance.getToken();
      yield* FirebaseMessaging.instance.onTokenRefresh;
    } else if (Platform.isIOS) {
      var status = await _apnsPushConnector?.getAuthorizationStatus();
      if (status != ApnsAuthorizationStatus.authorized) {
        await _apnsPushConnector
            ?.requestNotificationPermissions(const IosNotificationSettings());
      }

      status = await _apnsPushConnector?.getAuthorizationStatus();
      if (status == ApnsAuthorizationStatus.authorized) {
        // APNSPushConnector is receving a null token, so manually get it ourselves
        const eventChannel =
            EventChannel('com.openupdating/notification_tokens');
        _iosEventChannelTokenSubscription =
            eventChannel.receiveBroadcastStream().listen((token) {
          if (_iosNotificationTokenController?.isClosed != true) {
            _iosNotificationTokenController?.add(token);
          }
        });
        _apnsPushConnector?.token.addListener(() {
          if (_iosNotificationTokenController?.isClosed != true) {
            _iosNotificationTokenController
                ?.add(_apnsPushConnector?.token.value);
          }
        });
      }
      final stream = _iosNotificationTokenController?.stream;
      if (stream != null) {
        yield* stream;
      }
    }
  }
}
