import 'package:flutter/material.dart';
import 'package:openup/api/users/preferences.dart';
import 'package:openup/api/users/profile.dart';
import 'package:openup/util/emoji.dart';
import 'package:openup/widgets/preference.dart';
import 'package:openup/widgets/theming.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';

class PrivateProfileForm extends StatefulWidget {
  final PrivateProfile profile;
  final void Function(PrivateProfile profile) onChanged;

  const PrivateProfileForm({
    Key? key,
    required this.profile,
    required this.onChanged,
  }) : super(key: key);

  @override
  _PrivateProfileFormState createState() => _PrivateProfileFormState();
}

class _PrivateProfileFormState extends State<PrivateProfileForm> {
  int? _expandedSection;

  @override
  Widget build(BuildContext context) {
    return Column(
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
          label: 'Male',
          expanded: _expandedSection == 0,
          onPressed: () => setState(() => _expandedSection = 0),
          children: [
            for (final gender in Gender.values)
              PreferencesRadioTile(
                title: Text(genderToLabel(gender)),
                value: gender,
                groupValue: widget.profile.gender,
                onSelected: () {
                  widget.onChanged(widget.profile.copyWith(gender: gender));
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
          label: genderToEmoji(
              widget.profile.gender)[widget.profile.skinColor.index],
          expanded: _expandedSection == 1,
          onPressed: () => setState(() => _expandedSection = 1),
          children: [
            for (var skinColor in SkinColor.values)
              PreferencesRadioTile(
                title: Text(genderToEmoji(widget.profile.gender)[
                    SkinColor.values.indexOf(skinColor)]),
                value: skinColor,
                groupValue: widget.profile.skinColor,
                onSelected: () {
                  widget
                      .onChanged(widget.profile.copyWith(skinColor: skinColor));
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
          value: widget.profile.weight,
          min: 0,
          max: 400,
          stepSize: 50,
          interval: 50,
          showDividers: true,
          thumbIcon: Center(
            child: Text(
              widget.profile.weight.toString(),
              textAlign: TextAlign.center,
              style: Theming.of(context)
                  .text
                  .body
                  .copyWith(fontSize: 11, fontWeight: FontWeight.w300),
            ),
          ),
          onChanged: (v) {
            widget.onChanged(widget.profile.copyWith(weight: v.toInt()));
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
          value: widget.profile.height,
          min: 0,
          max: 120,
          stepSize: 6,
          interval: 6,
          showDividers: true,
          thumbIcon: Center(
            child: Text(
              _inchToFtIn(widget.profile.height),
              textAlign: TextAlign.center,
              maxLines: 1,
              style: Theming.of(context).text.body.copyWith(
                  fontSize: widget.profile.height >= 120 ? 9 : 11,
                  fontWeight: FontWeight.w300),
            ),
          ),
          onChanged: (v) {
            widget.onChanged(widget.profile.copyWith(height: v.toInt()));
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
          label: widget.profile.ethnicity,
          expanded: _expandedSection == 3,
          onPressed: () => setState(() => _expandedSection = 3),
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
                groupValue: widget.profile.ethnicity,
                onSelected: () {
                  widget
                      .onChanged(widget.profile.copyWith(ethnicity: ethnicity));
                },
              ),
          ],
        ),
      ],
    );
  }
}

String _inchToFtIn(int inches) {
  return '${inches ~/ 12}\'${((inches % 12))}"';
}
