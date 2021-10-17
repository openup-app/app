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
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Button(
                onPressed: onPressedUpper,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        SoloDoubleScreenTheme.of(context).upperGradientInner,
                        SoloDoubleScreenTheme.of(context).upperGradientOuter,
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      imageUpper,
                      const SizedBox(height: 24),
                      Text(
                        labelUpper,
                        textAlign: TextAlign.center,
                        style: Theming.of(context).text.large.copyWith(
                          shadows: [
                            BoxShadow(
                              color: Theming.of(context).shadow,
                              spreadRadius: 0.0,
                              blurRadius: 32.0,
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Button(
                onPressed: onPressedLower,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        SoloDoubleScreenTheme.of(context).lowerGradientInner,
                        SoloDoubleScreenTheme.of(context).lowerGradientOuter,
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      imageLower,
                      const SizedBox(height: 24),
                      Text(
                        labelLower,
                        textAlign: TextAlign.center,
                        style: Theming.of(context).text.large.copyWith(
                          shadows: [
                            BoxShadow(
                              color: Theming.of(context).shadow,
                              spreadRadius: 0.0,
                              blurRadius: 32.0,
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
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
    required Color upperGradientInner,
    required Color upperGradientOuter,
    required Color lowerGradientInner,
    required Color lowerGradientOuter,
    required Color profileButtonColor,
    Color? homeButtonColor,
  }) = _SoloDoubleScreenThemeData;
}
