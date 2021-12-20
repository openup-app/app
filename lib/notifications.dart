import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:openup/api/chat/chat_api.dart';
import 'package:openup/api/users/users_api.dart';
import 'package:openup/chat_screen.dart';

part 'notifications.freezed.dart';
part 'notifications.g.dart';

/// Returns [true] if the app navigated to a deep link.
Future<bool> initializeNotifications({
  required BuildContext context,
  required UsersApi usersApi,
}) {
  FirebaseMessaging.onMessage.listen((remoteMessage) {
    _onForegroundNotification(remoteMessage, usersApi);
  });
  FirebaseMessaging.onBackgroundMessage(_onBackgroundNotification);

  return _handleLaunchNotification(
    context: context,
    usersApi: usersApi,
  );
}

Future<void> dismissAllNotifications() =>
    FlutterLocalNotificationsPlugin().cancelAll();

/// Returns [true] if this notification did deep link, false otherwise.
Future<bool> _handleLaunchNotification({
  required BuildContext context,
  required UsersApi usersApi,
}) async {
  final launchDetails =
      await FlutterLocalNotificationsPlugin().getNotificationAppLaunchDetails();
  if (launchDetails == null) {
    return false;
  }

  final payloadJson = launchDetails.payload;
  if (payloadJson != null) {
    final payload = _NotificationPayload.fromJson(jsonDecode(payloadJson));
    payload.map(
      call: (call) async {},
      chat: (chat) async {
        final profile = await usersApi.getPublicProfile(chat.uid);
        Navigator.of(context).pushReplacementNamed('home');
        Navigator.of(context).pushNamed(
          'chat',
          arguments: ChatArguments(
            profile: profile,
            chatroomId: chat.chatroomId,
          ),
        );
      },
    );
    return true;
  }
  return false;
}

void _onForegroundNotification(RemoteMessage message, UsersApi api) async {
  final parsed = await _parseRemoteMessage(message);
  parsed.payload?.map(
    call: (_) => _,
    chat: (chat) {
      api.updateUnreadChatMessagesCount(chat.uid, chat.chatroomUnread);
    },
  );
}

Future<void> _onBackgroundNotification(RemoteMessage message) async {
  final parsed = await _parseRemoteMessage(message);
  return _displayNotification(parsed);
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
    final uid = message.data['uid'];
    final senderName = message.data['senderName'];
    final senderPhoto = message.data['senderPhoto'];
    notificationTitle = 'Incoming call on Openup';
    notificationBody = senderName;
    channelName = 'Calls';
    channelDescription = 'Calls from your connections';
    notificationPayload = _CallPayload(
      video: true,
      rid: '',
      uid: uid,
    );
  } else if (type == 'chat') {
    final messageJson = message.data['message'];
    final senderName = message.data['senderName'];
    final senderPhoto = message.data['senderPhoto'];
    notificationTitle = senderName;
    chatroomId = message.data['chatroomId'];
    final chatroomUnread = int.parse(message.data['chatroomUnread']);
    final chatMessage = ChatMessage.fromJson(jsonDecode(messageJson));
    channelName = 'Chat messages';
    channelDescription = 'Messages from your connections';
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
    required String uid,
    required String rid,
    required bool video,
  }) = _CallPayload;

  const factory _NotificationPayload.chat({
    required String uid,
    required String chatroomId,
    required int chatroomUnread,
  }) = _ChatPayload;

  factory _NotificationPayload.fromJson(Map<String, dynamic> json) =>
      _$_NotificationPayloadFromJson(json);
}
