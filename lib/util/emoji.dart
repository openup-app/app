import 'package:openup/api/users/preferences.dart';

/// A list of 5 emojis with skin colors ramping from light to dark,
/// based on the gender provided.
List<String> genderToEmoji(Gender gender) {
  const faceLists = [
    ['🧑🏻', '🧑🏼', '🧑🏽', '🧑🏾', '🧑🏿'],
    ['👨🏻', '👨🏼', '👨🏽', '👨🏾', '👨🏿'],
    ['👩🏻', '👩🏼', '👩🏽', '👩🏾', '👩🏿'],
  ];
  switch (gender) {
    case Gender.male:
      return faceLists[1];
    case Gender.female:
      return faceLists[2];
    case Gender.transgender:
    case Gender.nonBinary:
      return faceLists[0];
  }
}

/// Converts gender preferences into a single gender. No preference implies
/// non-binary, as does a preference of both a male and female type gender.
Gender genderForPreferredGenders(Set<Gender> genders) {
  final containsMale = genders.contains(Gender.male);
  final containsFemale = genders.contains(Gender.female);
  final containsOther = genders.contains(Gender.nonBinary) ||
      genders.contains(Gender.transgender);
  if (containsOther) {
    return Gender.nonBinary;
  } else if (containsMale && !containsFemale) {
    return Gender.male;
  } else if (containsFemale && !containsMale) {
    return Gender.female;
  } else {
    return Gender.nonBinary;
  }
}

String genderToLabel(Gender gender) {
  switch (gender) {
    case Gender.male:
      return 'Male';
    case Gender.female:
      return 'Female';
    case Gender.nonBinary:
      return 'Non-Binary';
    case Gender.transgender:
      return 'Transgender';
  }
}
