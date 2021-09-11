import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class ThemingData {
  final friendBlue1 = const Color.fromARGB(0xFF, 0xCE, 0xF6, 0xFF);
  final friendBlue2 = const Color.fromARGB(0xFF, 0x1C, 0xC1, 0xE4);
  final datingRed1 = const Color.fromARGB(0xFF, 0xFF, 0xA2, 0xA2);
  final datingRed2 = const Color.fromARGB(0xFF, 0xFF, 0xCC, 0xCC);
  final shadow = const Color.fromARGB(0x40, 0x00, 0x00, 0x00);

  final text = const TextTheme._();

  const ThemingData._();
}

class TextTheme {
  final body = const TextStyle(
    color: Colors.white,
    fontFamily: 'Myriad',
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );

  const TextTheme._();
}

/// Provides access to theming information.
class Theming extends InheritedWidget {
  final _themingData = const ThemingData._();

  const Theming({
    Key? key,
    required Widget child,
  }) : super(key: key, child: child);

  static ThemingData of(BuildContext context) {
    final theming = context.dependOnInheritedWidgetOfExactType<Theming>();
    if (theming == null) {
      throw 'An ancestor Theming widget is required';
    }
    return theming._themingData;
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => false;
}
