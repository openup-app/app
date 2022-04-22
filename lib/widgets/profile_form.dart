import 'package:flutter/material.dart';
import 'package:openup/api/users/profile.dart';
import 'package:openup/widgets/preference.dart';
import 'package:syncfusion_flutter_core/theme.dart';

const _interests = [
  'Music',
  'Gaming',
  'Television',
  'Traveling',
  'Reading',
  'Sports & Exercise',
  'Shopping',
  'Food & Cooking',
];

class AttributesForm extends StatelessWidget {
  final Interests interests;
  final void Function(Interests interests) onChanged;
  final int? expandedSection;
  final void Function(int index) onExpansion;

  const AttributesForm({
    Key? key,
    required this.interests,
    required this.onChanged,
    required this.expandedSection,
    required this.onExpansion,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final interestsSet = Set.of(interests.interests);
    return SfSliderTheme(
      data: SfSliderThemeData(
        thumbRadius: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PreferencesExpansionSection(
            label: '',
            expanded: true,
            onPressed: () {},
            children: [
              for (final interest in _interests)
                PreferencesSetTile<String>(
                  title: Text(interest),
                  value: interest,
                  set: interestsSet,
                  onChanged: (value) {
                    if (value.length <= 3) {
                      onChanged(interests.copyWith(interests: value.toList()));
                    }
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
