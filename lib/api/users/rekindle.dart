import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:openup/api/lobby/lobby_api.dart';

part 'rekindle.freezed.dart';
part 'rekindle.g.dart';

@freezed
class Rekindle with _$Rekindle {
  const factory Rekindle({
    required String uid,
    required int date,
    required Purpose purpose,
    required String name,
    String? photo,
  }) = _Rekindle;

  factory Rekindle.fromJson(Map<String, dynamic> json) =>
      _$RekindleFromJson(json);
}
