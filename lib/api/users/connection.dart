import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:openup/api/users/profile.dart';

part 'connection.freezed.dart';
part 'connection.g.dart';

@freezed
class Connection with _$Connection {
  const factory Connection({
    required PublicProfile profile,
    required String chatroomId,
  }) = _Connection;

  factory Connection.fromJson(Map<String, dynamic> json) =>
      _$ConnectionFromJson(json);
}
