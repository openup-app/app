import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:openup/api/users/profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'notification_comms.freezed.dart';
part 'notification_comms.g.dart';

const _kBackgroundCallKey = "background_call";

Future<void> serializeBackgroundCallNotification(
    BackgroundCallNotification notification) async {
  final preferences = await SharedPreferences.getInstance();
  await preferences.setString(
    _kBackgroundCallKey,
    jsonEncode(notification.toJson()),
  );
}

Future<BackgroundCallNotification?>
    deserializeAndRemoveBackgroundCallNotification() async {
  final preferences = await SharedPreferences.getInstance();
  final json = preferences.getString(_kBackgroundCallKey);
  await removeBackgroundCallNotification();
  if (json != null) {
    return BackgroundCallNotification.fromJson(jsonDecode(json));
  }
  return null;
}

Future<void> removeBackgroundCallNotification() async {
  final preferences = await SharedPreferences.getInstance();
  await preferences.remove(_kBackgroundCallKey);
}

@freezed
class BackgroundCallNotification with _$BackgroundCallNotification {
  const factory BackgroundCallNotification({
    required String rid,
    required SimpleProfile profile,
    required bool video,
  }) = _BackgroundCallNotification;

  factory BackgroundCallNotification.fromJson(Map<String, dynamic> json) =>
      _$BackgroundCallNotificationFromJson(json);
}
