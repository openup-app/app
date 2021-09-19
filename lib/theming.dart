import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class ThemingData {
  final friendBlue1 = const Color.fromARGB(0xFF, 0xCE, 0xF6, 0xFF);
  final friendBlue2 = const Color.fromARGB(0xFF, 0x1C, 0xC1, 0xE4);
  final friendBlue3 = const Color.fromARGB(0xFF, 0x01, 0xAF, 0xD5);
  final friendBlue4 = const Color.fromARGB(0xFF, 0x11, 0x8E, 0xDD);
  final friendBlue5 = const Color.fromARGB(0xFF, 0x00, 0xB0, 0xD7);

  final datingRed1 = const Color.fromARGB(0xFF, 0xFF, 0xCC, 0xCC);
  final datingRed2 = const Color.fromARGB(0xFF, 0xFF, 0xA2, 0xA2);

  final alertRed = const Color.fromARGB(0xFF, 0xFF, 0x00, 0x00);

  final notificationRed = const Color.fromARGB(0xFF, 0xA0, 0x06, 0x06);

  final shadow = const Color.fromARGB(0x40, 0x00, 0x00, 0x00);

  final text = const TextTheme._();

  const ThemingData._();
}

class TextTheme {
  final large = const TextStyle(
    color: Colors.white,
    fontFamily: 'Myriad',
    fontSize: 36,
    fontWeight: FontWeight.w400,
  );

  final headline = const TextStyle(
    color: Colors.white,
    fontFamily: 'Myriad',
    fontSize: 32,
    fontWeight: FontWeight.w400,
  );

  final subheading = const TextStyle(
    color: Colors.white,
    fontFamily: 'Myriad',
    fontSize: 22,
    fontWeight: FontWeight.w600,
  );

  final body = const TextStyle(
    color: Colors.white,
    fontFamily: 'Myriad',
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  final bodySecondary = const TextStyle(
    color: Colors.white,
    fontFamily: 'Myriad',
    fontSize: 23,
    fontWeight: FontWeight.w400,
  );

  final button = const TextStyle(
    color: Colors.white,
    fontFamily: 'Myriad',
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  final caption = const TextStyle(
    color: Colors.white,
    fontFamily: 'Myriad',
    fontSize: 12,
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
