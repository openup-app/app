import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:openup/api/users/preferences.dart';
import 'package:openup/api/users/users_api.dart';
import 'package:openup/util/emoji.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/loading_dialog.dart';
import 'package:openup/widgets/profile_button.dart';
import 'package:openup/widgets/slider.dart';
import 'package:openup/widgets/theming.dart';

part 'preferences_screen.freezed.dart';

late StateProvider<Preferences> _prefsProvider;
void _initPreferences(Preferences preferences) {
  _prefsProvider = StateProvider<Preferences>((ref) {
    return preferences;
  });
}

final _matchCountProvider = StateProvider<int?>((ref) => 0);

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
  @override
  void initState() {
    super.initState();
    _initPreferences(widget.initialPreferences);
  }

  @override
  Widget build(BuildContext context) {
    return _PreferencesScreen(
      initialPreferences: widget.initialPreferences,
      title: widget.title,
      image: widget.image,
      updatePreferences: widget.updatePreferences,
      ref: ref,
    );
  }
}

class _PreferencesScreen extends ConsumerStatefulWidget {
  final Preferences initialPreferences;
  final String title;
  final Widget image;
  final Future<void> Function(
      UsersApi usersApi, String uid, Preferences preferences) updatePreferences;
  final WidgetRef ref;

  const _PreferencesScreen({
    Key? key,
    required this.initialPreferences,
    required this.title,
    required this.image,
    required this.updatePreferences,
    required this.ref,
  }) : super(key: key);

  @override
  ConsumerState<_PreferencesScreen> createState() => __PreferencesScreenState();
}

class __PreferencesScreenState extends ConsumerState<_PreferencesScreen> {
  void Function()? _removePreferencesUpdatedListener;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _removePreferencesUpdatedListener?.call();

    WidgetsBinding.instance?.addPostFrameCallback((_) {
      _removePreferencesUpdatedListener =
          ref.watch(_prefsProvider.state).addListener(_preferencesUpdated);
    });
  }

  @override
  void dispose() {
    super.dispose();
    _removePreferencesUpdatedListener?.call();
  }

  void _preferencesUpdated(Preferences preferences) async {
    final auth = FirebaseAuth.instance;
    final uid = auth.currentUser?.uid;
    if (uid != null) {
      int? count;

      ref.read(_matchCountProvider.state).state = null;

      try {
        count = await ref
            .read(usersApiProvider)
            .getPossibleFriendCount(uid, preferences);
      } catch (e) {
        print(e);
      }
      ref.read(_matchCountProvider.state).state = count;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => _maybeUpdatePreferences(context),
      child: DecoratedBox(
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
            Column(
              children: [
                SizedBox(height: MediaQuery.of(context).padding.top),
                const SizedBox(height: 40),
                Text(
                  widget.title,
                  style: Theming.of(context).text.headline.copyWith(
                    color: PreferencesScreenTheme.of(context).titleColor,
                    shadows: [
                      BoxShadow(
                        color:
                            PreferencesScreenTheme.of(context).titleShadowColor,
                        spreadRadius: 2.0,
                        blurRadius: 16.0,
                        offset: const Offset(0.0, 2.0),
                      )
                    ],
                  ),
                ),
                Text(
                  'preferences',
                  style: Theming.of(context).text.headline.copyWith(
                    fontSize: 24,
                    color: PreferencesScreenTheme.of(context).titleColor,
                    shadows: [
                      BoxShadow(
                        color:
                            PreferencesScreenTheme.of(context).titleShadowColor,
                        spreadRadius: 2.0,
                        blurRadius: 16.0,
                        offset: const Offset(0.0, 2.0),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: widget.image,
                      ),
                      Positioned(
                        right: 12,
                        bottom: 4,
                        child: Container(
                          height: 24,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.all(
                              Radius.circular(12),
                            ),
                            boxShadow: [
                              BoxShadow(
                                blurRadius: 6,
                                offset: const Offset(0.0, 4.0),
                                color: Theming.of(context).shadow,
                              ),
                            ],
                            color: Colors.white,
                          ),
                          child: AnimatedSize(
                            duration: const Duration(milliseconds: 450),
                            curve: Curves.easeOut,
                            alignment: Alignment.bottomCenter,
                            child: Consumer(builder: (context, ref, child) {
                              final matchCount =
                                  ref.watch(_matchCountProvider.state).state;
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (matchCount == null)
                                    const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 4,
                                        horizontal: 8.0,
                                      ),
                                      child: Center(
                                        child: AspectRatio(
                                          aspectRatio: 1.0,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      ),
                                    )
                                  else ...[
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4.0),
                                      child: Text(
                                        '•',
                                        style: Theming.of(context)
                                            .text
                                            .body
                                            .copyWith(
                                                color: const Color.fromARGB(
                                                    0xFF, 0x00, 0xFF, 0x38)),
                                      ),
                                    ),
                                    Text(
                                      matchCount.toString(),
                                      style: Theming.of(context)
                                          .text
                                          .headline
                                          .copyWith(
                                        fontSize: 18,
                                        color: const Color.fromARGB(
                                            0xFF, 0x00, 0xD1, 0xFF),
                                        shadows: [
                                          const BoxShadow(
                                            color: Color.fromARGB(
                                                0xAA, 0x00, 0xD1, 0xFF),
                                            spreadRadius: 2.0,
                                            blurRadius: 16.0,
                                            offset: Offset(0.0, 2.0),
                                          )
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                ],
                              );
                            }),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 32),
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
                            'Who are you looking for?',
                            style: Theming.of(context).text.body.copyWith(
                                  color: const Color.fromARGB(
                                      0xFF, 0x9A, 0x9A, 0x9A),
                                ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Consumer(
                          builder: (context, ref, child) {
                            final ageRange = ref.watch(
                                _prefsProvider.select((p) => p.age));
                            const defaultRange = Range(min: 18, max: 99);
                            return ExpansionSection(
                              label: 'Age',
                              highlighted: ageRange != defaultRange,
                              children: [
                                _RangeSlider(
                                  values: ageRange,
                                  min: defaultRange.min,
                                  max: defaultRange.max,
                                  onUpdate: (range) {
                                    ref.read(_prefsProvider.state).state = ref
                                        .read(_prefsProvider)
                                        .copyWith(age: range);
                                  },
                                ),
                              ],
                            );
                          },
                        ),
                        Consumer(
                          builder: (context, ref, child) {
                            final genders = ref.watch(
                                _prefsProvider.select((p) => p.gender));
                            return ExpansionSection(
                              label: 'Gender',
                              highlighted: genders.isNotEmpty,
                              children: [
                                _SetTile(
                                  title: const Text('Male'),
                                  value: Gender.male,
                                  set: genders,
                                  onChanged: _setGender,
                                ),
                                _SetTile(
                                  title: const Text('Female'),
                                  value: Gender.female,
                                  set: genders,
                                  onChanged: _setGender,
                                ),
                                _SetTile(
                                  title: const Text('Trans Male'),
                                  value: Gender.transMale,
                                  set: genders,
                                  onChanged: _setGender,
                                ),
                                _SetTile(
                                  title: const Text('Trans Female'),
                                  value: Gender.transFemale,
                                  set: genders,
                                  onChanged: _setGender,
                                ),
                                _SetTile(
                                  title: const Text('Non Binary'),
                                  value: Gender.nonBinary,
                                  set: genders,
                                  onChanged: _setGender,
                                ),
                              ],
                            );
                          },
                        ),
                        Consumer(
                          builder: (context, ref, child) {
                            final distance = ref.watch(
                                _prefsProvider.select((p) => p.distance));
                            const max = 100;
                            return ExpansionSection(
                              label: 'Location',
                              highlighted: distance < max,
                              children: [
                                Container(
                                  padding: const EdgeInsets.only(right: 16),
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    'Up to $distance miles away',
                                    style: _listTextStyle(context)
                                        .copyWith(fontSize: 16),
                                  ),
                                ),
                                _Slider(
                                  value: distance,
                                  min: 0,
                                  max: max,
                                  onUpdate: (value) {
                                    ref.read(_prefsProvider.state).state = ref
                                        .read(_prefsProvider)
                                        .copyWith(distance: value);
                                  },
                                ),
                              ],
                            );
                          },
                        ),
                        Consumer(
                          builder: (context, ref, child) {
                            final religions = ref.watch(
                                _prefsProvider.select((p) => p.religion));
                            return ExpansionSection(
                              label: 'Religion',
                              highlighted: religions.isNotEmpty,
                              children: [
                                _TextTile(
                                  icon: const Icon(
                                    Icons.add,
                                    color: Colors.red,
                                  ),
                                  hintText: 'Add a religion',
                                  onAdded: (value) {},
                                ),
                                _SetTile(
                                  title: const Text('Islam'),
                                  value: 'Islam',
                                  set: religions,
                                  onChanged: _setReligion,
                                ),
                                _SetTile(
                                  title: const Text('Hinduism'),
                                  value: 'Hinduism',
                                  set: religions,
                                  onChanged: _setReligion,
                                ),
                                _SetTile(
                                  title: const Text('Judaism'),
                                  value: 'Judaism',
                                  set: religions,
                                  onChanged: _setReligion,
                                ),
                                _SetTile(
                                  title: const Text('Sikhism'),
                                  value: 'Sikhism',
                                  set: religions,
                                  onChanged: _setReligion,
                                ),
                                _SetTile(
                                  title: const Text('Buddhism'),
                                  value: 'Buddhism',
                                  set: religions,
                                  onChanged: _setReligion,
                                ),
                              ],
                            );
                          },
                        ),
                        Consumer(
                          builder: (context, ref, child) {
                            final educations = ref.watch(_prefsProvider
                                .select((p) => p.education));
                            return ExpansionSection(
                              label: 'Education',
                              highlighted: educations.isNotEmpty,
                              children: [
                                _SetTile(
                                  title: const Text('High School'),
                                  value: Education.highSchool,
                                  set: educations,
                                  onChanged: _setEducation,
                                ),
                                _SetTile(
                                  title: const Text('Associates Degree'),
                                  value: Education.associatesDegree,
                                  set: educations,
                                  onChanged: _setEducation,
                                ),
                                _SetTile(
                                  title: const Text('Bachelors Degree'),
                                  value: Education.bachelorsDegree,
                                  set: educations,
                                  onChanged: _setEducation,
                                ),
                                _SetTile(
                                  title: const Text('Masters Degree'),
                                  value: Education.mastersDegree,
                                  set: educations,
                                  onChanged: _setEducation,
                                ),
                                _SetTile(
                                  title: const Text('No Schooling'),
                                  value: Education.noSchooling,
                                  set: educations,
                                  onChanged: _setEducation,
                                ),
                              ],
                            );
                          },
                        ),
                        Consumer(
                          builder: (context, ref, child) {
                            final communities = ref.watch(_prefsProvider
                                .select((p) => p.community));
                            return ExpansionSection(
                              label: 'Community',
                              highlighted: communities.isNotEmpty,
                              children: [
                                _TextTile(
                                  icon: const Icon(
                                    Icons.add,
                                    color: Colors.red,
                                  ),
                                  hintText: 'Add a community',
                                  onAdded: (value) {},
                                ),
                                _SetTile(
                                  title: const Text('Punjabi'),
                                  value: 'Punjabi',
                                  set: communities,
                                  onChanged: _setCommunity,
                                ),
                                _SetTile(
                                  title: const Text('Black'),
                                  value: 'Black',
                                  set: communities,
                                  onChanged: _setCommunity,
                                ),
                                _SetTile(
                                  title: const Text('White'),
                                  value: 'White',
                                  set: communities,
                                  onChanged: _setCommunity,
                                ),
                                _SetTile(
                                  title: const Text('Indian'),
                                  value: 'Indian',
                                  set: communities,
                                  onChanged: _setCommunity,
                                ),
                                _SetTile(
                                  title: const Text('Gujarati'),
                                  value: 'Gujarati',
                                  set: communities,
                                  onChanged: _setCommunity,
                                ),
                                _SetTile(
                                  title: const Text('Armenian'),
                                  value: 'Armenian',
                                  set: communities,
                                  onChanged: _setCommunity,
                                ),
                                _SetTile(
                                  title: const Text('Chinese'),
                                  value: 'Chinese',
                                  set: communities,
                                  onChanged: _setCommunity,
                                ),
                                _SetTile(
                                  title: const Text('Japanese'),
                                  value: 'Japanese',
                                  set: communities,
                                  onChanged: _setCommunity,
                                ),
                                _SetTile(
                                  title: const Text('Lebanese'),
                                  value: 'Lebanese',
                                  set: communities,
                                  onChanged: _setCommunity,
                                ),
                                _SetTile(
                                  title: const Text('African'),
                                  value: 'African',
                                  set: communities,
                                  onChanged: _setCommunity,
                                ),
                              ],
                            );
                          },
                        ),
                        Consumer(
                          builder: (context, ref, child) {
                            final languages = ref.watch(
                                _prefsProvider.select((p) => p.language));
                            return ExpansionSection(
                              label: 'Languages',
                              highlighted: languages.isNotEmpty,
                              children: [
                                _TextTile(
                                  icon: const Icon(
                                    Icons.add,
                                    color: Colors.red,
                                  ),
                                  hintText: 'Add a language',
                                  onAdded: (value) {},
                                ),
                                _SetTile(
                                  title: const Text('Punjabi'),
                                  value: 'Punjabi',
                                  set: languages,
                                  onChanged: _setLanguage,
                                ),
                                _SetTile(
                                  title: const Text('Indian'),
                                  value: 'Indian',
                                  set: languages,
                                  onChanged: _setLanguage,
                                ),
                                _SetTile(
                                  title: const Text('Gujarati'),
                                  value: 'Gujarati',
                                  set: languages,
                                  onChanged: _setLanguage,
                                ),
                                _SetTile(
                                  title: const Text('Armenian'),
                                  value: 'Armenian',
                                  set: languages,
                                  onChanged: _setLanguage,
                                ),
                                _SetTile(
                                  title: const Text('Chinese'),
                                  value: 'Chinese',
                                  set: languages,
                                  onChanged: _setLanguage,
                                ),
                                _SetTile(
                                  title: const Text('Japanese'),
                                  value: 'Japanese',
                                  set: languages,
                                  onChanged: _setLanguage,
                                ),
                                _SetTile(
                                  title: const Text('Lebanese'),
                                  value: 'Lebanese',
                                  set: languages,
                                  onChanged: _setLanguage,
                                ),
                                _SetTile(
                                  title: const Text('African'),
                                  value: 'African',
                                  set: languages,
                                  onChanged: _setLanguage,
                                ),
                              ],
                            );
                          },
                        ),
                        Consumer(
                          builder: (context, ref, child) {
                            final skinColors = ref.watch(_prefsProvider
                                .select((p) => p.skinColor));
                            final genders = ref.watch(
                                _prefsProvider.select((p) => p.gender));
                            final gender = genderForPreferredGenders(genders);
                            return ExpansionSection(
                              label: 'Skin Color',
                              highlighted: skinColors.isNotEmpty,
                              children: [
                                for (int i = 0;
                                    i < SkinColor.values.length;
                                    i++)
                                  _SetTile(
                                    title: Text(emojiForGender(gender)[i]),
                                    value: SkinColor.values[i],
                                    set: skinColors,
                                    onChanged: _setSkinColor,
                                  ),
                              ],
                            );
                          },
                        ),
                        Consumer(
                          builder: (context, ref, child) {
                            final weightRange = ref.watch(
                                _prefsProvider.select((p) => p.weight));
                            const defaultRange = Range(min: 10, max: 500);
                            return ExpansionSection(
                              label: 'Weight',
                              highlighted: weightRange != defaultRange,
                              children: [
                                _RangeSlider(
                                  values: weightRange,
                                  min: defaultRange.min,
                                  max: defaultRange.max,
                                  onUpdate: (range) {
                                    ref.read(_prefsProvider.state).state = ref
                                        .read(_prefsProvider)

                                        .copyWith(weight: range);
                                  },
                                ),
                              ],
                            );
                          },
                        ),
                        Consumer(
                          builder: (context, ref, child) {
                            final heightRange = ref.watch(
                                _prefsProvider.select((p) => p.height));
                            const defaultRange = Range(min: 50, max: 250);
                            return ExpansionSection(
                              label: 'Height',
                              highlighted: heightRange != defaultRange,
                              children: [
                                _RangeSlider(
                                  values: heightRange,
                                  min: defaultRange.min,
                                  max: defaultRange.max,
                                  onUpdate: (range) {
                                    ref.read(_prefsProvider.state).state = ref
                                        .read(_prefsProvider)
                                        
                                        .copyWith(height: range);
                                  },
                                ),
                              ],
                            );
                          },
                        ),
                        Consumer(
                          builder: (context, ref, child) {
                            final occupations = ref.watch(_prefsProvider
                                .select((p) => p.occupation));
                            return ExpansionSection(
                              label: 'Job Occupation',
                              highlighted: occupations.isNotEmpty,
                              children: [
                                _TextTile(
                                  icon: const Icon(
                                    Icons.add,
                                    color: Colors.red,
                                  ),
                                  hintText: 'Add a job',
                                  onAdded: (value) {},
                                ),
                                _SetTile(
                                  title: const Text('Accountant'),
                                  value: 'Accountant',
                                  set: occupations,
                                  onChanged: _setOccupation,
                                ),
                                _SetTile(
                                  title: const Text('Entrepreneur'),
                                  value: 'Entrepreneur',
                                  set: occupations,
                                  onChanged: _setOccupation,
                                ),
                                _SetTile(
                                  title: const Text('Oil Man'),
                                  value: 'Oil Man',
                                  set: occupations,
                                  onChanged: _setOccupation,
                                ),
                                _SetTile(
                                  title: const Text('Welder'),
                                  value: 'Welder',
                                  set: occupations,
                                  onChanged: _setOccupation,
                                ),
                                _SetTile(
                                  title: const Text('Data Scientist'),
                                  value: 'Data Scientist',
                                  set: occupations,
                                  onChanged: _setOccupation,
                                ),
                              ],
                            );
                          },
                        ),
                        Consumer(
                          builder: (context, ref, child) {
                            final hairColors = ref.watch(_prefsProvider
                                .select((p) => p.hairColor));
                            return ExpansionSection(
                              label: 'Hair Color',
                              highlighted: hairColors.isNotEmpty,
                              children: [
                                _SetTile(
                                  title: const Text('Black'),
                                  value: HairColor.black,
                                  set: hairColors,
                                  onChanged: _setHairColor,
                                ),
                                _SetTile(
                                  title: const Text('Blonde'),
                                  value: HairColor.blonde,
                                  set: hairColors,
                                  onChanged: _setHairColor,
                                ),
                                _SetTile(
                                  title: const Text('Brunette'),
                                  value: HairColor.brunette,
                                  set: hairColors,
                                  onChanged: _setHairColor,
                                ),
                                _SetTile(
                                  title: const Text('Brown'),
                                  value: HairColor.brown,
                                  set: hairColors,
                                  onChanged: _setHairColor,
                                ),
                                _SetTile(
                                  title: const Text('Red'),
                                  value: HairColor.red,
                                  set: hairColors,
                                  onChanged: _setHairColor,
                                ),
                                _SetTile(
                                  title: const Text('Gray'),
                                  value: HairColor.gray,
                                  set: hairColors,
                                  onChanged: _setHairColor,
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: MediaQuery.of(context).padding.left + 16,
              child: Button(
                onPressed: () async {
                  if (await _maybeUpdatePreferences(context)) {
                    Navigator.of(context).pop();
                  }
                },
                child: Image.asset(
                  'assets/images/preferences_back.png',
                  width: 40,
                  height: 40,
                  color: PreferencesScreenTheme.of(context).backArrowColor,
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: MediaQuery.of(context).padding.right + 16,
              child: ProfileButton(
                color: PreferencesScreenTheme.of(context).profileButtonColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _setGender(Set<Gender> value) => widget.ref.read(_prefsProvider.state).state =
      widget.ref.read(_prefsProvider).copyWith(gender: value);

  void _setReligion(Set<String> value) =>
      widget.ref.read(_prefsProvider.state).state =
          widget.ref.read(_prefsProvider).copyWith(religion: value);

  void _setEducation(Set<Education> value) =>
      widget.ref.read(_prefsProvider.state).state =
          widget.ref.read(_prefsProvider).copyWith(education: value);

  void _setCommunity(Set<String> value) =>
      widget.ref.read(_prefsProvider.state).state =
          widget.ref.read(_prefsProvider).copyWith(community: value);

  void _setLanguage(Set<String> value) =>
      widget.ref.read(_prefsProvider.state).state =
          widget.ref.read(_prefsProvider).copyWith(language: value);

  void _setSkinColor(Set<SkinColor> value) =>
      widget.ref.read(_prefsProvider.state).state =
          widget.ref.read(_prefsProvider).copyWith(skinColor: value);

  void _setOccupation(Set<String> value) =>
      widget.ref.read(_prefsProvider.state).state =
          widget.ref.read(_prefsProvider).copyWith(occupation: value);

  void _setHairColor(Set<HairColor> value) =>
      widget.ref.read(_prefsProvider.state).state =
          widget.ref.read(_prefsProvider).copyWith(hairColor: value);

  Future<bool> _maybeUpdatePreferences(BuildContext context) async {
    final preferences = widget.ref.read(_prefsProvider);
    if (widget.initialPreferences == preferences) {
      return true;
    }

    final container = ProviderScope.containerOf(context);
    final usersApi = container.read(usersApiProvider);

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return false;
    }

    final popDialog = showBlockingModalDialog(
      context: context,
      builder: (_) => const Loading(),
    );

    try {
      await widget.updatePreferences(usersApi, uid, preferences);
      popDialog();
    } catch (e, s) {
      popDialog();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update preferences'),
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
  final bool highlighted;
  final List<Widget> children;

  const ExpansionSection({
    Key? key,
    required this.label,
    this.highlighted = false,
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
        Button(
          onPressed: () {
            setState(() => _expanded = !_expanded);
            if (_expanded) {
              _controller.forward();
            } else {
              _controller.reverse();
            }
          },
          child: Container(
            height: 32,
            decoration: BoxDecoration(
              color: widget.highlighted
                  ? const Color.fromARGB(0xFF, 0xFF, 0xD4, 0xD4)
                  : null,
            ),
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

class _SetTile<T> extends StatelessWidget {
  final Widget title;
  final T value;
  final Set<T> set;
  final ValueChanged<Set<T>> onChanged;

  const _SetTile({
    Key? key,
    required this.title,
    required this.value,
    required this.set,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _Tile(
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
    );
  }
}

TextStyle _listTextStyle(BuildContext context) {
  return Theming.of(context).text.subheading.copyWith(
    fontWeight: FontWeight.normal,
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

class _TextTile extends StatelessWidget {
  final String hintText;
  final Widget icon;
  final void Function(String value) onAdded;

  const _TextTile({
    Key? key,
    required this.hintText,
    required this.icon,
    required this.onAdded,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Container(
        height: 44.0,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.only(left: 10, right: 22),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(22)),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Theming.of(context).shadow,
              offset: const Offset(0.0, 2.0),
              blurRadius: 2.0,
            ),
          ],
        ),
        child: TextField(
          textAlign: TextAlign.end,
          decoration: InputDecoration(
            icon: icon,
            hintText: hintText,
            hintStyle: Theming.of(context)
                .text
                .body
                .copyWith(color: Colors.grey, fontWeight: FontWeight.normal),
            border: InputBorder.none,
          ),
        ),
      ),
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

class _RangeSlider extends StatelessWidget {
  final Range values;
  final int min;
  final int max;
  final void Function(Range range) onUpdate;
  const _RangeSlider({
    Key? key,
    required this.values,
    required this.min,
    required this.max,
    required this.onUpdate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: LabeledRangedSlider(
        values: RangeValues(values.min.toDouble(), values.max.toDouble()),
        min: min.toDouble(),
        max: max.toDouble(),
        activeColor: const Color.fromARGB(0xFF, 0xFF, 0x71, 0x71),
        inactiveColor: const Color.fromARGB(0x88, 0xFF, 0x71, 0x71),
        onChanged: (values) {
          onUpdate(
            Range(
              min: values.start.toInt(),
              max: values.end.toInt(),
            ),
          );
        },
      ),
    );
  }
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
    required Color titleShadowColor,
    required Color backArrowColor,
    required Color profileButtonColor,
  }) = _PreferencesScreenThemeData;
}
