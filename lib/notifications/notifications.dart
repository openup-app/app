import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:openup/api/chat/chat_api.dart';
import 'package:openup/api/lobby/lobby_api.dart';
import 'package:openup/api/users/users_api.dart';
import 'package:openup/call_screen.dart';
import 'package:openup/chat_screen.dart';
import 'package:openup/main.dart';
import 'package:openup/notifications/connectycube_call_kit_integration.dart';
import 'package:openup/notifications/notification_comms.dart';
import 'package:openup/util/string.dart';

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
  // Calls that don't go through the standard FirebaseMessaging app launch method
  final backgroundCallNotification =
      await deserializeBackgroundCallNotification();
  await removeBackgroundCallNotification();
  if (backgroundCallNotification != null) {
    final video = backgroundCallNotification.video;
    final purpose = backgroundCallNotification.purpose == Purpose.friends
        ? 'friends'
        : 'dating';
    final route = video ? '$purpose-video-call' : '$purpose-voice-call';
    final profile =
        await usersApi.getPublicProfile(backgroundCallNotification.uid);
    Navigator.of(context).pushReplacementNamed('home');
    Navigator.of(context).pushNamed(
      route,
      arguments: CallPageArguments(
        uid: FirebaseAuth.instance.currentUser!.uid,
        initiator: false,
        profiles: [profile],
        rekindles: [],
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

void _onForegroundNotification(RemoteMessage message, UsersApi usersApi) async {
  final parsed = await _parseRemoteMessage(message);
  parsed.payload?.map(
    call: (call) {
      displayIncomingCall(
        rid: call.rid,
        callerName: call.name,
        video: call.video,
        onCallAccepted: () async {
          final purpose =
              call.purpose == Purpose.friends ? 'friends' : 'dating';
          final route =
              call.video ? '$purpose-video-call' : '$purpose-voice-call';
          final profile = await usersApi.getPublicProfile(call.uid);
          Navigator.of(navigatorKey.currentContext!).pushNamed(
            route,
            arguments: CallPageArguments(
              uid: FirebaseAuth.instance.currentUser!.uid,
              initiator: false,
              profiles: [profile],
              rekindles: [],
            ),
          );
        },
        onCallRejected: () {},
      );
    },
    chat: (chat) {
      usersApi.updateUnreadChatMessagesCount(chat.uid, chat.chatroomUnread);
    },
  );
}

Future<void> _onBackgroundNotification(RemoteMessage message) async {
  bool shouldDisplay = true;
  final parsed = await _parseRemoteMessage(message);
  parsed.payload?.map(
    call: (call) {
      shouldDisplay = false;
      displayIncomingCall(
        rid: call.rid,
        callerName: call.name,
        video: call.video,
        onCallAccepted: () async {
          final backgroundCallNotification = BackgroundCallNotification(
            uid: call.uid,
            video: call.video,
            purpose: Purpose.friends,
          );
          await serializeBackgroundCallNotification(backgroundCallNotification);
        },
        onCallRejected: () {},
      );
    },
    chat: (_) {},
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
    final uid = message.data['uid'];
    final senderName = message.data['senderName'];
    final senderPhoto = message.data['senderPhoto'];
    final rid = message.data['rid'];
    final purpose =
        message.data['purpose'] == 'friends' ? Purpose.friends : Purpose.dating;
    final video = (message.data['video'] as String).parseBool();
    notificationTitle =
        'Incoming ${video ? 'video call' : 'call'} from $senderName';
    notificationBody = senderName;
    channelName = 'Calls';
    channelDescription = 'Calls from your connections';
    notificationPayload = _CallPayload(
      name: senderName,
      photo: senderPhoto,
      video: video,
      rid: rid,
      uid: uid,
      purpose: purpose,
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
    required String name,
    required String photo,
    required String rid,
    required Purpose purpose,
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
