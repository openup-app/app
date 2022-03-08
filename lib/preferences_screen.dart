import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:get_it/get_it.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/lobby/lobby_api.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/api/users/preferences.dart';
import 'package:openup/util/emoji.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/matching_users_online.dart';
import 'package:openup/widgets/preference.dart';
import 'package:openup/widgets/theming.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';

part 'preferences_screen.freezed.dart';

class PreferencesScreen extends ConsumerStatefulWidget {
  final Preferences initialPreferences;
  final String title;
  final Widget image;
  final Purpose purpose;

  const PreferencesScreen({
    Key? key,
    required this.initialPreferences,
    required this.title,
    required this.image,
    required this.purpose,
  }) : super(key: key);

  @override
  _PreferencesScreenState createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends ConsumerState<PreferencesScreen> {
  late Preferences _preferences;

  bool _uploading = false;
  int? _expandedSection;

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
      child: Stack(
        children: [
          Positioned(
            left: 16,
            top: MediaQuery.of(context).padding.top + 24,
            child: const CloseButton(
              color: Colors.black,
            ),
          ),
          Column(
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
                            onChanged: (profile) =>
                                setState(() => _preferences = profile),
                            expandedSection: _expandedSection,
                            onExpansion: (index) =>
                                setState(() => _expandedSection = index),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                widget.image,
                Button(
                  onPressed: () => _submit(context, ref),
                  child: Container(
                    height: 100,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color.fromRGBO(0xFF, 0xA1, 0xA1, 1.0),
                          Color.fromRGBO(0xFF, 0xCC, 0xCC, 1.0),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                    child: _uploading
                        ? const CircularProgressIndicator()
                        : const Text('Complete'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _submit(BuildContext context, WidgetRef ref) async {
    if (_preferences == widget.initialPreferences) {
      return Navigator.of(context).pop();
    }

    setState(() => _uploading = true);
    final userState = ref.read(userProvider);
    final api = GetIt.instance.get<Api>();
    final preferences = _preferences;
    final friends = widget.purpose == Purpose.friends;
    final result = friends
        ? await api.updateFriendsPreferences(userState.uid, preferences)
        : await api.updateDatingPreferences(userState.uid, preferences);
    if (!mounted) {
      return;
    }
    setState(() => _uploading = false);
    result.fold(
      (l) => displayError(context, l),
      (r) {
        final notifier = ref.read(userProvider.notifier);
        if (friends) {
          notifier.friendsPreferences(preferences);
        } else {
          notifier.datingPreferences(preferences);
        }
        Navigator.of(context).pop();
      },
    );
  }
}

class PreferencesSelection extends StatelessWidget {
  final Preferences preferences;
  final void Function(Preferences preferences) onChanged;
  final int? expandedSection;
  final void Function(int index) onExpansion;

  const PreferencesSelection({
    Key? key,
    required this.preferences,
    required this.onChanged,
    required this.expandedSection,
    required this.onExpansion(int index),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final genderLabelElements = [...preferences.gender];
    genderLabelElements.sort((a, b) => a.index.compareTo(b.index));
    final genderLabel = genderLabelElements.isEmpty
        ? 'Any'
        : genderLabelElements.map(genderToLabel).join(', ');

    final skinColorLabel = preferences.skinColor.isEmpty
        ? 'Any'
        : preferences.skinColor
            .map((s) => genderToEmoji(
                genderForPreferredGenders(preferences.gender))[s.index])
            .join(' ');

    final ethnicityList = [
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
    final ethnicityLabelElements = [...preferences.ethnicity];
    ethnicityLabelElements.sort(
        (a, b) => ethnicityList.indexOf(a).compareTo(ethnicityList.indexOf(b)));
    final ethnicityLabel = ethnicityLabelElements.isEmpty
        ? 'Any'
        : ethnicityLabelElements.join(', ');
    return SfRangeSliderTheme(
      data: SfRangeSliderThemeData(
        thumbRadius: 16,
      ),
      child: Column(
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
            expanded: expandedSection == 0,
            onPressed: () => onExpansion(0),
            gradient:
                PreferencesScreenTheme.of(context).expansionButtonGradient,
            children: [
              for (final gender in Gender.values)
                PreferencesSetTile<Gender>(
                  title: Text(genderToLabel(gender)),
                  value: gender,
                  set: preferences.gender,
                  onChanged: (value) {
                    onChanged(preferences.copyWith(gender: value));
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
            expanded: expandedSection == 1,
            onPressed: () => onExpansion(1),
            gradient:
                PreferencesScreenTheme.of(context).expansionButtonGradient,
            children: [
              for (var skinColor in SkinColor.values)
                PreferencesSetTile<SkinColor>(
                  title: Text(genderToEmoji(
                          genderForPreferredGenders(preferences.gender))[
                      SkinColor.values.indexOf(skinColor)]),
                  value: skinColor,
                  set: preferences.skinColor,
                  onChanged: (value) {
                    onChanged(preferences.copyWith(skinColor: value));
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
              preferences.weight.min.toDouble(),
              preferences.weight.max.toDouble(),
            ),
            min: 25,
            max: 400,
            stepSize: 5,
            interval: 5,
            startThumbIcon: Center(
              child: Text(
                preferences.weight.min.toString(),
                textAlign: TextAlign.center,
                style: Theming.of(context)
                    .text
                    .body
                    .copyWith(fontSize: 15, fontWeight: FontWeight.w300),
              ),
            ),
            endThumbIcon: Center(
              child: Text(
                preferences.weight.max.toString(),
                textAlign: TextAlign.center,
                style: Theming.of(context)
                    .text
                    .body
                    .copyWith(fontSize: 15, fontWeight: FontWeight.w300),
              ),
            ),
            onChanged: (v) {
              if (v.start < v.end - 50) {
                onChanged(preferences.copyWith(
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
              preferences.height.min.toDouble(),
              preferences.height.max.toDouble(),
            ),
            min: 24,
            max: 120,
            startThumbIcon: Center(
              child: Text(
                _inchToFtIn(preferences.height.min),
                textAlign: TextAlign.center,
                maxLines: 1,
                style: Theming.of(context)
                    .text
                    .body
                    .copyWith(fontSize: 15, fontWeight: FontWeight.w300),
              ),
            ),
            endThumbIcon: Center(
              child: Text(
                _inchToFtIn(preferences.height.max),
                textAlign: TextAlign.center,
                maxLines: 1,
                style: Theming.of(context)
                    .text
                    .body
                    .copyWith(fontSize: 15, fontWeight: FontWeight.w300),
              ),
            ),
            onChanged: (v) {
              if (v.start < v.end - 14) {
                onChanged(preferences.copyWith(
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
            expanded: expandedSection == 3,
            onPressed: () => onExpansion(3),
            gradient:
                PreferencesScreenTheme.of(context).expansionButtonGradient,
            children: [
              for (var ethnicity in ethnicityList)
                PreferencesSetTile<String>(
                  title: Text(ethnicity),
                  value: ethnicity,
                  set: preferences.ethnicity,
                  onChanged: (value) {
                    onChanged(preferences.copyWith(ethnicity: value));
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
