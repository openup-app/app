import 'package:freezed_annotation/freezed_annotation.dart';

part 'preferences.freezed.dart';
part 'preferences.g.dart';

@freezed
class Preferences with _$Preferences {
  const factory Preferences({
    @RangeJsonConverter() required Set<Gender> gender,
    required Set<SkinColor> skinColor,
    @RangeJsonConverter() @JsonKey() required Range weight,
    @RangeJsonConverter() @JsonKey() required Range height,
    required Set<String> ethnicity,
  }) = _Preferences;

  factory Preferences.fromJson(Map<String, dynamic> json) =>
      _$PreferencesFromJson(json);
}

@freezed
class Range with _$Range {
  const factory Range({
    required int min,
    required int max,
  }) = _Range;

  factory Range.fromJson(Map<String, dynamic> json) => _$RangeFromJson(json);
}

class RangeJsonConverter implements JsonConverter<Range, List<dynamic>> {
  static const defaultRange = Range(min: 1, max: 10);

  const RangeJsonConverter();

  @override
  Range fromJson(List<dynamic>? json) =>
      json == null ? defaultRange : Range(min: json[0], max: json[1]);

  @override
  List<dynamic> toJson(Range? object) => object == null
      ? [defaultRange.min, defaultRange.max]
      : [object.min, object.max];
}

enum Gender { male, female, nonBinary, transgender }

enum SkinColor { light, mediumLight, medium, mediumDark, dark }
