import 'package:openup/api/users/preferences.dart';

/// A list of 5 emojis with skin colors ramping from light to dark,
/// based on the gender provided.
List<String> emojiForGender(Gender gender) {
  const faceLists = [
    ['🧑🏻', '🧑🏼', '🧑🏽', '🧑🏾', '🧑🏿'],
    ['👨🏻', '👨🏼', '👨🏽', '👨🏾', '👨🏿'],
    ['👩🏻', '👩🏼', '👩🏽', '👩🏾', '👩🏿'],
  ];
  switch (gender) {
    case Gender.male:
    case Gender.transMale:
      return faceLists[1];
    case Gender.female:
    case Gender.transFemale:
      return faceLists[2];
    case Gender.nonBinary:
      return faceLists[0];
  }
}

/// Converts gender preferences into a single gender. No preference implies
/// non-binary, as does a preference of both a male and female type gender.
Gender genderForPreferredGenders(Set<Gender> genders) {
  final containsMale =
      genders.contains(Gender.male) || genders.contains(Gender.transMale);
  final containsFemale =
      genders.contains(Gender.female) || genders.contains(Gender.transFemale);
  final containsNonBinary =
      genders.isEmpty || genders.contains(Gender.nonBinary);
  if (containsNonBinary) {
    return Gender.nonBinary;
  } else if (containsMale && !containsFemale) {
    return Gender.male;
  } else if (containsFemale && !containsMale) {
    return Gender.female;
  } else {
    return Gender.nonBinary;
  }
}
