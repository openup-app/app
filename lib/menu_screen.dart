import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/home_button.dart';
import 'package:openup/widgets/profile_button.dart';
import 'package:openup/widgets/theming.dart';
import 'package:openup/widgets/toggle_button.dart';

part 'menu_screen.freezed.dart';

class MenuScreen extends StatefulWidget {
  final String label;
  final Widget image;
  final bool groupCalling;
  final void Function(bool serious) onPressedVoiceCall;
  final void Function(bool serious) onPressedVideoCall;
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
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  bool _serious = false;

  @override
  Widget build(BuildContext context) {
    final buttonStyle = Theming.of(context).text.bodySecondary.copyWith(
      fontSize: 20,
      shadows: [
        BoxShadow(
          color: Colors.black.withOpacity(0.5),
          blurRadius: 8.0,
          offset: const Offset(2.0, 2.0),
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
            padding: const EdgeInsets.symmetric(horizontal: 22.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(),
                Text(
                  widget.label,
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
                const Spacer(),
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: SizedBox(
                        height: 185,
                        child: widget.image,
                      ),
                    ),
                    if (!widget.groupCalling)
                      Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ToggleButton(
                            value: _serious,
                            color: _serious
                                ? const Color.fromRGBO(0xFF, 0x86, 0x86, 1.0)
                                : const Color.fromRGBO(0x8B, 0xC0, 0xFF, 1.0),
                            onChanged: (value) {
                              setState(() => _serious = value);
                            },
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _serious ? 'serious' : 'casual',
                            style: TextStyle(
                              color: _serious
                                  ? const Color.fromRGBO(0xFF, 0x86, 0x86, 1.0)
                                  : const Color.fromRGBO(0x8B, 0xC0, 0xFF, 1.0),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                  ],
                ),
                _MenuButton(
                  onPressed: () => widget.onPressedVoiceCall(_serious),
                  icon: Image.asset('assets/images/voice_call.png'),
                  color: MenuScreenTheme.of(context).buttonColorTop,
                  child: Text(
                    'Talk to someone new',
                    style: buttonStyle,
                  ),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: 16,
                    maxHeight: 28,
                  ),
                ),
                _MenuButton(
                  onPressed: () => widget.onPressedVideoCall(_serious),
                  icon: Image.asset('assets/images/video_call.png'),
                  color: MenuScreenTheme.of(context).buttonColorMiddle,
                  child: Text(
                    'Video call someone new',
                    style: buttonStyle,
                  ),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: 16,
                    maxHeight: 28,
                  ),
                ),
                _MenuButton(
                  onPressed: widget.onPressedPreferences,
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

/// Prominent button with an icon.
class _MenuButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget icon;
  final Color color;
  final Widget child;

  const _MenuButton({
    Key? key,
    required this.onPressed,
    required this.icon,
    required this.color,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Button(
      child: Container(
        alignment: Alignment.center,
        constraints: const BoxConstraints(maxHeight: 116),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(58)),
          color: color,
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Row(
            children: [
              const SizedBox(width: 16),
              SizedBox(
                width: 78,
                height: 78,
                child: icon,
              ),
              const SizedBox(width: 8),
              Expanded(child: child),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
      onPressed: onPressed,
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
