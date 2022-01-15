import 'package:flutter/material.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/male_female_connection_image.dart';
import 'package:openup/widgets/preference.dart';
import 'package:openup/widgets/slider.dart';
import 'package:openup/widgets/theming.dart';

class SignUpPrivateProfileScreen extends StatefulWidget {
  const SignUpPrivateProfileScreen({Key? key}) : super(key: key);

  @override
  State<SignUpPrivateProfileScreen> createState() =>
      _SignUpPrivateProfileScreenState();
}

class _SignUpPrivateProfileScreenState
    extends State<SignUpPrivateProfileScreen> {
  Gender2 _gender = Gender2.male;
  int _skinColor = 0;
  int _weight = 5;
  int _height = 5;
  String _ethnicity = 'Indian';

  int? _expandedSection;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: MediaQuery.of(context).padding.top + 32,
        ),
        Align(
          alignment: Alignment.center,
          child: Text(
            'Introduce yourself',
            style: Theming.of(context).text.body.copyWith(
                  color: const Color.fromRGBO(0x62, 0xCD, 0xE3, 1.0),
                  fontWeight: FontWeight.w400,
                  fontSize: 30,
                ),
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.center,
          child: Text(
            'Fill out the following information so others can find the real you',
            textAlign: TextAlign.center,
            style: Theming.of(context).text.body.copyWith(
                  color: const Color.fromRGBO(0x99, 0x99, 0x99, 1.0),
                  fontWeight: FontWeight.w400,
                  fontSize: 18,
                ),
          ),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.center,
            child: ListView(
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 300),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'I identify as a ...',
                          style: Theming.of(context).text.body.copyWith(
                                color:
                                    const Color.fromRGBO(0x8E, 0x8E, 0x8E, 1.0),
                                fontWeight: FontWeight.w400,
                                fontSize: 18,
                              ),
                        ),
                        PreferencesExpansionSection(
                          label: 'Male',
                          expanded: _expandedSection == 0,
                          onPressed: () => setState(() => _expandedSection = 0),
                          children: [
                            for (final gender in Gender2.values)
                              PreferencesRadioTile(
                                title: Text(genderToLabel(gender)),
                                value: gender,
                                groupValue: _gender,
                                onSelected: () {
                                  setState(() => _gender = gender);
                                },
                              ),
                          ],
                        ),
                        Text(
                          'My skin color ...',
                          style: Theming.of(context).text.body.copyWith(
                                color:
                                    const Color.fromRGBO(0x8E, 0x8E, 0x8E, 1.0),
                                fontWeight: FontWeight.w400,
                                fontSize: 18,
                              ),
                        ),
                        PreferencesExpansionSection(
                          label: genderToEmoji(_gender)[_skinColor],
                          expanded: _expandedSection == 1,
                          onPressed: () => setState(() => _expandedSection = 1),
                          children: [
                            for (var i = 0; i < 5; i++)
                              PreferencesRadioTile(
                                title: Text(genderToEmoji(_gender)[i]),
                                value: i,
                                groupValue: _skinColor,
                                onSelected: () {
                                  setState(() => _skinColor = i);
                                },
                              ),
                          ],
                        ),
                        Text(
                          'My weight ...',
                          style: Theming.of(context).text.body.copyWith(
                                color:
                                    const Color.fromRGBO(0x8E, 0x8E, 0x8E, 1.0),
                                fontWeight: FontWeight.w400,
                                fontSize: 18,
                              ),
                        ),
                        PreferencesSlider(
                          value: _weight,
                          min: 1,
                          max: 10,
                          onUpdate: (value) {
                            setState(() {
                              _weight = value;
                            });
                          },
                        ),
                        Text(
                          'My height ...',
                          style: Theming.of(context).text.body.copyWith(
                                color:
                                    const Color.fromRGBO(0x8E, 0x8E, 0x8E, 1.0),
                                fontWeight: FontWeight.w400,
                                fontSize: 18,
                              ),
                        ),
                        PreferencesSlider(
                          value: _height,
                          min: 1,
                          max: 10,
                          onUpdate: (value) {
                            setState(() {
                              _height = value;
                            });
                          },
                        ),
                        Text(
                          'My ethnicity ...',
                          style: Theming.of(context).text.body.copyWith(
                                color:
                                    const Color.fromRGBO(0x8E, 0x8E, 0x8E, 1.0),
                                fontWeight: FontWeight.w400,
                                fontSize: 18,
                              ),
                        ),
                        PreferencesExpansionSection(
                          label: _ethnicity,
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
                                groupValue: _ethnicity,
                                onSelected: () {
                                  setState(() => _ethnicity = ethnicity);
                                },
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SignificantButton.pink(
          onPressed: () {
            Navigator.of(context).pushNamed('sign-up-photos');
          },
          child: const Text('Continue'),
        ),
        const SizedBox(height: 32),
        const Hero(
          tag: 'male_female_connection',
          child: SizedBox(
            height: 125,
            child: MaleFemaleConnectionImageApart(),
          ),
        ),
      ],
    );
  }
}
