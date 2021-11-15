import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:openup/api/users/preferences.dart';

part 'profile.freezed.dart';
part 'profile.g.dart';

@freezed
class PublicProfile with _$PublicProfile {
  const factory PublicProfile({
    String? uid,
    required String name,
    required int age,
    required String description,
    String? audio,
    String? photo,
    required List<String> gallery,
  }) = _PublicProfile;

  factory PublicProfile.fromJson(Map<String, dynamic> json) =>
      _$PublicProfileFromJson(json);
}

@freezed
class PrivateProfile with _$PrivateProfile {
  const factory PrivateProfile({
    required int age,
    required Gender gender,
    required LatLong location,
    required String religion,
    required Education education,
    required Set<String> community,
    required Set<String> language,
    required SkinColor skinColor,
    required int weight,
    required int height,
    required String occupation,
    required HairColor hairColor,
  }) = _PrivateProfile;

  factory PrivateProfile.fromJson(Map<String, dynamic> json) =>
      _$PrivateProfileFromJson(json);
}

@freezed
class LatLong with _$LatLong {
  const factory LatLong({
    required double lat,
    required double long,
  }) = _LatLong;

  factory LatLong.fromJson(Map<String, dynamic> json) =>
      _$LatLongFromJson(json);
}
