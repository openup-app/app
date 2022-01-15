import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openup/api/users/preferences.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/theming.dart';

late StateProvider<Preferences> _prefsProvider;
void _initPreferences(Preferences preferences) {
  _prefsProvider = StateProvider<Preferences>((ref) {
    return preferences;
  });
}

class PreferencesList extends ConsumerStatefulWidget {
  final Preferences initialPreferences;
  final void Function(Preferences preferences) onPreferencesChanged;

  const PreferencesList({
    Key? key,
    required this.initialPreferences,
    required this.onPreferencesChanged,
  }) : super(key: key);

  @override
  _PreferencesListState createState() => _PreferencesListState();
}

class _PreferencesListState extends ConsumerState<PreferencesList> {
  @override
  void initState() {
    super.initState();
    _initPreferences(widget.initialPreferences);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      children: [
        Text(
          'I identify as a ...',
          style: Theming.of(context).text.body.copyWith(
                color: const Color.fromRGBO(0x8E, 0x8E, 0x8E, 1.0),
                fontWeight: FontWeight.w400,
                fontSize: 18,
              ),
        ),
        Consumer(
          builder: (context, ref, child) {
            final genders = ref.watch(_prefsProvider.select((p) => p.gender));
            return PreferencesExpansionSection(
              label: 'Gender',
              expanded: false,
              onPressed: () {},
              children: [
                PreferencesSetTile(
                  title: const Text('Male'),
                  value: Gender.male,
                  set: genders,
                  onChanged: _setGender,
                ),
                PreferencesSetTile(
                  title: const Text('Female'),
                  value: Gender.female,
                  set: genders,
                  onChanged: _setGender,
                ),
                PreferencesSetTile(
                  title: const Text('Non-Binary'),
                  value: Gender.nonBinary,
                  set: genders,
                  onChanged: _setGender,
                ),
                PreferencesSetTile(
                  title: const Text('Transgender'),
                  value: Gender.transMale,
                  set: genders,
                  onChanged: _setGender,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  void _setGender(Set<Gender> value) => ref.read(_prefsProvider.state).state =
      ref.read(_prefsProvider).copyWith(gender: value);
}

class PreferencesExpansionSection extends StatefulWidget {
  final String label;
  final bool expanded;
  final VoidCallback onPressed;
  final List<Widget> children;

  const PreferencesExpansionSection({
    Key? key,
    required this.label,
    required this.expanded,
    required this.onPressed,
    required this.children,
  }) : super(key: key);

  @override
  _PreferencesExpansionSectionState createState() =>
      _PreferencesExpansionSectionState();
}

class _PreferencesExpansionSectionState
    extends State<PreferencesExpansionSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant PreferencesExpansionSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expanded != widget.expanded) {
      if (widget.expanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        margin: const EdgeInsets.only(bottom: 19),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(32)),
          color: Colors.pink,
          gradient: const LinearGradient(
            colors: [
              Color.fromRGBO(0x26, 0xC4, 0xE6, 1.0),
              Color.fromRGBO(0x7B, 0xDC, 0xF1, 1.0),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            Theming.of(context).boxShadow,
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!widget.expanded)
              Button(
                onPressed: widget.onPressed,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 6.0,
                    ),
                    child: Text(
                      widget.label,
                      style: Theming.of(context).text.body.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.w400,
                          color: Colors.white),
                    ),
                  ),
                ),
              )
            else
              SizeTransition(
                sizeFactor: _controller,
                child: FadeTransition(
                  opacity: _controller,
                  child: ListView(
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shrinkWrap: true,
                    children: widget.children,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class PreferencesTile extends StatelessWidget {
  final Widget title;
  final bool selected;
  final ValueChanged<bool> onChanged;
  const PreferencesTile({
    Key? key,
    required this.title,
    required this.selected,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Button(
      onPressed: () => onChanged(!selected),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.centerRight,
        child: Row(
          children: [
            DefaultTextStyle(
              style: Theming.of(context).text.subheading.copyWith(
                    fontWeight: FontWeight.normal,
                    color: const Color.fromRGBO(0x80, 0x7E, 0x7E, 1.0),
                  ),
              child: title,
            ),
            const Spacer(),
            if (selected)
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.fromRGBO(0x2E, 0xC7, 0xE7, 1.0),
                      Color.fromRGBO(0x76, 0xDB, 0xF1, 1.0),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.done),
              )
            else
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  border: Border.all(
                    width: 2,
                    color: const Color.fromRGBO(0x2A, 0xC5, 0xE7, 1.0),
                  ),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class PreferencesSetTile<T> extends StatelessWidget {
  final Widget title;
  final T value;
  final Set<T> set;
  final ValueChanged<Set<T>> onChanged;

  const PreferencesSetTile({
    Key? key,
    required this.title,
    required this.value,
    required this.set,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(18)),
        color: Colors.white,
      ),
      child: PreferencesTile(
        title: title,
        selected: set.contains(value),
        onChanged: (selected) {
          final newSet = Set.of(set);
          if (selected) {
            newSet.add(value);
          } else {
            newSet.remove(value);
          }
          onChanged(newSet);
        },
      ),
    );
  }
}

class PreferencesRadioTile<T> extends StatelessWidget {
  final Widget title;
  final T value;
  final T groupValue;
  final VoidCallback onSelected;

  const PreferencesRadioTile({
    Key? key,
    required this.title,
    required this.value,
    required this.groupValue,
    required this.onSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(18)),
        color: Colors.white,
      ),
      child: PreferencesTile(
        title: title,
        selected: value == groupValue,
        onChanged: (selected) {
          if (selected) {
            onSelected();
          }
        },
      ),
    );
  }
}

/// A list of 5 emojis with skin colors ramping from light to dark,
/// based on the gender provided.
List<String> genderToEmoji(Gender2 gender) {
  const faceLists = [
    ['🧑🏻', '🧑🏼', '🧑🏽', '🧑🏾', '🧑🏿'],
    ['👨🏻', '👨🏼', '👨🏽', '👨🏾', '👨🏿'],
    ['👩🏻', '👩🏼', '👩🏽', '👩🏾', '👩🏿'],
  ];
  switch (gender) {
    case Gender2.male:
      return faceLists[1];
    case Gender2.female:
      return faceLists[2];
    case Gender2.transgender:
    case Gender2.nonBinary:
      return faceLists[0];
  }
}

String genderToLabel(Gender2 gender) {
  switch (gender) {
    case Gender2.male:
      return 'Male';
    case Gender2.female:
      return 'Female';
    case Gender2.nonBinary:
      return 'Non-Binary';
    case Gender2.transgender:
      return 'Transgender';
  }
}

enum Gender2 { male, female, nonBinary, transgender }
