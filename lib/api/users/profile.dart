import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:openup/api/users/preferences.dart';

part 'profile.freezed.dart';
part 'profile.g.dart';

@freezed
class Profile with _$Profile {
  const factory Profile({
    required String uid,
    required String name,
    required DateTime birthday,
    String? audio,
    required String photo,
    required List<String> gallery,
  }) = _Profile;

  // Private constructor required for adding methods
  const Profile._();

  SimpleProfile toSimpleProfile() {
    return SimpleProfile(
      uid: uid,
      name: name,
      photo: photo,
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
  }) = _SimpleProfile;

  factory SimpleProfile.fromJson(Map<String, dynamic> json) =>
      _$SimpleProfileFromJson(json);
}

@freezed
class TopicParticipant with _$TopicParticipant {
  const factory TopicParticipant({
    required String uid,
    required String name,
    required String photo,
    required int age,
    required ParticipantAttributes attributes,
    required String statusText,
  }) = _TopicParticipant;

  factory TopicParticipant.fromJson(Map<String, dynamic> json) =>
      _$TopicParticipantFromJson(json);
}

@freezed
class ParticipantAttributes with _$ParticipantAttributes {
  const factory ParticipantAttributes({
    required String ethnicity,
    required String religion,
    required String interests,
  }) = _ParticipantAttributes;

  factory ParticipantAttributes.fromJson(Map<String, dynamic> json) =>
      _$ParticipantAttributesFromJson(json);
}

@freezed
class Attributes with _$Attributes {
  const factory Attributes({
    required Gender gender,
    required SkinColor skinColor,
    required int weight,
    required int height,
    required String ethnicity,
  }) = _Attributes;

  factory Attributes.fromJson(Map<String, dynamic> json) =>
      _$AttributesFromJson(json);
}
