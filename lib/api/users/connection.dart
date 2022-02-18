import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:openup/api/users/profile.dart';

part 'connection.freezed.dart';
part 'connection.g.dart';

@freezed
class Connection with _$Connection {
  const factory Connection({
    required Profile profile,
    required String chatroomId,
    required int chatroomUnread,
  }) = _Connection;

  factory Connection.fromJson(Map<String, dynamic> json) =>
      _$ConnectionFromJson(json);
}
