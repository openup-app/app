import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/home_button.dart';
import 'package:openup/widgets/profile_button.dart';
import 'package:openup/widgets/theming.dart';
import 'package:openup/widgets/toggle_button.dart';

part 'menu_screen.freezed.dart';

class MenuScreen extends StatelessWidget {
  final String label;
  final Widget image;
  final bool groupCalling;
  final VoidCallback onPressedVoiceCall;
  final VoidCallback onPressedVideoCall;
  final VoidCallback onPressedPreferences;

  const MenuScreen({
    Key? key,
    required this.label,
    required this.image,
    this.groupCalling = false,
    required this.onPressedVoiceCall,
    required this.onPressedVideoCall,
    required this.onPressedPreferences,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    final buttonStyle = Theming.of(context).text.bodySecondary.copyWith(
      fontSize: 19,
      shadows: [
        BoxShadow(
          color: Colors.black.withOpacity(0.4),
          blurRadius: 16.0,
          offset: const Offset(0.0, 2.0),
        ),
      ],
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white,
            MenuScreenTheme.of(context).backgroundGradientBottom,
          ],
        ),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(),
                Text(
                  label,
                  style: Theming.of(context).text.headline.copyWith(
                    color: MenuScreenTheme.of(context).titleColor,
                    shadows: [
                      BoxShadow(
                        color: MenuScreenTheme.of(context).titleShadowColor,
                        spreadRadius: 2.0,
                        blurRadius: 16.0,
                        offset: const Offset(0.0, 2.0),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    image,
                    if (!groupCalling)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Column(
                          children: [
                            ToggleButton(
                              value: true,
                              onChanged: (_) {},
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'casual',
                              style: TextStyle(
                                color: Color.fromARGB(0xFF, 0x8B, 0xC0, 0xFF),
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                  ],
                ),
                PrimaryIconButton(
                  onPressed: onPressedVoiceCall,
                  icon: Image.asset('assets/images/voice_call.png'),
                  color: MenuScreenTheme.of(context).buttonColorTop,
                  child: Text(
                    'Talk to someone new',
                    style: buttonStyle,
                  ),
                ),
                const SizedBox(height: 20),
                PrimaryIconButton(
                  onPressed: onPressedVideoCall,
                  icon: Image.asset('assets/images/video_call.png'),
                  color: MenuScreenTheme.of(context).buttonColorMiddle,
                  child: Text(
                    'Video call someone new',
                    style: buttonStyle,
                  ),
                ),
                const SizedBox(height: 20),
                PrimaryIconButton(
                  onPressed: onPressedPreferences,
                  icon: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Image.asset('assets/images/preferences.png'),
                  ),
                  color: MenuScreenTheme.of(context).buttonColorBottom,
                  child: Text(
                    'Preferences',
                    style: buttonStyle,
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: MediaQuery.of(context).padding.right + 16,
            child: ProfileButton(
              color: MenuScreenTheme.of(context).profileButtonColor,
            ),
          ),
          Positioned(
            right: MediaQuery.of(context).padding.right + 16,
            bottom: MediaQuery.of(context).padding.bottom + 16,
            child: HomeButton(
              color: MenuScreenTheme.of(context).homeButtonColor,
            ),
          ),
        ],
      ),
    );
  }
}

class MenuScreenTheme extends InheritedWidget {
  final MenuScreenThemeData themeData;

  const MenuScreenTheme({
    Key? key,
    required Widget child,
    required this.themeData,
  }) : super(key: key, child: child);

  static MenuScreenThemeData of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<MenuScreenTheme>()!
        .themeData;
  }

  @override
  bool updateShouldNotify(MenuScreenTheme oldWidget) =>
      oldWidget.themeData != themeData;
}

@freezed
class MenuScreenThemeData with _$MenuScreenThemeData {
  const factory MenuScreenThemeData({
    required Color backgroundGradientBottom,
    required Color titleColor,
    required Color titleShadowColor,
    required Color buttonColorTop,
    required Color buttonColorMiddle,
    required Color buttonColorBottom,
    required Color profileButtonColor,
    Color? homeButtonColor,
  }) = _MenuScreenThemeData;
}
