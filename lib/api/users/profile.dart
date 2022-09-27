import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:openup/api/api.dart';

part 'profile.freezed.dart';
part 'profile.g.dart';

@freezed
class Profile with _$Profile {
  const factory Profile({
    required String uid,
    required String name,
    String? audio,
    required String photo,
    required List<String> gallery,
    required bool blurPhotos,
    required String location,
    required Topic topic,
  }) = _Profile;

  // Private constructor required for adding methods
  const Profile._();

  SimpleProfile toSimpleProfile() {
    return SimpleProfile(
      uid: uid,
      name: name,
      photo: photo,
      blurPhotos: blurPhotos,
    );
  }

  factory Profile.fromJson(Map<String, dynamic> json) =>
      _$ProfileFromJson(json);
}

@freezed
class SimpleProfile with _$SimpleProfile {
  const factory SimpleProfile({
    required String uid,
    required String name,
    required String photo,
    required bool blurPhotos,
  }) = _SimpleProfile;

  factory SimpleProfile.fromJson(Map<String, dynamic> json) =>
      _$SimpleProfileFromJson(json);
}
