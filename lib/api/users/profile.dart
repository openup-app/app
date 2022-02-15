import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:openup/api/users/preferences.dart';

part 'profile.freezed.dart';
part 'profile.g.dart';

@freezed
class PublicProfile with _$PublicProfile {
  const factory PublicProfile({
    required String uid,
    required String name,
    required DateTime birthday,
    String? audio,
    String? photo,
    required List<String> gallery,
  }) = _PublicProfile;

  // Private constructor required for adding methods
  const PublicProfile._();

  SimpleProfile toSimpleProfile() {
    return SimpleProfile(
      uid: uid,
      name: name,
      photo: photo,
    );
  }

  factory PublicProfile.fromJson(Map<String, dynamic> json) =>
      _$PublicProfileFromJson(json);
}

@freezed
class SimpleProfile with _$SimpleProfile {
  const factory SimpleProfile({
    required String uid,
    required String name,
    String? photo,
  }) = _SimpleProfile;

  factory SimpleProfile.fromJson(Map<String, dynamic> json) =>
      _$SimpleProfileFromJson(json);
}

@freezed
class PrivateProfile with _$PrivateProfile {
  const factory PrivateProfile({
    required Gender gender,
    required SkinColor skinColor,
    required int weight,
    required int height,
    required String ethnicity,
  }) = _PrivateProfile;

  factory PrivateProfile.fromJson(Map<String, dynamic> json) =>
      _$PrivateProfileFromJson(json);
}
