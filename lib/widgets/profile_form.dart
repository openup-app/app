import 'package:flutter/material.dart';
import 'package:openup/api/users/preferences.dart';
import 'package:openup/api/users/profile.dart';
import 'package:openup/util/emoji.dart';
import 'package:openup/widgets/preference.dart';
import 'package:openup/widgets/theming.dart';
import 'package:syncfusion_flutter_core/theme.dart';

const _religions = [
  'Bahaist',
  'Buddhist',
  'Christian',
  'Hindu',
  'Jewish',
  'Jucheist',
  'Muslim',
  'Non-religious',
  'Shintoist',
  'Sikh',
  'Taoist',
  'Other',
];

const _interests = [
  'Building',
  'Collecting',
  'Computer Science',
  'Cooking',
  'Crafts',
  'Dancing',
  'Drawing',
  'Film/Video',
  'Food',
  'Games',
  'Language',
  'Music',
  'Nature',
  'Photography',
  'Puzzles',
  'Reading',
  'Science',
  'Sport',
  'Travel',
  'Writing',
  'Other',
];

const _ethnicities = [
  'White',
  'Black',
  'Indian',
  'Punjabi',
  'Hindu',
  'Chinese',
  'Japanese',
  'Korean',
  'Hispanic',
  'Native American',
  'Asian',
];

class AttributesForm extends StatelessWidget {
  final Attributes2 attributes;
  final void Function(Attributes2 profile) onChanged;
  final int? expandedSection;
  final void Function(int index) onExpansion;

  const AttributesForm({
    Key? key,
    required this.attributes,
    required this.onChanged,
    required this.expandedSection,
    required this.onExpansion,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SfSliderTheme(
      data: SfSliderThemeData(
        thumbRadius: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'I identify as a ...',
            style: Theming.of(context).text.body.copyWith(
                  color: const Color.fromRGBO(0x8E, 0x8E, 0x8E, 1.0),
                  fontWeight: FontWeight.w400,
                  fontSize: 18,
                ),
          ),
          PreferencesExpansionSection(
            label: genderToLabel(attributes.gender),
            expanded: expandedSection == 0,
            onPressed: () => onExpansion(0),
            children: [
              for (final gender in Gender.values)
                PreferencesRadioTile(
                  title: Text(genderToLabel(gender)),
                  value: gender,
                  groupValue: attributes.gender,
                  onSelected: () {
                    onChanged(attributes.copyWith(gender: gender));
                  },
                ),
            ],
          ),
          Text(
            'What do I do ...',
            style: Theming.of(context).text.body.copyWith(
                  color: const Color.fromRGBO(0x8E, 0x8E, 0x8E, 1.0),
                  fontWeight: FontWeight.w400,
                  fontSize: 18,
                ),
          ),
          PreferencesExpansionSection(
            label: attributes.interests,
            expanded: expandedSection == 1,
            onPressed: () => onExpansion(1),
            children: [
              for (final interest in _interests)
                PreferencesRadioTile(
                  title: Text(interest),
                  value: interest,
                  groupValue: attributes.interests,
                  onSelected: () {
                    onChanged(attributes.copyWith(interests: interest));
                  },
                ),
            ],
          ),
          Text(
            'My ethnicity ...',
            style: Theming.of(context).text.body.copyWith(
                  color: const Color.fromRGBO(0x8E, 0x8E, 0x8E, 1.0),
                  fontWeight: FontWeight.w400,
                  fontSize: 18,
                ),
          ),
          PreferencesExpansionSection(
            label: attributes.ethnicity,
            expanded: expandedSection == 2,
            onPressed: () => onExpansion(2),
            children: [
              for (var ethnicity in _ethnicities)
                PreferencesRadioTile(
                  title: Text(ethnicity),
                  value: ethnicity,
                  groupValue: attributes.ethnicity,
                  onSelected: () {
                    onChanged(attributes.copyWith(ethnicity: ethnicity));
                  },
                ),
            ],
          ),
          Text(
            'My religion   ...',
            style: Theming.of(context).text.body.copyWith(
                  color: const Color.fromRGBO(0x8E, 0x8E, 0x8E, 1.0),
                  fontWeight: FontWeight.w400,
                  fontSize: 18,
                ),
          ),
          PreferencesExpansionSection(
            label: attributes.religion,
            expanded: expandedSection == 3,
            onPressed: () => onExpansion(3),
            children: [
              for (final religion in _religions)
                PreferencesRadioTile(
                  title: Text(religion),
                  value: religion,
                  groupValue: attributes.religion,
                  onSelected: () {
                    onChanged(attributes.copyWith(religion: religion));
                  },
                ),
            ],
          ),
          const SizedBox(height: 150),
        ],
      ),
    );
  }
}

String _inchToFtIn(int inches) {
  return '${inches ~/ 12}\'${((inches % 12))}"';
}
