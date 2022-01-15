import 'package:flutter/material.dart';
import 'package:openup/api/users/preferences.dart';
import 'package:openup/widgets/theming.dart';

class LabeledRangedSlider extends StatelessWidget {
  final RangeValues values;
  final double min;
  final double max;
  final void Function(RangeValues values) onChanged;
  final Color? activeColor;
  final Color? inactiveColor;
  const LabeledRangedSlider({
    Key? key,
    required this.values,
    this.min = 0.0,
    this.max = 1.0,
    required this.onChanged,
    this.activeColor,
    this.inactiveColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth - 40 - 8;
          final range = max - min;
          return DefaultTextStyle(
            style: Theming.of(context)
                .text
                .caption
                .copyWith(fontSize: 11, fontWeight: FontWeight.bold),
            child: Stack(
              fit: StackFit.expand,
              alignment: Alignment.center,
              children: [
                RangeSlider(
                  key: key,
                  values: values,
                  min: min,
                  max: max,
                  onChanged: onChanged,
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                ),
                Positioned(
                  left: width * ((values.start - min) / range) + 4,
                  width: 40,
                  height: 40,
                  child: IgnorePointer(
                    child: Center(
                      child: Text(
                        values.start.toInt().toString(),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: width * ((values.end - min) / range) + 4,
                  width: 40,
                  height: 40,
                  child: IgnorePointer(
                    child: Center(
                      child: Text(
                        values.end.toInt().toString(),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class PreferencesSlider extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final void Function(int value) onUpdate;
  const PreferencesSlider({
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

class PreferencesRangeSlider extends StatelessWidget {
  final Range values;
  final int min;
  final int max;
  final void Function(Range range) onUpdate;
  const PreferencesRangeSlider({
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
