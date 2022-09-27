import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/call_manager.dart';
import 'package:openup/api/chat_api.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/chat_page.dart';
import 'package:openup/home_screen.dart';
import 'package:openup/notifications/android_voip_handlers.dart'
    as android_voip;
import 'package:openup/notifications/ios_voip_handlers.dart' as ios_voip;
import 'package:openup/notifications/notification_comms.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:sentry_flutter/sentry_flutter.dart';

part 'notifications.freezed.dart';
part 'notifications.g.dart';

typedef UseContext = bool Function(BuildContext context);

void initializeVoipHandlers() {
  if (Platform.isAndroid) {
    android_voip.initAndroidVoipHandlers();
  } else if (Platform.isIOS) {
    ios_voip.initIosVoipHandlers();
  }
}

Future<void> initializeNotifications({
  required GlobalKey scaffoldKey,
  required UserStateNotifier userStateNotifier,
}) async {
  await _initializeLocalNotifications(scaffoldKey);
  FirebaseMessaging.onBackgroundMessage(_onBackgroundNotification);
  FirebaseMessaging.onMessage.listen((remoteMessage) {
    _onForegroundNotification(scaffoldKey, remoteMessage, userStateNotifier);
  });

  FirebaseMessaging.instance
      .setForegroundNotificationPresentationOptions(alert: true);
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

/// Returns a function that needs a mounted [BuildContext]. The function
/// returns [true] if the app used the context to navigate somewhere.
Future<UseContext?> handleLaunchNotification() async {
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
      final activeCall = createActiveCall(
        uid,
        backgroundCallNotification.rid,
        backgroundCallNotification.profile,
        backgroundCallNotification.video,
      );
      activeCall.phone.join();
      GetIt.instance.get<CallManager>().activeCall = activeCall;
    }
    return (BuildContext context) {
      Navigator.of(context).pushReplacementNamed('home');
      Navigator.of(context).pushNamed('call');
      return true;
    };
  }

  final launchDetails =
      await FlutterLocalNotificationsPlugin().getNotificationAppLaunchDetails();
  if (launchDetails == null) {
    return null;
  }

  final payload = launchDetails.payload;
  if (payload != null) {
    final parsedMessage = _ParsedMessage.fromJson(jsonDecode(payload));
    return _handleDeepLink(parsedMessage);
  }
  return null;
}

void _onForegroundNotification(
  GlobalKey key,
  RemoteMessage message,
  UserStateNotifier userStateNotifier,
) {
  final parsedMessage = _parseRemoteMessage(message);
  parsedMessage?.map(
    call: (call) {
      final profile = SimpleProfile(
        uid: call.uid,
        name: call.name,
        photo: call.photo,
        blurPhotos: call.blurPhotos,
      );
      if (Platform.isAndroid) {
        android_voip.displayIncomingCall(
          rid: call.rid,
          profile: profile,
          video: false,
        );
      }
    },
    callEnded: (callEnded) => reportCallEnded(callEnded.rid),
    chat: (_) => _displayNotification(parsedMessage),
    newInvite: (_) => _displayNotification(parsedMessage),
    inviteAccepted: (_) => _displayNotification(parsedMessage),
  );
}

Future<void> _onBackgroundNotification(RemoteMessage message) {
  final parsedMessage = _parseRemoteMessage(message);
  parsedMessage?.map(
    call: (call) {
      final profile = SimpleProfile(
        uid: call.uid,
        name: call.name,
        photo: call.photo,
        blurPhotos: call.blurPhotos,
      );
      if (Platform.isAndroid) {
        android_voip.displayIncomingCall(
          rid: call.rid,
          profile: profile,
          video: false,
        );
      }
      // iOS handles incoming call separately using PushKit and CallKit
    },
    callEnded: (callEnded) => reportCallEnded(callEnded.rid),
    chat: (_) => _displayNotification(parsedMessage, background: true),
    newInvite: (_) => _displayNotification(parsedMessage, background: true),
    inviteAccepted: (_) =>
        _displayNotification(parsedMessage, background: true),
  );
  return Future.value();
}

_ParsedMessage? _parseRemoteMessage(RemoteMessage message) {
  final String? type = message.data['type'];
  final String? bodyString = message.data['body'];
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
  } else if (type == 'chat') {
    return _Chat.fromJson(body);
  } else if (type == 'new_invite') {
    return _NewInvite.fromJson(body);
  } else if (type == 'invite_accepted') {
    return _InviteAccepted.fromJson(body);
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

Future<void> _initializeLocalNotifications(GlobalKey globalKey) {
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iOSInit = IOSInitializationSettings();
  const initializationSettings = InitializationSettings(
    android: androidInit,
    iOS: iOSInit,
  );
  return flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onSelectNotification: (deepLinkPayload) async {
      if (deepLinkPayload != null) {
        final _ParsedMessage parsedMessage;
        try {
          parsedMessage = _ParsedMessage.fromJson(jsonDecode(deepLinkPayload));
        } on FormatException catch (e, s) {
          debugPrint(e.toString());
          debugPrint(s.toString());
          return;
        }
        final useContext = await _handleDeepLink(parsedMessage);
        final context = globalKey.currentContext;
        if (context != null) {
          // ignore: use_build_context_synchronously
          useContext?.call(context);
        }
      }
    },
  );
}

Future<UseContext?> _handleDeepLink(_ParsedMessage parsedMessage) {
  final api = GetIt.instance.get<Api>();
  return parsedMessage.map(
    call: (call) async {
      return (BuildContext context) {
        Navigator.of(context).pushReplacementNamed('home');
        Navigator.of(context).pushNamed('call');
        return true;
      };
    },
    callEnded: (_) => Future.value(),
    chat: (chat) async {
      final result = await api.getProfile(chat.senderUid);
      return (BuildContext context) {
        return result.fold((l) {
          displayError(context, l);
          return false;
        }, (profile) {
          Navigator.of(context).popUntil((route) => route.isFirst);
          Navigator.of(context).popAndPushNamed(
            'home',
            arguments: DeepLinkArgs.chat(
              ChatPageArguments(
                otherUid: profile.uid,
                otherProfile: profile,
                otherLocation: profile.location,
                online: false,
                endTime: DateTime.now().add(
                  const Duration(days: 3),
                ),
              ),
            ),
          );
          return true;
        });
      };
    },
    newInvite: (newInvite) async {
      return (BuildContext context) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        Navigator.of(context).popAndPushNamed(
          'home',
          arguments: const DeepLinkArgs.friendships(),
        );
        return true;
      };
    },
    inviteAccepted: (inviteAccepted) async {
      final result = await api.getProfile(inviteAccepted.uid);
      return (BuildContext context) {
        return result.fold((l) {
          displayError(context, l);
          return false;
        }, (profile) {
          Navigator.of(context).popUntil((route) => route.isFirst);
          Navigator.of(context).popAndPushNamed(
            'home',
            arguments: DeepLinkArgs.chat(
              ChatPageArguments(
                otherUid: profile.uid,
                otherProfile: profile,
                otherLocation: profile.location,
                online: false,
                endTime: DateTime.now().add(
                  const Duration(days: 3),
                ),
              ),
            ),
          );
          return true;
        });
      };
    },
  );
}

Future<void> _displayNotification(
  _ParsedMessage parsedMessage, {
  bool background = false,
}) {
  final plugin = FlutterLocalNotificationsPlugin();
  return parsedMessage.map(
    call: (call) => Future.value(),
    callEnded: (callEnded) => Future.value(),
    chat: (chat) async {
      final File? photoFile;
      if (background && Platform.isIOS) {
        // Pauses execution until app is open, then delivers notification, so
        // just skip photos
        photoFile = null;
      } else {
        photoFile = await getPhotoMaybeCached(
          uid: chat.senderName,
          url: chat.senderPhoto,
        );
      }
      final bytes = await photoFile?.readAsBytes();
      const message = "New voice message";
      plugin.show(
        chat.message.messageId?.hashCode ?? 0,
        "New voice message 🗣️",
        "${chat.senderName} sent you a message!",
        payload: jsonEncode(parsedMessage.toJson()),
        NotificationDetails(
          android: AndroidNotificationDetails(
            "chat",
            "Chat messages",
            channelDescription: "Messages from your friends",
            ticker: message,
            groupKey: chat.senderUid,
            styleInformation: MessagingStyleInformation(
              Person(
                name: chat.senderName,
                key: chat.senderUid,
                icon: bytes == null ? null : ByteArrayAndroidIcon(bytes),
              ),
              messages: [
                Message(
                  message,
                  chat.message.date,
                  Person(
                    name: chat.senderName,
                    key: chat.senderUid,
                    icon: bytes == null ? null : ByteArrayAndroidIcon(bytes),
                  ),
                ),
              ],
            ),
          ),
          iOS: IOSNotificationDetails(
            attachments: photoFile == null
                ? null
                : [IOSNotificationAttachment(photoFile.path)],
            threadIdentifier: chat.chatroomId,
          ),
        ),
      );
    },
    newInvite: (newInvite) async {
      final photoFile = await getPhotoMaybeCached(
        uid: newInvite.uid,
        url: newInvite.photo,
      );
      final bytes = await photoFile?.readAsBytes();
      final notificationId = 'new_invite_${newInvite.chatroomId}'.hashCode;
      plugin.show(
        notificationId,
        "🎊 You got an invite 🎊",
        "${newInvite.name} has sent you an invitation to chat!",
        payload: jsonEncode(parsedMessage.toJson()),
        NotificationDetails(
          android: AndroidNotificationDetails(
            "invites",
            "New invites",
            channelDescription: "New chat invites from others",
            groupKey: newInvite.uid,
            largeIcon: bytes == null ? null : ByteArrayAndroidBitmap(bytes),
            styleInformation: const MediaStyleInformation(),
          ),
          iOS: IOSNotificationDetails(
            attachments: photoFile == null
                ? null
                : [IOSNotificationAttachment(photoFile.path)],
          ),
        ),
      );
    },
    inviteAccepted: (inviteAccepted) async {
      final photoFile = await getPhotoMaybeCached(
        uid: inviteAccepted.uid,
        url: inviteAccepted.photo,
      );
      final bytes = await photoFile?.readAsBytes();
      final notificationId =
          'invite_accepted_${inviteAccepted.chatroomId}'.hashCode;
      plugin.show(
        notificationId,
        "${inviteAccepted.name} has accepted your chat invite! 🎊",
        null,
        payload: jsonEncode(parsedMessage.toJson()),
        NotificationDetails(
          android: AndroidNotificationDetails(
            "new_connection",
            "New friends",
            channelDescription: "When your chat invites are accepted",
            groupKey: inviteAccepted.uid,
            largeIcon: bytes == null ? null : ByteArrayAndroidBitmap(bytes),
            styleInformation: const MediaStyleInformation(),
          ),
          iOS: IOSNotificationDetails(
            attachments: photoFile == null
                ? null
                : [IOSNotificationAttachment(photoFile.path)],
          ),
        ),
      );
    },
  );
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

  const factory _ParsedMessage.chat({
    required String senderUid,
    required String senderName,
    required String senderPhoto,
    required String chatroomId,
    required ChatMessage message,
  }) = _Chat;

  const factory _ParsedMessage.newInvite({
    required String uid,
    required String name,
    required String photo,
    required String chatroomId,
  }) = _NewInvite;

  const factory _ParsedMessage.inviteAccepted({
    required String uid,
    required String name,
    required String photo,
    required String chatroomId,
  }) = _InviteAccepted;

  factory _ParsedMessage.fromJson(Map<String, dynamic> json) =>
      _$_ParsedMessageFromJson(json);
}
