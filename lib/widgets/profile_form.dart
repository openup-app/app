import 'package:flutter/material.dart';
import 'package:openup/api/users/preferences.dart';
import 'package:openup/api/users/profile.dart';
import 'package:openup/util/emoji.dart';
import 'package:openup/widgets/preference.dart';
import 'package:openup/widgets/theming.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';
import 'package:syncfusion_flutter_core/theme.dart';

class PrivateProfileForm extends StatelessWidget {
  final PrivateProfile profile;
  final void Function(PrivateProfile profile) onChanged;
  final int? expandedSection;
  final void Function(int index) onExpansion;

  const PrivateProfileForm({
    Key? key,
    required this.profile,
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
            label: genderToLabel(profile.gender),
            expanded: expandedSection == 0,
            onPressed: () => onExpansion(0),
            children: [
              for (final gender in Gender.values)
                PreferencesRadioTile(
                  title: Text(genderToLabel(gender)),
                  value: gender,
                  groupValue: profile.gender,
                  onSelected: () {
                    onChanged(profile.copyWith(gender: gender));
                  },
                ),
            ],
          ),
          Text(
            'My skin color ...',
            style: Theming.of(context).text.body.copyWith(
                  color: const Color.fromRGBO(0x8E, 0x8E, 0x8E, 1.0),
                  fontWeight: FontWeight.w400,
                  fontSize: 18,
                ),
          ),
          PreferencesExpansionSection(
            label: genderToEmoji(profile.gender)[profile.skinColor.index],
            expanded: expandedSection == 1,
            onPressed: () => onExpansion(1),
            children: [
              for (var skinColor in SkinColor.values)
                PreferencesRadioTile(
                  title: Text(genderToEmoji(
                      profile.gender)[SkinColor.values.indexOf(skinColor)]),
                  value: skinColor,
                  groupValue: profile.skinColor,
                  onSelected: () {
                    onChanged(profile.copyWith(skinColor: skinColor));
                  },
                ),
            ],
          ),
          Text(
            'My weight ...',
            style: Theming.of(context).text.body.copyWith(
                  color: const Color.fromRGBO(0x8E, 0x8E, 0x8E, 1.0),
                  fontWeight: FontWeight.w400,
                  fontSize: 18,
                ),
          ),
          SfSlider(
            value: profile.weight,
            min: 25,
            max: 400,
            stepSize: 5,
            interval: 5,
            thumbIcon: Center(
              child: Text(
                profile.weight.toString(),
                textAlign: TextAlign.center,
                style: Theming.of(context)
                    .text
                    .body
                    .copyWith(fontSize: 15, fontWeight: FontWeight.w300),
              ),
            ),
            onChanged: (v) {
              onChanged(profile.copyWith(weight: v.toInt()));
            },
          ),
          Text(
            'My height ...',
            style: Theming.of(context).text.body.copyWith(
                  color: const Color.fromRGBO(0x8E, 0x8E, 0x8E, 1.0),
                  fontWeight: FontWeight.w400,
                  fontSize: 18,
                ),
          ),
          SfSlider(
            value: profile.height,
            min: 24,
            max: 120,
            thumbIcon: Center(
              child: Text(
                _inchToFtIn(profile.height),
                textAlign: TextAlign.center,
                maxLines: 1,
                style: Theming.of(context)
                    .text
                    .body
                    .copyWith(fontSize: 15, fontWeight: FontWeight.w300),
              ),
            ),
            onChanged: (v) {
              onChanged(profile.copyWith(height: v.toInt()));
            },
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
            label: profile.ethnicity,
            expanded: expandedSection == 3,
            onPressed: () => onExpansion(3),
            children: [
              for (var ethnicity in [
                'Black',
                'White',
                'Indian',
                'Gujarati',
                'Armenian',
                'Chinese',
                'Japanese',
                'Lebanese',
                'Other',
              ])
                PreferencesRadioTile(
                  title: Text(ethnicity),
                  value: ethnicity,
                  groupValue: profile.ethnicity,
                  onSelected: () {
                    onChanged(profile.copyWith(ethnicity: ethnicity));
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
