import 'dart:convert';

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
/// [key] is used to access a context with a Scaffold ancestor.
Future<bool> initializeNotifications({
  required GlobalKey key,
  required UsersApi usersApi,
}) {
  FirebaseMessaging.onMessage.listen((remoteMessage) {
    _onForegroundNotification(key, remoteMessage, usersApi);
  });
  FirebaseMessaging.onBackgroundMessage(_onBackgroundNotification);

  return _handleLaunchNotification(
    key: key,
    usersApi: usersApi,
  );
}

Future<void> dismissAllNotifications() =>
    FlutterLocalNotificationsPlugin().cancelAll();

/// Returns [true] if this notification did deep link, false otherwise.
Future<bool> _handleLaunchNotification({
  required GlobalKey key,
  required UsersApi usersApi,
}) async {
  // Calls that don't go through the standard FirebaseMessaging app launch method
  final backgroundCallNotification =
      await deserializeBackgroundCallNotification();
  await removeBackgroundCallNotification();

  final context = key.currentContext;
  if (context == null) {
    return false;
  }

  if (backgroundCallNotification != null) {
    final rid = backgroundCallNotification.rid;
    final video = backgroundCallNotification.video;
    final group = backgroundCallNotification.group;
    final purpose = backgroundCallNotification.purpose == Purpose.friends
        ? 'friends'
        : 'dating';
    final route = video ? '$purpose-video-call' : '$purpose-voice-call';
    final profile =
        await usersApi.getPublicProfile(backgroundCallNotification.callerUid);
    Navigator.of(context).pushReplacementNamed('home');
    Navigator.of(context).pushNamed(
      route,
      arguments: CallPageArguments(
        rid: rid,
        profiles: [profile.toSimpleProfile()],
        rekindles: [],
        serious: false,
        groupLobby: group,
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
      call: (call) {},
      chat: (chat) async {
        final profile = await usersApi.getPublicProfile(chat.uid);
        Navigator.of(context).pushReplacementNamed('home');
        Navigator.of(context).pushNamed(
          'chat',
          arguments: ChatArguments(
            uid: profile.uid,
            chatroomId: chat.chatroomId,
          ),
        );
      },
      newConnection: (newConnection) async {
        final profile = await usersApi.getPublicProfile(newConnection.uid);
        Navigator.of(context).pushReplacementNamed('home');
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
  }
  return false;
}

void _onForegroundNotification(
  GlobalKey key,
  RemoteMessage message,
  UsersApi usersApi,
) async {
  final parsed = await _parseRemoteMessage(message);
  parsed.payload?.map(
    call: (call) {
      displayIncomingCall(
        rid: call.rid,
        callerUid: call.callerUid,
        callerName: call.name,
        video: call.video,
        onCallAccepted: () async {
          final purpose =
              call.purpose == Purpose.friends ? 'friends' : 'dating';
          final route =
              call.video ? '$purpose-video-call' : '$purpose-voice-call';
          final profile = await usersApi.getPublicProfile(call.callerUid);
          Navigator.of(navigatorKey.currentContext!).pushNamed(
            route,
            arguments: CallPageArguments(
              rid: call.rid,
              profiles: [profile.toSimpleProfile()],
              rekindles: [],
              serious: false,
              groupLobby: call.group,
            ),
          );
        },
        onCallRejected: () {},
      );
    },
    chat: (chat) {
      usersApi.updateUnreadChatMessagesCount(chat.uid, chat.chatroomUnread);
    },
    newConnection: (newConnection) {
      final context = key.currentContext;
      if (context == null) {
        return false;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${newConnection.name} has accepted your connection!'),
          action: SnackBarAction(
            label: 'Chat',
            onPressed: () {
              Navigator.of(context).pushNamed(
                'chat',
                arguments: ChatArguments(
                  uid: newConnection.uid,
                  chatroomId: newConnection.chatroomId,
                ),
              );
            },
          ),
        ),
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
      displayIncomingCall(
        rid: call.rid,
        callerUid: call.callerUid,
        callerName: call.name,
        video: call.video,
        onCallAccepted: () async {
          final backgroundCallNotification = BackgroundCallNotification(
            callerUid: call.callerUid,
            rid: call.rid,
            video: call.video,
            purpose: Purpose.friends,
            group: call.group,
          );
          await serializeBackgroundCallNotification(backgroundCallNotification);
        },
        onCallRejected: () {},
      );
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
    final purpose =
        message.data['purpose'] == 'friends' ? Purpose.friends : Purpose.dating;
    final video = (message.data['video'] as String).parseBool();
    final group = (message.data['group'] as String).parseBool();
    notificationTitle = group
        ? ('Incoming ${purpose == Purpose.friends ? 'friends with friends' : 'double date'} ${video ? 'video call' : 'call'} from $callerName')
        : ('Incoming ${video ? 'video call' : 'call'} from $callerName');
    print('Received ${message.data} $group, title $notificationTitle');
    notificationBody = callerName;
    channelName = 'Calls';
    channelDescription = 'Calls from your connections';
    notificationPayload = _CallPayload(
      callerUid: callerUid,
      name: callerName,
      photo: callerPhoto,
      video: video,
      group: group,
      rid: rid,
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
  } else if (type == 'new_connection') {
    channelName = 'New connections';
    channelDescription = 'When you make a new connection';
    final name = message.data['name'];
    notificationPayload = _NewConnectionPayload(
      uid: message.data['uid'],
      chatroomId: message.data['chatroomId'],
      name: name,
      photo: message.data['photo'],
    );
    notificationTitle = '$name accepted your connection!';
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
    required Purpose purpose,
    required bool video,
    required bool group,
  }) = _CallPayload;

  const factory _NotificationPayload.chat({
    required String uid,
    required String chatroomId,
    required int chatroomUnread,
  }) = _ChatPayload;

  const factory _NotificationPayload.newConnection({
    required String uid,
    required String chatroomId,
    required String name,
    required String? photo,
  }) = _NewConnectionPayload;

  factory _NotificationPayload.fromJson(Map<String, dynamic> json) =>
      _$_NotificationPayloadFromJson(json);
}
