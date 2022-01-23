import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_metadata.freezed.dart';
part 'user_metadata.g.dart';

@freezed
class UserMetadata with _$UserMetadata {
  const factory UserMetadata({
    required bool onboarded,
  }) = _UserMetadata;

  factory UserMetadata.fromJson(Map<String, dynamic> json) =>
      _$UserMetadataFromJson(json);
}
