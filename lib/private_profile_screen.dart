import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openup/api/users/preferences.dart';
import 'package:openup/api/users/profile.dart';
import 'package:openup/api/users/users_api.dart';
import 'package:openup/util/emoji.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/loading_dialog.dart';
import 'package:openup/widgets/theming.dart';

class PrivateProfileScreen extends ConsumerStatefulWidget {
  final PrivateProfile initialProfile;

  const PrivateProfileScreen({
    Key? key,
    required this.initialProfile,
  }) : super(key: key);

  @override
  _PrivateProfileScreenState createState() => _PrivateProfileScreenState();
}

class _PrivateProfileScreenState extends ConsumerState<PrivateProfileScreen> {
  late _ProfileValueNotifier _notifier;

  @override
  void initState() {
    super.initState();
    _notifier = _ProfileValueNotifier(widget.initialProfile);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => _maybeUpdateProfile(context),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Color.fromARGB(0xFF, 0x9E, 0xD5, 0xE2),
            ],
          ),
        ),
        child: Container(
          margin: const EdgeInsets.only(left: 32, right: 32, top: 64),
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                blurRadius: 6,
                spreadRadius: 2,
                color: Theming.of(context).shadow,
              ),
            ],
            color: Colors.white,
          ),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Your details',
                  style: Theming.of(context).text.body.copyWith(
                        color: const Color.fromARGB(0xFF, 0x9A, 0x9A, 0x9A),
                      ),
                ),
              ),
              const SizedBox(height: 16),
              ExpansionSection(
                label: 'Gender',
                children: [
                  _RadioTile(
                    title: const Text('Male'),
                    value: Gender.male,
                    notifier: _notifier,
                    extract: (p) => p.gender,
                    onUpdate: _setGender,
                  ),
                  _RadioTile(
                    title: const Text('Female'),
                    value: Gender.female,
                    notifier: _notifier,
                    extract: (p) => p.gender,
                    onUpdate: _setGender,
                  ),
                  _RadioTile(
                    title: const Text('Trans Male'),
                    value: Gender.transMale,
                    notifier: _notifier,
                    extract: (p) => p.gender,
                    onUpdate: _setGender,
                  ),
                  _RadioTile(
                    title: const Text('Trans Female'),
                    value: Gender.transFemale,
                    notifier: _notifier,
                    extract: (p) => p.gender,
                    onUpdate: _setGender,
                  ),
                  _RadioTile(
                    title: const Text('Non Binary'),
                    value: Gender.nonBinary,
                    notifier: _notifier,
                    extract: (p) => p.gender,
                    onUpdate: _setGender,
                  ),
                ],
              ),
              ExpansionSection(
                label: 'Religion',
                children: [
                  _RadioTile(
                    title: const Text('Islam'),
                    value: 'Islam',
                    notifier: _notifier,
                    extract: (p) => p.religion,
                    onUpdate: _setReligion,
                  ),
                  _RadioTile(
                    title: const Text('Hinduism'),
                    value: 'Hinduism',
                    notifier: _notifier,
                    extract: (p) => p.religion,
                    onUpdate: _setReligion,
                  ),
                  _RadioTile(
                    title: const Text('Judaism'),
                    value: 'Judaism',
                    notifier: _notifier,
                    extract: (p) => p.religion,
                    onUpdate: _setReligion,
                  ),
                  _RadioTile(
                    title: const Text('Sikhism'),
                    value: 'Sikhism',
                    notifier: _notifier,
                    extract: (p) => p.religion,
                    onUpdate: _setReligion,
                  ),
                  _RadioTile(
                    title: const Text('Buddhism'),
                    value: 'Buddhism',
                    notifier: _notifier,
                    extract: (p) => p.religion,
                    onUpdate: _setReligion,
                  ),
                ],
              ),
              ExpansionSection(
                label: 'Education level',
                children: [
                  _RadioTile(
                    title: const Text('High School'),
                    value: Education.highSchool,
                    notifier: _notifier,
                    extract: (p) => p.education,
                    onUpdate: _setEducation,
                  ),
                  _RadioTile(
                    title: const Text('Associates Degree'),
                    value: Education.associatesDegree,
                    notifier: _notifier,
                    extract: (p) => p.education,
                    onUpdate: _setEducation,
                  ),
                  _RadioTile(
                    title: const Text('Bachelors Degree'),
                    value: Education.bachelorsDegree,
                    notifier: _notifier,
                    extract: (p) => p.education,
                    onUpdate: _setEducation,
                  ),
                  _RadioTile(
                    title: const Text('Masters Degree'),
                    value: Education.mastersDegree,
                    notifier: _notifier,
                    extract: (p) => p.education,
                    onUpdate: _setEducation,
                  ),
                  _RadioTile(
                    title: const Text('No Schooling'),
                    value: Education.noSchooling,
                    notifier: _notifier,
                    extract: (p) => p.education,
                    onUpdate: _setEducation,
                  ),
                ],
              ),
              ExpansionSection(
                label: 'Community',
                children: [
                  _SelectableTile(
                    title: const Text('Punjabi'),
                    value: 'Punjabi',
                    notifier: _notifier,
                    extract: (p) => p.community,
                    onUpdate: _setCommunity,
                  ),
                  _SelectableTile(
                    title: const Text('Black'),
                    value: 'Black',
                    notifier: _notifier,
                    extract: (p) => p.community,
                    onUpdate: _setCommunity,
                  ),
                  _SelectableTile(
                    title: const Text('White'),
                    value: 'White',
                    notifier: _notifier,
                    extract: (p) => p.community,
                    onUpdate: _setCommunity,
                  ),
                  _SelectableTile(
                    title: const Text('Indian'),
                    value: 'Indian',
                    notifier: _notifier,
                    extract: (p) => p.community,
                    onUpdate: _setCommunity,
                  ),
                  _SelectableTile(
                    title: const Text('Gujarati'),
                    value: 'Gujarati',
                    notifier: _notifier,
                    extract: (p) => p.community,
                    onUpdate: _setCommunity,
                  ),
                  _SelectableTile(
                    title: const Text('Armenian'),
                    value: 'Armenian',
                    notifier: _notifier,
                    extract: (p) => p.community,
                    onUpdate: _setCommunity,
                  ),
                  _SelectableTile(
                    title: const Text('Chinese'),
                    value: 'Chinese',
                    notifier: _notifier,
                    extract: (p) => p.community,
                    onUpdate: _setCommunity,
                  ),
                  _SelectableTile(
                    title: const Text('Japanese'),
                    value: 'Japanese',
                    notifier: _notifier,
                    extract: (p) => p.community,
                    onUpdate: _setCommunity,
                  ),
                  _SelectableTile(
                    title: const Text('Lebanese'),
                    value: 'Lebanese',
                    notifier: _notifier,
                    extract: (p) => p.community,
                    onUpdate: _setCommunity,
                  ),
                  _SelectableTile(
                    title: const Text('African'),
                    value: 'African',
                    notifier: _notifier,
                    extract: (p) => p.community,
                    onUpdate: _setCommunity,
                  ),
                ],
              ),
              ExpansionSection(
                label: 'Languages',
                children: [
                  _SelectableTile(
                    title: const Text('Punjabi'),
                    value: 'Punjabi',
                    notifier: _notifier,
                    extract: (p) => p.language,
                    onUpdate: _setLanguage,
                  ),
                  _SelectableTile(
                    title: const Text('Indian'),
                    value: 'Indian',
                    notifier: _notifier,
                    extract: (p) => p.language,
                    onUpdate: _setLanguage,
                  ),
                  _SelectableTile(
                    title: const Text('Gujarati'),
                    value: 'Gujarati',
                    notifier: _notifier,
                    extract: (p) => p.language,
                    onUpdate: _setLanguage,
                  ),
                  _SelectableTile(
                    title: const Text('Armenian'),
                    value: 'Armenian',
                    notifier: _notifier,
                    extract: (p) => p.language,
                    onUpdate: _setLanguage,
                  ),
                  _SelectableTile(
                    title: const Text('Chinese'),
                    value: 'Chinese',
                    notifier: _notifier,
                    extract: (p) => p.language,
                    onUpdate: _setLanguage,
                  ),
                  _SelectableTile(
                    title: const Text('Japanese'),
                    value: 'Japanese',
                    notifier: _notifier,
                    extract: (p) => p.language,
                    onUpdate: _setLanguage,
                  ),
                  _SelectableTile(
                    title: const Text('Lebanese'),
                    value: 'Lebanese',
                    notifier: _notifier,
                    extract: (p) => p.language,
                    onUpdate: _setLanguage,
                  ),
                  _SelectableTile(
                    title: const Text('African'),
                    value: 'African',
                    notifier: _notifier,
                    extract: (p) => p.language,
                    onUpdate: _setLanguage,
                  ),
                ],
              ),
              ValueListenableBuilder<PrivateProfile>(
                valueListenable: _notifier,
                builder: (context, profile, child) {
                  return ExpansionSection(
                    label: 'Skin Color',
                    children: [
                      for (int i = 0; i < SkinColor.values.length; i++)
                        _RadioTile<SkinColor>(
                          title: Text(emojiForGender(profile.gender)[i]),
                          value: SkinColor.values[i],
                          notifier: _notifier,
                          extract: (p) => p.skinColor,
                          onUpdate: _setSkinColor,
                        ),
                    ],
                  );
                },
              ),
              ExpansionSection(
                label: 'Weight',
                children: [
                  ValueListenableBuilder<PrivateProfile>(
                    valueListenable: _notifier,
                    builder: (context, value, child) {
                      return _Slider(
                        value: value.weight,
                        min: 30,
                        max: 200,
                        onUpdate: (weight) {
                          _notifier.value = _notifier.value.copyWith(
                            weight: weight,
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
              ExpansionSection(
                label: 'Height',
                children: [
                  ValueListenableBuilder<PrivateProfile>(
                    valueListenable: _notifier,
                    builder: (context, value, child) {
                      return _Slider(
                        value: value.height,
                        min: 50,
                        max: 250,
                        onUpdate: (height) {
                          _notifier.value = _notifier.value.copyWith(
                            height: height,
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
              ExpansionSection(
                label: 'Job Occupation',
                children: [
                  _RadioTile(
                    title: const Text('Accountant'),
                    value: 'Accountant',
                    notifier: _notifier,
                    extract: (p) => p.occupation,
                    onUpdate: _setOccupation,
                  ),
                  _RadioTile(
                    title: const Text('Entrepreneur'),
                    value: 'Entrepreneur',
                    notifier: _notifier,
                    extract: (p) => p.occupation,
                    onUpdate: _setOccupation,
                  ),
                  _RadioTile(
                    title: const Text('Oil Man'),
                    value: 'Oil Man',
                    notifier: _notifier,
                    extract: (p) => p.occupation,
                    onUpdate: _setOccupation,
                  ),
                  _RadioTile(
                    title: const Text('Welder'),
                    value: 'Welder',
                    notifier: _notifier,
                    extract: (p) => p.occupation,
                    onUpdate: _setOccupation,
                  ),
                  _RadioTile(
                    title: const Text('Data Scientist'),
                    value: 'Data Scientist',
                    notifier: _notifier,
                    extract: (p) => p.occupation,
                    onUpdate: _setOccupation,
                  ),
                ],
              ),
              ExpansionSection(
                label: 'Hair Color',
                children: [
                  _RadioTile(
                    title: const Text('Black'),
                    value: HairColor.black,
                    notifier: _notifier,
                    extract: (p) => p.hairColor,
                    onUpdate: _setHairColor,
                  ),
                  _RadioTile(
                    title: const Text('Blonde'),
                    value: HairColor.blonde,
                    notifier: _notifier,
                    extract: (p) => p.hairColor,
                    onUpdate: _setHairColor,
                  ),
                  _RadioTile(
                    title: const Text('Brunette'),
                    value: HairColor.brunette,
                    notifier: _notifier,
                    extract: (p) => p.hairColor,
                    onUpdate: _setHairColor,
                  ),
                  _RadioTile(
                    title: const Text('Brown'),
                    value: HairColor.brown,
                    notifier: _notifier,
                    extract: (p) => p.hairColor,
                    onUpdate: _setHairColor,
                  ),
                  _RadioTile(
                    title: const Text('Red'),
                    value: HairColor.red,
                    notifier: _notifier,
                    extract: (p) => p.hairColor,
                    onUpdate: _setHairColor,
                  ),
                  _RadioTile(
                    title: const Text('Gray'),
                    value: HairColor.gray,
                    notifier: _notifier,
                    extract: (p) => p.hairColor,
                    onUpdate: _setHairColor,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _setGender(Gender value) =>
      _notifier.value = _notifier.value.copyWith(gender: value);

  void _setReligion(String value) =>
      _notifier.value = _notifier.value.copyWith(religion: value);

  void _setEducation(Education value) =>
      _notifier.value = _notifier.value.copyWith(education: value);

  void _setCommunity(Set<String> value) =>
      _notifier.value = _notifier.value.copyWith(community: value);

  void _setLanguage(Set<String> value) =>
      _notifier.value = _notifier.value.copyWith(language: value);

  void _setSkinColor(SkinColor value) =>
      _notifier.value = _notifier.value.copyWith(skinColor: value);

  void _setOccupation(String value) =>
      _notifier.value = _notifier.value.copyWith(occupation: value);

  void _setHairColor(HairColor value) =>
      _notifier.value = _notifier.value.copyWith(hairColor: value);

  Future<bool> _maybeUpdateProfile(BuildContext context) async {
    if (widget.initialProfile == _notifier.value) {
      return true;
    }

    final usersApi = ref.read(usersApiProvider);

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return false;
    }

    final popDialog = showBlockingModalDialog(
      context: context,
      builder: (_) => const Loading(),
    );

    try {
      await usersApi.updatePrivateProfile(uid, _notifier.value);
      popDialog();
    } catch (e, s) {
      popDialog();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update profile'),
        ),
      );
      print(e);
      print(s);
      return false;
    }

    return true;
  }
}

class ExpansionSection extends StatefulWidget {
  final String label;
  final List<Widget> children;

  const ExpansionSection({
    Key? key,
    required this.label,
    required this.children,
  }) : super(key: key);

  @override
  _ExpansionSectionState createState() => _ExpansionSectionState();
}

class _ExpansionSectionState extends State<ExpansionSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  bool _expanded = false;

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
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            setState(() => _expanded = !_expanded);
            if (_expanded) {
              _controller.forward();
            } else {
              _controller.reverse();
            }
          },
          child: SizedBox(
            height: 32,
            child: Row(
              children: [
                AnimatedRotation(
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOut,
                  turns: _expanded ? 0.25 : 0,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0, right: 12.0),
                    child: Text(
                      '►',
                      style: Theming.of(context).text.body.copyWith(
                            color: const Color.fromARGB(0xFF, 0xDD, 0x74, 0x7B),
                          ),
                    ),
                  ),
                ),
                Text(
                  widget.label,
                  style: _listTextStyle(context),
                ),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.center,
          child: SizeTransition(
            sizeFactor: _controller,
            child: ListView(
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              children: widget.children,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileValueNotifier extends ValueNotifier<PrivateProfile> {
  _ProfileValueNotifier(PrivateProfile value) : super(value);
}

class _Tile extends StatelessWidget {
  final Widget title;
  final bool selected;
  final ValueChanged<bool> onChanged;
  const _Tile({
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
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.centerRight,
        color: selected ? const Color.fromARGB(0xFF, 0xFF, 0xD4, 0xD4) : null,
        child: DefaultTextStyle(
          style: _listTextStyle(context),
          child: title,
        ),
      ),
    );
  }
}

TextStyle _listTextStyle(BuildContext context) {
  return Theming.of(context).text.subheading.copyWith(
    color: const Color.fromARGB(0xFF, 0xFF, 0x71, 0x71),
    shadows: [
      BoxShadow(
        blurRadius: 3,
        offset: const Offset(1.0, 1.0),
        color: Theming.of(context).shadow,
      ),
    ],
  );
}

class _SelectableTile<T> extends StatefulWidget {
  final Widget title;
  final T value;
  final _ProfileValueNotifier notifier;
  final Set<T> Function(PrivateProfile profile) extract;
  final void Function(Set<T> newSet) onUpdate;

  const _SelectableTile({
    Key? key,
    required this.title,
    required this.value,
    required this.extract,
    required this.notifier,
    required this.onUpdate,
  }) : super(key: key);

  @override
  State<_SelectableTile<T>> createState() => _SelectableTileState<T>();
}

class _SelectableTileState<T> extends State<_SelectableTile<T>> {
  bool _contains = false;

  @override
  void initState() {
    super.initState();
    _contains = widget.extract(widget.notifier.value).contains(widget.value);
    widget.notifier.addListener(_listener);
  }

  @override
  void dispose() {
    widget.notifier.removeListener(_listener);
    super.dispose();
  }

  void _listener() {
    final contains =
        widget.extract(widget.notifier.value).contains(widget.value);
    if (_contains != contains) {
      setState(() => _contains = contains);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _Tile(
      title: widget.title,
      selected: _contains,
      onChanged: (selected) {
        final newSet = Set.of(widget.extract(widget.notifier.value));
        if (selected) {
          newSet.add(widget.value);
        } else {
          newSet.remove(widget.value);
        }
        widget.onUpdate(newSet);
      },
    );
  }
}

class _RadioTile<T> extends StatefulWidget {
  final Widget title;
  final T value;
  final _ProfileValueNotifier notifier;
  final T Function(PrivateProfile profile) extract;
  final void Function(T value) onUpdate;

  const _RadioTile({
    Key? key,
    required this.title,
    required this.value,
    required this.extract,
    required this.notifier,
    required this.onUpdate,
  }) : super(key: key);

  @override
  State<_RadioTile<T>> createState() => _RadioTileState<T>();
}

class _RadioTileState<T> extends State<_RadioTile<T>> {
  bool _selected = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.extract(widget.notifier.value) == widget.value;
    widget.notifier.addListener(_listener);
  }

  @override
  void dispose() {
    widget.notifier.removeListener(_listener);
    super.dispose();
  }

  void _listener() {
    final selected = widget.extract(widget.notifier.value) == widget.value;
    if (_selected != selected) {
      setState(() => _selected = selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _Tile(
      title: widget.title,
      selected: _selected,
      onChanged: (selected) {
        if (selected) {
          widget.onUpdate(widget.value);
        }
      },
    );
  }
}

class _Slider extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final void Function(int value) onUpdate;
  const _Slider({
    Key? key,
    required this.value,
    required this.min,
    required this.max,
    required this.onUpdate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Slider(
      activeColor: const Color.fromARGB(0xFF, 0xFF, 0x71, 0x71),
      inactiveColor: const Color.fromARGB(0x88, 0xFF, 0x71, 0x71),
      divisions: max - min,
      value: value.toDouble(),
      min: min.toDouble(),
      max: max.toDouble(),
      onChanged: (value) => onUpdate(value.toInt()),
    );
  }
}
