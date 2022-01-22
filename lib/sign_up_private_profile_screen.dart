import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openup/api/users/preferences.dart';
import 'package:openup/api/users/profile.dart';
import 'package:openup/api/users/users_api.dart';
import 'package:openup/util/emoji.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/male_female_connection_image.dart';
import 'package:openup/widgets/preference.dart';
import 'package:openup/widgets/theming.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';

class SignUpPrivateProfileScreen extends ConsumerStatefulWidget {
  const SignUpPrivateProfileScreen({Key? key}) : super(key: key);

  @override
  _SignUpPrivateProfileScreenState createState() =>
      _SignUpPrivateProfileScreenState();
}

class _SignUpPrivateProfileScreenState
    extends ConsumerState<SignUpPrivateProfileScreen> {
  PrivateProfile _profile = const PrivateProfile(
    gender: Gender.male,
    skinColor: SkinColor.light,
    weight: 5,
    height: 5,
    ethnicity: 'White',
  );

  bool _uploading = false;

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
                    child: PrivateProfileSelection(
                      profile: _profile,
                      onChanged: (profile) {
                        setState(() => _profile = profile);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SignificantButton.pink(
              onPressed: () async {
                setState(() => _uploading = true);
                final user = FirebaseAuth.instance.currentUser;
                final uid = user?.uid;
                if (uid != null) {
                  final usersApi = ref.read(usersApiProvider);
                  await usersApi.updatePrivateProfile(uid, _profile);
                  if (mounted) {
                    setState(() => _uploading = false);
                    Navigator.of(context).pushNamed('sign-up-photos');
                  }
                }
              },
              child: _uploading
                  ? const CircularProgressIndicator()
                  : const Text('Continue'),
            ),
            const MaleFemaleConnectionImageApart(),
          ],
        ),
      ],
    );
  }
}

class PrivateProfileSelection extends StatefulWidget {
  final PrivateProfile profile;
  final void Function(PrivateProfile profile) onChanged;

  const PrivateProfileSelection({
    Key? key,
    required this.profile,
    required this.onChanged,
  }) : super(key: key);

  @override
  _PrivateProfileSelectionState createState() =>
      _PrivateProfileSelectionState();
}

class _PrivateProfileSelectionState extends State<PrivateProfileSelection> {
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
