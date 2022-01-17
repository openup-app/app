import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/home_button.dart';
import 'package:openup/widgets/profile_button.dart';
import 'package:openup/widgets/theming.dart';

part 'solo_double_screen.freezed.dart';

class SoloDoubleScreen extends StatelessWidget {
  final String labelUpper;
  final String labelLower;
  final Widget imageUpper;
  final Widget imageLower;
  final VoidCallback onPressedUpper;
  final VoidCallback onPressedLower;

  const SoloDoubleScreen({
    Key? key,
    required this.labelUpper,
    required this.labelLower,
    required this.imageUpper,
    required this.imageLower,
    required this.onPressedUpper,
    required this.onPressedLower,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final upperGradients = SoloDoubleScreenTheme.of(context).upperGradients;
    final lowerGradients = SoloDoubleScreenTheme.of(context).lowerGradients;
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Button(
                onPressed: onPressedUpper,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    for (var gradient in upperGradients.reversed)
                      DecoratedBox(
                        decoration: BoxDecoration(gradient: gradient),
                      ),
                    Align(
                      alignment: const Alignment(0.0, -0.4),
                      child: imageUpper,
                    ),
                    Align(
                      alignment: const Alignment(0.0, 0.6),
                      child: Text(
                        labelUpper,
                        textAlign: TextAlign.center,
                        style: Theming.of(context).text.large.copyWith(
                          shadows: [
                            const BoxShadow(
                              color: Color.fromRGBO(0x00, 0x00, 0x00, 0.25),
                              spreadRadius: 0.0,
                              blurRadius: 10.0,
                              offset: Offset(2.0, 2.0),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Button(
                onPressed: onPressedLower,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    for (var gradient in lowerGradients.reversed)
                      DecoratedBox(
                        decoration: BoxDecoration(gradient: gradient),
                      ),
                    Align(
                      alignment: const Alignment(0.0, -0.4),
                      child: imageLower,
                    ),
                    Align(
                      alignment: const Alignment(0.0, 0.6),
                      child: Text(
                        labelLower,
                        textAlign: TextAlign.center,
                        style: Theming.of(context).text.large.copyWith(
                          shadows: [
                            const BoxShadow(
                              color: Color.fromRGBO(0x00, 0x00, 0x00, 0.25),
                              spreadRadius: 0.0,
                              blurRadius: 10.0,
                              offset: Offset(2.0, 2.0),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          right: MediaQuery.of(context).padding.right + 16,
          child: ProfileButton(
            color: SoloDoubleScreenTheme.of(context).profileButtonColor,
          ),
        ),
        Positioned(
          right: MediaQuery.of(context).padding.right + 16,
          bottom: MediaQuery.of(context).padding.bottom + 16,
          child: HomeButton(
            color: SoloDoubleScreenTheme.of(context).homeButtonColor,
          ),
        ),
      ],
    );
  }
}

class SoloDoubleScreenTheme extends InheritedWidget {
  final SoloDoubleScreenThemeData themeData;

  const SoloDoubleScreenTheme({
    Key? key,
    required Widget child,
    required this.themeData,
  }) : super(key: key, child: child);

  static SoloDoubleScreenThemeData of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<SoloDoubleScreenTheme>()!
        .themeData;
  }

  @override
  bool updateShouldNotify(SoloDoubleScreenTheme oldWidget) =>
      oldWidget.themeData != themeData;
}

@freezed
class SoloDoubleScreenThemeData with _$SoloDoubleScreenThemeData {
  const factory SoloDoubleScreenThemeData({
    required List<Gradient> upperGradients,
    required List<Gradient> lowerGradients,
    required Color profileButtonColor,
    Color? homeButtonColor,
  }) = _SoloDoubleScreenThemeData;
}
