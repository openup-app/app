import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:get_it/get_it.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/call_state.dart';
import 'package:openup/api/chat/chat_api.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/api/users/profile.dart';
import 'package:openup/call_system.dart';
import 'package:openup/chat_screen.dart';
import 'package:openup/lobby_list_page.dart';
import 'package:openup/notifications/android_voip_handlers.dart'
    as android_voip;
import 'package:openup/notifications/ios_voip_handlers.dart' as ios_voip;
import 'package:openup/notifications/notification_comms.dart';
import 'package:openup/profile_screen.dart';
import 'package:openup/widgets/new_friend_banner.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

part 'notifications.freezed.dart';
part 'notifications.g.dart';

/// Returns [true] if the app navigated to a deep link.
Future<bool> initializeNotifications({
  required GlobalKey scaffoldKey,
  required UserStateNotifier userStateNotifier,
}) async {
  FirebaseMessaging.onMessage.listen((remoteMessage) {
    _onForegroundNotification(scaffoldKey, remoteMessage, userStateNotifier);
  });
  FirebaseMessaging.onBackgroundMessage(_onBackgroundNotification);

  bool deepLinked = false;
  final temporaryContext = scaffoldKey.currentContext;
  if (temporaryContext != null) {
    deepLinked = await _handleLaunchNotification(temporaryContext);
  }

  if (Platform.isAndroid) {
    android_voip.initAndroidVoipHandlers();
  } else if (Platform.isIOS) {
    ios_voip.initIosVoipHandlers();
  }

  return deepLinked;
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

/// Returns [true] if this notification did deep link, false otherwise.
Future<bool> _handleLaunchNotification(BuildContext context) async {
  // Calls that don't go through the standard FirebaseMessaging app launch method
  BackgroundCallNotification? backgroundCallNotification;
  try {
    backgroundCallNotification =
        await deserializeAndRemoveBackgroundCallNotification();
  } catch (e, s) {
    Sentry.captureException(e, stackTrace: s);
  }

  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (backgroundCallNotification != null && uid != null) {
    if (Platform.isAndroid) {
      final activeCall = android_voip.createActiveCall(
        uid,
        backgroundCallNotification.rid,
        backgroundCallNotification.profile,
      );
      activeCall.phone.join();
      GetIt.instance.get<CallState>().callInfo = activeCall;
    }
    Navigator.of(context).popUntil((r) => r.isFirst);
    Navigator.of(context).pushReplacementNamed(
      'lobby-list',
      arguments: StartWithCall(
        rid: backgroundCallNotification.rid,
        profile: backgroundCallNotification.profile,
      ),
    );

    return true;
  }

  final launchDetails =
      await FlutterLocalNotificationsPlugin().getNotificationAppLaunchDetails();
  if (launchDetails == null) {
    return false;
  }

  final payloadJson = launchDetails.payload;
  if (payloadJson != null) {
    final payload = _NotificationPayload.fromJson(jsonDecode(payloadJson));
    final api = GetIt.instance.get<Api>();
    return payload.map(
      call: (call) => false,
      callEnded: (_) => false,
      chat: (chat) async {
        final result = await api.getProfile(chat.uid);
        result.fold(
          (l) => displayError(context, l),
          (profile) {
            Navigator.of(context).pushReplacementNamed('lobby-list');
            Navigator.of(context).pushNamed(
              'chat',
              arguments: ChatArguments(
                uid: profile.uid,
                chatroomId: chat.chatroomId,
              ),
            );
          },
        );
        return true;
      },
      newConnection: (newConnection) async {
        final result = await api.getProfile(newConnection.uid);
        result.fold(
          (l) => displayError(context, l),
          (profile) {
            Navigator.of(context).pushReplacementNamed('lobby-list');
            Navigator.of(context).pushNamed(
              'chat',
              arguments: ChatArguments(
                uid: profile.uid,
                chatroomId: newConnection.chatroomId,
              ),
            );
          },
        );
        return true;
      },
    );
  }
  return false;
}

void _onForegroundNotification(
  GlobalKey key,
  RemoteMessage message,
  UserStateNotifier userStateNotifier,
) async {
  final parsed = await _parseRemoteMessage(message);
  parsed.payload?.map(
    call: (call) {
      final profile = SimpleProfile(
        uid: call.callerUid,
        name: call.name,
        photo: call.photo,
      );
      if (Platform.isAndroid) {
        android_voip.displayIncomingCall(
          rid: call.rid,
          profile: profile,
          video: false,
        );
      }
    },
    callEnded: (callEnded) {
      reportCallEnded(callEnded.rid);
    },
    chat: (chat) {
      final unreadMessageCount =
          Map.of(userStateNotifier.userState.unreadMessageCount);
      unreadMessageCount[chat.uid] = chat.chatroomUnread;
      userStateNotifier.unreadMessageCount(unreadMessageCount);
    },
    newConnection: (newConnection) async {
      final context = key.currentContext;
      if (context == null) {
        return false;
      }

      final api = GetIt.instance.get<Api>();
      final result = await api.getProfile(newConnection.uid);
      result.fold(
        (l) {},
        (r) {
          showTopSnackBar(
            context,
            NewFriendBanner(
              uid: newConnection.uid,
              name: newConnection.name,
              photo: newConnection.photo,
              chatroomId: newConnection.chatroomId,
            ),
            onTap: () {
              Navigator.of(context).pushNamed(
                'profile',
                arguments: ProfileArguments(profile: r, editable: false),
              );
            },
          );
        },
      );
    },
  );
}

Future<void> _onBackgroundNotification(RemoteMessage message) async {
  bool shouldDisplay = true;
  final parsed = await _parseRemoteMessage(message);
  parsed.payload?.map(
    call: (call) {
      shouldDisplay = false;
      final profile = SimpleProfile(
        uid: call.callerUid,
        name: call.name,
        photo: call.photo,
      );
      if (Platform.isAndroid) {
        android_voip.displayIncomingCall(
          rid: call.rid,
          profile: profile,
          video: false,
        );
      }
    },
    callEnded: (callEnded) {
      reportCallEnded(callEnded.rid);
    },
    chat: (_) {},
    newConnection: (_) {},
  );
  if (shouldDisplay) {
    return _displayNotification(parsed);
  }
}

Future<_ParsedNotification> _parseRemoteMessage(RemoteMessage message) async {
  final type = message.data['type'];
  final String notificationTitle;
  final String notificationBody;
  final _NotificationPayload notificationPayload;
  final String channelName;
  final String channelDescription;

  String? chatroomId;
  if (type == 'call') {
    final callerUid = message.data['callerUid'];
    final callerName = message.data['callerName'];
    final callerPhoto = message.data['callerPhoto'];
    final rid = message.data['rid'];
    notificationTitle = 'Incoming audio call from $callerName';
    notificationBody = callerName;
    channelName = 'Calls';
    channelDescription = 'Calls from your friends';
    notificationPayload = _CallPayload(
      callerUid: callerUid,
      name: callerName,
      photo: callerPhoto,
      rid: rid,
    );
  } else if (type == 'call_ended') {
    final rid = message.data['rid'];
    notificationPayload = _CallEndedPayload(rid: rid);
    notificationTitle = '';
    notificationBody = '';
    channelName = '';
    channelDescription = '';
  } else if (type == 'chat') {
    final messageJson = message.data['message'];
    final senderName = message.data['senderName'];
    final senderPhoto = message.data['senderPhoto'];
    notificationTitle = senderName;
    chatroomId = message.data['chatroomId'];
    final chatroomUnread = int.parse(message.data['chatroomUnread']);
    final chatMessage = ChatMessage.fromJson(jsonDecode(messageJson));
    channelName = 'Chat messages';
    channelDescription = 'Messages from your friends';
    notificationPayload = _ChatPayload(
      uid: chatMessage.uid,
      chatroomId: chatroomId!,
      chatroomUnread: chatroomUnread,
    );

    switch (chatMessage.type) {
      case ChatType.emoji:
        notificationBody = chatMessage.content;
        break;
      case ChatType.image:
        notificationBody = '$senderName sent a photo';
        break;
      case ChatType.video:
        notificationBody = '$senderName sent a video';
        break;
      case ChatType.audio:
        notificationBody = '$senderName sent a voice memo';
        break;
    }
  } else if (type == 'new_connection') {
    channelName = 'New friends';
    channelDescription = 'When you make a new friend';
    final name = message.data['name'];
    notificationPayload = _NewConnectionPayload(
      uid: message.data['uid'],
      chatroomId: message.data['chatroomId'],
      name: name,
      photo: message.data['photo'],
    );
    notificationTitle = '$name accepted your friend request!';
    notificationBody = 'Tap to chat';
  } else {
    throw 'Unknown notification type $type';
  }

  await _initializeLocalNotifications();

  final androidDetails = AndroidNotificationDetails(
    type,
    channelName,
    ongoing: true,
    channelDescription: channelDescription,
    importance: Importance.max,
    priority: Priority.high,
    ticker: notificationBody,
  );
  final iOSDetails = IOSNotificationDetails(
    threadIdentifier: chatroomId,
  );
  final notificationDetails = NotificationDetails(
    android: androidDetails,
    iOS: iOSDetails,
  );

  return _ParsedNotification(
    id: 0,
    title: notificationTitle,
    body: notificationBody,
    details: notificationDetails,
    payload: notificationPayload,
  );
}

Future<void> _initializeLocalNotifications() {
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iOSInit = IOSInitializationSettings();
  const initializationSettings = InitializationSettings(
    android: androidInit,
    iOS: iOSInit,
  );
  return flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

Future<void> _displayNotification(_ParsedNotification _parsedNotification) {
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  return flutterLocalNotificationsPlugin.show(
    0,
    _parsedNotification.title,
    _parsedNotification.body,
    _parsedNotification.details,
    payload: jsonEncode(_parsedNotification.payload),
  );
}

class _ParsedNotification {
  final int id;
  final String title;
  final String body;
  final NotificationDetails details;
  final _NotificationPayload? payload;

  _ParsedNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.details,
    required this.payload,
  });
}

@freezed
class _NotificationPayload with _$_NotificationPayload {
  const factory _NotificationPayload.call({
    required String callerUid,
    required String name,
    required String photo,
    required String rid,
  }) = _CallPayload;

  const factory _NotificationPayload.callEnded({
    required String rid,
  }) = _CallEndedPayload;

  const factory _NotificationPayload.chat({
    required String uid,
    required String chatroomId,
    required int chatroomUnread,
  }) = _ChatPayload;

  const factory _NotificationPayload.newConnection({
    required String uid,
    required String chatroomId,
    required String name,
    required String photo,
  }) = _NewConnectionPayload;

  factory _NotificationPayload.fromJson(Map<String, dynamic> json) =>
      _$_NotificationPayloadFromJson(json);
}
