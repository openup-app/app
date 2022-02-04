import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:openup/api/users/preferences.dart';
import 'package:openup/api/users/users_api.dart';
import 'package:openup/util/emoji.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/matching_users_online.dart';
import 'package:openup/widgets/preference.dart';
import 'package:openup/widgets/theming.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';

part 'preferences_screen.freezed.dart';

class PreferencesScreen extends ConsumerStatefulWidget {
  final Preferences initialPreferences;
  final String title;
  final Widget image;
  final Future<void> Function(
      UsersApi usersApi, String uid, Preferences preferences) updatePreferences;

  const PreferencesScreen({
    Key? key,
    required this.initialPreferences,
    required this.title,
    required this.image,
    required this.updatePreferences,
  }) : super(key: key);

  @override
  _PreferencesScreenState createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends ConsumerState<PreferencesScreen> {
  late Preferences _preferences;

  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _preferences = widget.initialPreferences;
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white,
            PreferencesScreenTheme.of(context).backgroundGradientBottom,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: MediaQuery.of(context).padding.top + 32,
          ),
          Align(
            alignment: Alignment.center,
            child: Text(
              widget.title,
              style: Theming.of(context).text.body.copyWith(
                    color: PreferencesScreenTheme.of(context).titleColor,
                    fontWeight: FontWeight.w400,
                    fontSize: 30,
                  ),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.only(right: 0.0),
              child: MatchingUsersOnline(preferences: _preferences),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.center,
            child: Text(
              'Who are you interested in talking to?\nYou can change these settings at any time',
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
                      child: PreferencesSelection(
                        preferences: _preferences,
                        onChanged: (profile) {
                          setState(() => _preferences = profile);
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SignificantButton(
                onPressed: () async {
                  if (_preferences == widget.initialPreferences) {
                    return Navigator.of(context).pop();
                  }
                  setState(() => _uploading = true);
                  final user = FirebaseAuth.instance.currentUser;
                  final uid = user?.uid;
                  if (uid != null) {
                    final usersApi = ref.read(usersApiProvider);
                    await widget.updatePreferences(usersApi, uid, _preferences);
                    if (mounted) {
                      setState(() => _uploading = false);
                      Navigator.of(context).pop();
                    }
                  }
                },
                gradient: PreferencesScreenTheme.of(context).doneButtonGradient,
                child: _uploading
                    ? const CircularProgressIndicator()
                    : const Text('Complete'),
              ),
              widget.image,
            ],
          ),
        ],
      ),
    );
  }
}

class PreferencesSelection extends StatefulWidget {
  final Preferences preferences;
  final void Function(Preferences preferences) onChanged;

  const PreferencesSelection({
    Key? key,
    required this.preferences,
    required this.onChanged,
  }) : super(key: key);

  @override
  _PreferencesSelectionState createState() => _PreferencesSelectionState();
}

class _PreferencesSelectionState extends State<PreferencesSelection> {
  int? _expandedSection;

  @override
  Widget build(BuildContext context) {
    final genderLabelElements = [...widget.preferences.gender];
    genderLabelElements.sort((a, b) => a.index.compareTo(b.index));
    final genderLabel = genderLabelElements.isEmpty
        ? 'Any'
        : genderLabelElements.map(genderToLabel).join(', ');

    final skinColorLabel = widget.preferences.skinColor.isEmpty
        ? 'Any'
        : widget.preferences.skinColor
            .map((s) => genderToEmoji(
                genderForPreferredGenders(widget.preferences.gender))[s.index])
            .join(' ');

    final ethnicityList = [
      'Black',
      'White',
      'Indian',
      'Gujarati',
      'Armenian',
      'Chinese',
      'Japanese',
      'Lebanese',
      'Other',
    ];
    final ethnicityLabelElements = [...widget.preferences.ethnicity];
    ethnicityLabelElements.sort(
        (a, b) => ethnicityList.indexOf(a).compareTo(ethnicityList.indexOf(b)));
    final ethnicityLabel = ethnicityLabelElements.isEmpty
        ? 'Any'
        : ethnicityLabelElements.join(', ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Genders I am interested in ...',
          style: Theming.of(context).text.body.copyWith(
                color: const Color.fromRGBO(0x8E, 0x8E, 0x8E, 1.0),
                fontWeight: FontWeight.w400,
                fontSize: 18,
              ),
        ),
        PreferencesExpansionSection(
          label: genderLabel,
          expanded: _expandedSection == 0,
          onPressed: () => setState(() => _expandedSection = 0),
          gradient: PreferencesScreenTheme.of(context).expansionButtonGradient,
          children: [
            for (final gender in Gender.values)
              PreferencesSetTile<Gender>(
                title: Text(genderToLabel(gender)),
                value: gender,
                set: widget.preferences.gender,
                onChanged: (value) {
                  widget.onChanged(widget.preferences.copyWith(gender: value));
                },
              ),
          ],
        ),
        Text(
          'Skin color ...',
          style: Theming.of(context).text.body.copyWith(
                color: const Color.fromRGBO(0x8E, 0x8E, 0x8E, 1.0),
                fontWeight: FontWeight.w400,
                fontSize: 18,
              ),
        ),
        PreferencesExpansionSection(
          label: skinColorLabel,
          expanded: _expandedSection == 1,
          onPressed: () => setState(() => _expandedSection = 1),
          gradient: PreferencesScreenTheme.of(context).expansionButtonGradient,
          children: [
            for (var skinColor in SkinColor.values)
              PreferencesSetTile<SkinColor>(
                title: Text(genderToEmoji(
                        genderForPreferredGenders(widget.preferences.gender))[
                    SkinColor.values.indexOf(skinColor)]),
                value: skinColor,
                set: widget.preferences.skinColor,
                onChanged: (value) {
                  widget
                      .onChanged(widget.preferences.copyWith(skinColor: value));
                },
              ),
          ],
        ),
        Text(
          'Weight ...',
          style: Theming.of(context).text.body.copyWith(
                color: const Color.fromRGBO(0x8E, 0x8E, 0x8E, 1.0),
                fontWeight: FontWeight.w400,
                fontSize: 18,
              ),
        ),
        SfRangeSlider(
          values: SfRangeValues(
            widget.preferences.weight.min.toDouble(),
            widget.preferences.weight.max.toDouble(),
          ),
          min: 25,
          max: 400,
          stepSize: 25,
          interval: 25,
          showDividers: true,
          startThumbIcon: Center(
            child: Text(
              widget.preferences.weight.min.toString(),
              textAlign: TextAlign.center,
              style: Theming.of(context)
                  .text
                  .body
                  .copyWith(fontSize: 11, fontWeight: FontWeight.w300),
            ),
          ),
          endThumbIcon: Center(
            child: Text(
              widget.preferences.weight.max.toString(),
              textAlign: TextAlign.center,
              style: Theming.of(context)
                  .text
                  .body
                  .copyWith(fontSize: 11, fontWeight: FontWeight.w300),
            ),
          ),
          onChanged: (v) {
            if (v.start < v.end - 25) {
              widget.onChanged(widget.preferences.copyWith(
                  weight: Range(min: v.start.toInt(), max: v.end.toInt())));
            }
          },
        ),
        Text(
          'Height ...',
          style: Theming.of(context).text.body.copyWith(
                color: const Color.fromRGBO(0x8E, 0x8E, 0x8E, 1.0),
                fontWeight: FontWeight.w400,
                fontSize: 18,
              ),
        ),
        SfRangeSlider(
          values: SfRangeValues(
            widget.preferences.height.min.toDouble(),
            widget.preferences.height.max.toDouble(),
          ),
          min: 24,
          max: 120,
          stepSize: 6,
          interval: 6,
          showDividers: true,
          startThumbIcon: Center(
            child: Text(
              _inchToFtIn(widget.preferences.height.min),
              textAlign: TextAlign.center,
              maxLines: 1,
              style: Theming.of(context)
                  .text
                  .body
                  .copyWith(fontSize: 11, fontWeight: FontWeight.w300),
            ),
          ),
          endThumbIcon: Center(
            child: Text(
              _inchToFtIn(widget.preferences.height.max),
              textAlign: TextAlign.center,
              maxLines: 1,
              style: Theming.of(context).text.body.copyWith(
                  fontSize: widget.preferences.height.max >= 120 ? 9 : 11,
                  fontWeight: FontWeight.w300),
            ),
          ),
          onChanged: (v) {
            if (v.start < v.end - 6) {
              widget.onChanged(widget.preferences.copyWith(
                  height: Range(min: v.start.toInt(), max: v.end.toInt())));
            }
          },
        ),
        Text(
          'Ethnicity ...',
          style: Theming.of(context).text.body.copyWith(
                color: const Color.fromRGBO(0x8E, 0x8E, 0x8E, 1.0),
                fontWeight: FontWeight.w400,
                fontSize: 18,
              ),
        ),
        PreferencesExpansionSection(
          label: ethnicityLabel,
          expanded: _expandedSection == 3,
          onPressed: () => setState(() => _expandedSection = 3),
          gradient: PreferencesScreenTheme.of(context).expansionButtonGradient,
          children: [
            for (var ethnicity in ethnicityList)
              PreferencesSetTile<String>(
                title: Text(ethnicity),
                value: ethnicity,
                set: widget.preferences.ethnicity,
                onChanged: (value) {
                  widget
                      .onChanged(widget.preferences.copyWith(ethnicity: value));
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

class PreferencesScreenTheme extends InheritedWidget {
  final PreferencesScreenThemeData themeData;

  const PreferencesScreenTheme({
    Key? key,
    required Widget child,
    required this.themeData,
  }) : super(key: key, child: child);

  static PreferencesScreenThemeData of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<PreferencesScreenTheme>()!
        .themeData;
  }

  @override
  bool updateShouldNotify(PreferencesScreenTheme oldWidget) =>
      oldWidget.themeData != themeData;
}

@freezed
class PreferencesScreenThemeData with _$PreferencesScreenThemeData {
  const factory PreferencesScreenThemeData({
    required Color backgroundGradientBottom,
    required Color titleColor,
    required Gradient expansionButtonGradient,
    required Gradient doneButtonGradient,
    required Color backArrowColor,
    required Color profileButtonColor,
  }) = _PreferencesScreenThemeData;
}
