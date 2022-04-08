import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:get_it/get_it.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/chat/chat_api.dart';
import 'package:openup/api/lobby/lobby_api.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/api/users/profile.dart';
import 'package:openup/call_screen.dart';
import 'package:openup/chat_screen.dart';
import 'package:openup/lobby_list_page.dart';
import 'package:openup/notifications/connectycube_call_kit_integration.dart';
import 'package:openup/notifications/notification_comms.dart';
import 'package:openup/util/string.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

part 'notifications.freezed.dart';
part 'notifications.g.dart';

/// Returns [true] if the app navigated to a deep link.
/// [key] is used to access a context with a Scaffold ancestor.
Future<bool> initializeNotifications({
  required GlobalKey scaffoldKey,
  required GlobalKey<LobbyListPageState> callPanelKey,
  required UserStateNotifier userStateNotifier,
}) async {
  FirebaseMessaging.onMessage.listen((remoteMessage) {
    _onForegroundNotification(scaffoldKey, remoteMessage, userStateNotifier);
  });
  FirebaseMessaging.onBackgroundMessage(_onBackgroundNotification);

  final deepLinked = await _handleLaunchNotification(scaffoldKey: scaffoldKey);

  initIncomingCallHandlers(
    scaffoldKey: scaffoldKey,
    callPanelKey: callPanelKey,
  );

  return deepLinked;
}

Future<void> dismissAllNotifications() =>
    FlutterLocalNotificationsPlugin().cancelAll();

/// Returns [true] if this notification did deep link, false otherwise.
Future<bool> _handleLaunchNotification({required GlobalKey scaffoldKey}) async {
  // Calls that don't go through the standard FirebaseMessaging app launch method
  BackgroundCallNotification? backgroundCallNotification;
  try {
    backgroundCallNotification = await deserializeBackgroundCallNotification();
  } catch (e, s) {
    Sentry.captureException(e, stackTrace: s);
  }
  await removeBackgroundCallNotification();

  final context = scaffoldKey.currentContext;
  if (context == null) {
    return false;
  }

  if (backgroundCallNotification != null) {
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
    payload.map(
      call: (call) {
        final context = scaffoldKey.currentContext;
        if (context != null) {
          final route =
              call.video ? 'friends-video-call' : 'friends-voice-call';
          final profile = SimpleProfile(
            uid: call.callerUid,
            name: call.name,
            photo: call.photo,
          );
          Navigator.of(context).pushNamed(
            route,
            arguments: CallPageArguments(
              rid: call.rid,
              profiles: [profile],
              rekindles: [],
              serious: false,
            ),
          );
        }
      },
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
      },
    );
    return true;
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
      final context = key.currentContext;
      if (context == null) {
        return false;
      }
      displayIncomingCall(
        rid: call.rid,
        callerUid: call.callerUid,
        callerName: call.name,
        callerPhoto: call.photo,
        video: call.video,
        onCallAccepted: () async {
          final purpose =
              call.purpose == Purpose.friends ? 'friends' : 'dating';
          final route =
              call.video ? '$purpose-video-call' : '$purpose-voice-call';
          final profile = SimpleProfile(
            uid: call.callerUid,
            name: call.name,
            photo: call.photo,
          );
          Navigator.of(context).pushNamed(
            route,
            arguments: CallPageArguments(
              rid: call.rid,
              profiles: [profile],
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
      final unreadMessageCount =
          Map.of(userStateNotifier.userState.unreadMessageCount);
      unreadMessageCount[chat.uid] = chat.chatroomUnread;
      userStateNotifier.unreadMessageCount(unreadMessageCount);
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
              Navigator.of(context).popUntil((route) => route.isFirst);
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
      if (!Platform.isIOS) {
        shouldDisplay = false;
        displayIncomingCall(
          rid: call.rid,
          callerUid: call.callerUid,
          callerName: call.name,
          callerPhoto: call.photo,
          video: call.video,
          onCallAccepted: () async {
            final backgroundCallNotification = BackgroundCallNotification(
              rid: call.rid,
              profile: SimpleProfile(
                uid: call.callerUid,
                name: call.name,
                photo: call.photo,
              ),
              video: call.video,
              purpose: Purpose.friends,
              group: call.group,
            );
            await serializeBackgroundCallNotification(
                backgroundCallNotification);
          },
          onCallRejected: () {},
        );
      }
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
    notificationBody = callerName;
    channelName = 'Calls';
    channelDescription = 'Calls from your friends';
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
    required String photo,
  }) = _NewConnectionPayload;

  factory _NotificationPayload.fromJson(Map<String, dynamic> json) =>
      _$_NotificationPayloadFromJson(json);
}
