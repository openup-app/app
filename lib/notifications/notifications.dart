import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_apns/flutter_apns.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'notifications.freezed.dart';

typedef DeepLinkCallback = void Function(String path);

class NotificationManager {
  final void Function(NotificationToken token) onToken;
  ApnsPushConnector? _apnsPushConnector;
  StreamController<String?>? _iosNotificationTokenController;
  StreamSubscription? _iosEventChannelTokenSubscription;
  bool _disposed = false;

  NotificationManager({
    required this.onToken,
  }) {
    if (Platform.isIOS) {
      _apnsPushConnector = ApnsPushConnector();
      _apnsPushConnector?.shouldPresent = (_) => Future.value(true);
      _apnsPushConnector?.configureApns();
      _iosNotificationTokenController = StreamController<String?>.broadcast();
    }
  }

  void requestNotificationPermission() {
    print('######## Requesting notification permission');
    _tokenStream.listen(_onNotificationToken);
  }

  void _onNotificationToken(String? token) {
    debugPrint('On notification token: $token');
    if (token != null && !_disposed) {
      final notificationToken =
          Platform.isIOS ? _ApnsMessaging(token) : _FcmMessagingAndVoip(token);
      onToken(notificationToken);
    }
  }

  void dispose() => _disposeNotifications();

  void _disposeNotifications() {
    _disposed = true;
    _iosEventChannelTokenSubscription?.cancel();
    _iosNotificationTokenController?.close();
    if (Platform.isIOS) {
      _apnsPushConnector = null;
    }
  }

  Stream<String?> get _tokenStream async* {
    if (_disposed) {
      yield* const Stream.empty();
      return;
    }

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

@freezed
class NotificationToken with _$NotificationToken {
  const factory NotificationToken.fcmMessagingAndVoip(String token) =
      _FcmMessagingAndVoip;
  const factory NotificationToken.apnsMessaging(String token) = _ApnsMessaging;
}
