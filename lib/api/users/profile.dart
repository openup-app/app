import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:openup/api/users/preferences.dart';

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
    required List<String> gallery,
    required List<String> interests,
    required String location,
    required String topic,
    required String audioUrl,
    required DateTime endTime,
  }) = _TopicParticipant;

  factory TopicParticipant.fromJson(Map<String, dynamic> json) =>
      _$TopicParticipantFromJson(json);
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

@freezed
class Interests with _$Interests {
  const factory Interests({
    required List<String> interests,
  }) = _Interests;

  factory Interests.fromJson(Map<String, dynamic> json) =>
      _$InterestsFromJson(json);
}
