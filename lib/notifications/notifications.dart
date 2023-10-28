import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_apns/flutter_apns.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rxdart/subjects.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

part 'notifications.freezed.dart';
part 'notifications.g.dart';

typedef DeepLinkCallback = void Function(String path);

final notificationManagerProvider =
    Provider<NotificationManager>((ref) => throw 'Uninitialized provider');

class NotificationManager {
  final _tokenController = BehaviorSubject<NotificationToken>();
  final _deepLinkController = BehaviorSubject<String>();

  ApnsPushConnector? _apnsPushConnector;
  StreamSubscription? _iosEventChannelTokenSubscription;
  bool _disposed = false;

  NotificationManager() {
    if (Platform.isIOS) {
      _apnsPushConnector = ApnsPushConnector();
      _apnsPushConnector?.shouldPresent = (_) => Future.value(true);
      _apnsPushConnector?.configureApns(
        onLaunch: (message) {
          _parseNotification(message);
          return Future.value();
        },
        onMessage: (message) {
          _parseNotification(message);
          return Future.value();
        },
        onBackgroundMessage: (message) {
          _parseNotification(message);
          return Future.value();
        },
        onResume: (message) {
          _parseNotification(message);
          return Future.value();
        },
      );
    }

    if (Platform.isAndroid) {
      _listenToFcmNotificationTokens(_tokenController.sink);
    } else if (Platform.isIOS) {
      _listenToApnsNotificationTokens(_tokenController.sink);
    }
  }

  Future<bool> hasNotificationPermission() => Permission.notification.isGranted;

  Future<bool> isPermanentlyDenied() =>
      Permission.notification.isPermanentlyDenied;

  Future<bool> requestNotificationPermission() async {
    if (Platform.isAndroid) {
      final settings = await FirebaseMessaging.instance.requestPermission();
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } else {
      final status = await _apnsPushConnector?.getAuthorizationStatus();
      if (status == ApnsAuthorizationStatus.authorized) {
        return true;
      } else {
        return await _apnsPushConnector!
            .requestNotificationPermissions(const IosNotificationSettings());
      }
    }
  }

  void dispose() {
    _tokenController.close();
    _deepLinkController.close();
    _disposeNotifications();
  }

  void _disposeNotifications() {
    _disposed = true;
    _iosEventChannelTokenSubscription?.cancel();
    if (Platform.isIOS) {
      _apnsPushConnector = null;
    }
  }

  void _parseNotification(ApnsRemoteMessage message) {
    final data = message.payload['data'] ?? {};
    final body = jsonDecode(data['body'] ?? '{}');
    switch (data['type']) {
      case 'deep_link':
        try {
          final deepLink = NotificationPayload.fromJson(body);
          _deepLinkController.add(deepLink.path);
        } catch (e, s) {
          Sentry.captureException(e, stackTrace: s);
        }
    }
  }

  Stream<NotificationToken> get tokenStream => _tokenController.stream;

  Stream<String> get deepLinkStream => _deepLinkController.stream;

  void _listenToFcmNotificationTokens(
      StreamSink<NotificationToken> sink) async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      sink.add(NotificationToken.fcmMessagingAndVoip(token));
    }
    sink.addStream(FirebaseMessaging.instance.onTokenRefresh
        .map(NotificationToken.fcmMessagingAndVoip));
  }

  void _listenToApnsNotificationTokens(Sink<NotificationToken> sink) async {
    // APNSPushConnector is receving a null token, so manually get it ourselves
    const eventChannel = EventChannel('com.openupdating/notification_tokens');
    _iosEventChannelTokenSubscription =
        eventChannel.receiveBroadcastStream().listen((token) {
      if (!_disposed && token != null) {
        sink.add(NotificationToken.apnsMessaging(token));
      }
    });
    _apnsPushConnector?.token.addListener(() {
      final value = _apnsPushConnector?.token.value;
      if (!_disposed && value != null) {
        sink.add(NotificationToken.apnsMessaging(value));
      }
    });
  }
}

@freezed
class NotificationToken with _$NotificationToken {
  const factory NotificationToken.fcmMessagingAndVoip(String token) =
      _FcmMessagingAndVoip;
  const factory NotificationToken.apnsMessaging(String token) = _ApnsMessaging;
}

@freezed
class NotificationPayload with _$NotificationPayload {
  const factory NotificationPayload.deepLink(String path) = _DeepLink;

  factory NotificationPayload.fromJson(Map<String, dynamic> json) =>
      _$NotificationPayloadFromJson(json);
}
