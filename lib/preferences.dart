import 'package:freezed_annotation/freezed_annotation.dart';

part 'preferences.freezed.dart';
part 'preferences.g.dart';

@freezed
class Preferences with _$Preferences {
  const factory Preferences({
    @RangeJsonConverter()
    @Default(Range(min: 18, max: 99))
    @JsonKey()
        Range age,
    @Default({}) Set<Gender> gender,
    @Default(20) int distance,
    @Default({}) Set<String> religion,
    @Default({}) Set<Education> education,
    @Default({}) Set<String> community,
    @Default({}) Set<String> language,
    @Default({}) Set<int> skinColor,
    @RangeJsonConverter()
    @Default(Range(min: 30, max: 200))
    @JsonKey()
        Range weight,
    @RangeJsonConverter()
    @Default(Range(min: 50, max: 250))
    @JsonKey()
        Range height,
    @Default({}) Set<String> occupation,
    @Default({}) Set<HairColor> hairColor,
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
  static const defaultRange = Range(min: 0, max: 100);

  const RangeJsonConverter();

  @override
  Range fromJson(List<dynamic>? json) =>
      json == null ? defaultRange : Range(min: json[0], max: json[1]);

  @override
  List<dynamic> toJson(Range? object) => object == null
      ? [defaultRange.min, defaultRange.max]
      : [object.min, object.max];
}

enum Gender {
  male,
  female,
  transMale,
  transFemale,
  nonBinary,
}

enum Education {
  highSchool,
  associatesDegree,
  bachelorsDegree,
  mastersDegree,
  noSchooling
}

enum HairColor { black, blonde, brunette, brown, red, gray }
