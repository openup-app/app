import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_apns/flutter_apns.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/call_manager.dart';
import 'package:openup/notifications/android_voip_handlers.dart'
    as android_voip;
import 'package:openup/notifications/ios_voip_handlers.dart' as ios_voip;
import 'package:openup/notifications/notification_comms.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:sentry_flutter/sentry_flutter.dart';

part 'notifications.freezed.dart';
part 'notifications.g.dart';

typedef DeepLinkCallback = void Function(String path);
ApnsPushConnectorOnly? _apnsPushConnector;

// TODO: This is never disposed, probably it should be
final _iosNotificationTokenController = StreamController<String?>();

Future<void> initializeNotifications() async {
  // May not be needed, used to dismiss remaining notifications on logout
  await _initializeLocalNotifications();

  _apnsPushConnector = ApnsPushConnectorOnly();
}

void initializeVoipHandlers({required DeepLinkCallback onDeepLink}) {
  if (Platform.isAndroid) {
    android_voip.initAndroidVoipHandlers(onDeepLink);
  } else if (Platform.isIOS) {
    ios_voip.initIosVoipHandlers(onDeepLink);
  }
}

Stream<String?> get onNotificationMessagingToken async* {
  if (Platform.isAndroid) {
    yield await FirebaseMessaging.instance.getToken();
    yield* FirebaseMessaging.instance.onTokenRefresh;
  } else if (Platform.isIOS) {
    yield _apnsPushConnector?.token.value;
    _apnsPushConnector?.token.addListener(() {
      _iosNotificationTokenController.add(_apnsPushConnector?.token.value);
    });
    yield* _iosNotificationTokenController.stream;
  }
}

/// The callback will receive a deep link path whenever the user taps on a
/// notification, or immediately if the app was launched from a notification.
Future<void> handleNotifications({
  required DeepLinkCallback onDeepLink,
}) async {
  if (Platform.isAndroid) {
    FirebaseMessaging.onBackgroundMessage(_onBackgroundNotification);
    FirebaseMessaging.onMessage.listen((remoteMessage) {
      _onForegroundNotification(remoteMessage);
    });
    await _handleAndroidBackgroundCall(onDeepLink);
    await _handleAndroidNotification(onDeepLink);
  } else if (Platform.isIOS) {
    await _handleIosNotification(onDeepLink);
  }
}

Future<void> dismissAllNotifications() =>
    FlutterLocalNotificationsPlugin().cancelAll();

void reportCallStarted(String rid) {
  if (Platform.isAndroid) {
    android_voip.reportCallStarted(rid, false);
  } else {
    ios_voip.reportCallStarted(rid, false);
  }
}

void reportCallEnded(String rid) {
  if (Platform.isAndroid) {
    android_voip.reportCallEnded(rid);
  } else {
    ios_voip.reportCallEnded(rid);
  }
}

Future<void> _handleAndroidBackgroundCall(DeepLinkCallback onDeepLink) async {
  // Calls that don't go through the standard FirebaseMessaging app launch method
  BackgroundCallNotification? backgroundCallNotification;
  try {
    backgroundCallNotification =
        await deserializeAndRemoveBackgroundCallNotification();
  } catch (e, s) {
    Sentry.captureException(e, stackTrace: s);
  }

  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (backgroundCallNotification == null || uid == null) {
    return;
  }

  final activeCall = createActiveCall(
    uid,
    backgroundCallNotification.rid,
    backgroundCallNotification.profile,
    backgroundCallNotification.video,
  );
  activeCall.phone.join();
  GetIt.instance.get<CallManager>().activeCall = activeCall;
  onDeepLink('/friendships/${backgroundCallNotification.profile.uid}/call');
}

Future<void> _handleAndroidNotification(DeepLinkCallback onDeepLink) async {
  final remoteMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (remoteMessage != null) {
    final parsedMessage = _parseRemoteMessageData(remoteMessage.data);
    if (parsedMessage is _DeepLink) {
      onDeepLink(parsedMessage.path);
    }
  }

  FirebaseMessaging.onMessageOpenedApp.listen((remoteMessage) {
    final parsedMessage = _parseRemoteMessageData(remoteMessage.data);
    if (parsedMessage is _DeepLink) {
      onDeepLink(parsedMessage.path);
    }
  });
}

Future<void> _handleIosNotification(DeepLinkCallback onDeepLink) async {
  final connector = ApnsPushConnectorOnly();
  connector.configureApns(
    onMessage: (remoteMessage) {
      final data = remoteMessage.payload['data'];
      if (data != null) {
        final parsedMessage =
            _parseRemoteMessageData(Map<String, dynamic>.from(data));
        if (parsedMessage != null) {
          return _onReceiveNotification(parsedMessage);
        }
      }
      return Future.value();
    },
    onBackgroundMessage: (remoteMessage) {
      final data = remoteMessage.payload['data'];
      if (data != null) {
        final parsedMessage =
            _parseRemoteMessageData(Map<String, dynamic>.from(data));
        if (parsedMessage != null) {
          return _onReceiveNotification(parsedMessage);
        }
      }
      return Future.value();
    },
    onLaunch: (remoteMessage) {
      final data = remoteMessage.payload['data'];
      if (data != null) {
        final parsedMessage =
            _parseRemoteMessageData(Map<String, dynamic>.from(data));
        if (parsedMessage is _DeepLink) {
          onDeepLink(parsedMessage.path);
        }
      }
      return Future.value();
    },
    onResume: (remoteMessage) {
      final data = remoteMessage.payload['data'];
      if (data != null) {
        final parsedMessage =
            _parseRemoteMessageData(Map<String, dynamic>.from(data));
        if (parsedMessage is _DeepLink) {
          onDeepLink(parsedMessage.path);
        }
      }
      return Future.value();
    },
  );
  _apnsPushConnector = connector;
  connector.shouldPresent = (_) => Future.value(true);
  await connector.requestNotificationPermissions();
}

Future<void> _onReceiveNotification(_ParsedMessage parsedMessage) {
  return parsedMessage.map(
    call: (call) {
      final profile = SimpleProfile(
        uid: call.uid,
        name: call.name,
        photo: call.photo,
        blurPhotos: call.blurPhotos,
      );
      if (Platform.isAndroid) {
        return android_voip.displayIncomingCall(
          rid: call.rid,
          profile: profile,
          video: false,
        );
      }
      // iOS handles incoming call separately using PushKit and CallKit
      return Future.value();
    },
    callEnded: (callEnded) => Future.sync(() => reportCallEnded(callEnded.rid)),
    deepLink: (_) {
      // Deep links are handled on tap separately for each platform
      return Future.value();
    },
  );
}

void _onForegroundNotification(RemoteMessage message) {
  final parsedMessage = _parseRemoteMessageData(message.data);
  if (parsedMessage != null) {
    _onReceiveNotification(parsedMessage);
  }
}

Future<void> _onBackgroundNotification(RemoteMessage message) {
  final parsedMessage = _parseRemoteMessageData(message.data);
  if (parsedMessage != null) {
    _onReceiveNotification(parsedMessage);
  }
  return Future.value();
}

_ParsedMessage? _parseRemoteMessageData(Map<String, dynamic> data) {
  final type = data['type'];
  final bodyString = data['body'];
  if (type == null || bodyString == null) {
    final error = 'Invalid notification. Type: $type, body: $bodyString';
    Sentry.captureMessage(error);
    debugPrint(error);
    return null;
  }

  final body = jsonDecode(bodyString);
  if (type == 'call') {
    return _Call.fromJson(body);
  } else if (type == 'call_ended') {
    return _CallEnded.fromJson(body);
  } else if (type == 'deep_link') {
    return _DeepLink.fromJson(body);
  } else {
    final error = 'Unknown notification type $type';
    Sentry.captureMessage(error);
    debugPrint(error);
    return null;
  }
}

Future<File?> getPhotoMaybeCached({
  required String uid,
  required String url,
}) async {
  try {
    final tempDir = await path_provider.getTemporaryDirectory();
    final profilesDir = Directory(path.join(tempDir.path, 'profiles'));
    File file = File(path.join(profilesDir.path, '$uid.jpg'));
    final oneDayAgo = DateTime.now().subtract(const Duration(days: 1));
    if (!await file.exists() ||
        (await file.lastModified()).isBefore(oneDayAgo)) {
      // Recache
      final response = await get(Uri.parse(url));
      await profilesDir.create(recursive: true);
      await file.writeAsBytes(response.bodyBytes);
    }
    return file;
  } catch (e, s) {
    debugPrint(e.toString());
    debugPrint(s.toString());
  }
  return null;
}

Future<void> _initializeLocalNotifications() {
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const darwinInit = DarwinInitializationSettings();
  const initializationSettings = InitializationSettings(
    android: androidInit,
    iOS: darwinInit,
  );
  return flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

@freezed
class _ParsedMessage with _$_ParsedMessage {
  const factory _ParsedMessage.call({
    required String uid,
    required String name,
    required String photo,
    required String rid,
    required bool blurPhotos,
  }) = _Call;

  const factory _ParsedMessage.callEnded({
    required String rid,
  }) = _CallEnded;

  const factory _ParsedMessage.deepLink(String path) = _DeepLink;

  factory _ParsedMessage.fromJson(Map<String, dynamic> json) =>
      _$_ParsedMessageFromJson(json);
}
