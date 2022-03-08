import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:lottie/lottie.dart';
import 'package:openup/api/lobby/lobby_api.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/home_button.dart';
import 'package:openup/widgets/profile_button.dart';
import 'package:openup/widgets/theming.dart';
import 'package:openup/widgets/toggle_button.dart';

part 'menu_screen.freezed.dart';

final _shouldOverlayProvider =
    StateNotifierProvider<_ShouldOverlay, bool>((ref) {
  return _ShouldOverlay();
});

class _ShouldOverlay extends StateNotifier<bool> {
  _ShouldOverlay() : super(true);
  void disableOverlay() => state = false;
}

class MenuScreen extends StatefulWidget {
  final Purpose purpose;
  final String label;
  final Widget image;
  final bool groupCalling;
  final void Function(bool serious) onPressedVoiceCall;
  final void Function(bool serious) onPressedVideoCall;

  const MenuScreen({
    Key? key,
    required this.purpose,
    required this.label,
    required this.image,
    this.groupCalling = false,
    required this.onPressedVoiceCall,
    required this.onPressedVideoCall,
  }) : super(key: key);

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  bool _serious = false;
  bool _showSeriousOverlay = false;

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
    return Stack(
      children: [
        DecoratedBox(
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
                    SizedBox(height: MediaQuery.of(context).padding.top),
                    const Spacer(flex: 1),
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
                    const Spacer(flex: 1),
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
                              Consumer(builder: (context, ref, child) {
                                return ToggleButton(
                                  value: _serious,
                                  color: _serious
                                      ? const Color.fromRGBO(
                                          0xFF, 0x86, 0x86, 1.0)
                                      : const Color.fromRGBO(
                                          0x8B, 0xC0, 0xFF, 1.0),
                                  onChanged: (value) {
                                    final shouldOverlay =
                                        ref.read(_shouldOverlayProvider);
                                    ref
                                        .read(_shouldOverlayProvider.notifier)
                                        .disableOverlay();
                                    setState(() {
                                      _showSeriousOverlay =
                                          shouldOverlay && value;
                                      _serious = value;
                                    });
                                  },
                                );
                              }),
                              const SizedBox(height: 8),
                              Text(
                                _serious ? 'serious' : 'casual',
                                style: TextStyle(
                                  color: _serious
                                      ? const Color.fromRGBO(
                                          0xFF, 0x86, 0x86, 1.0)
                                      : const Color.fromRGBO(
                                          0x8B, 0xC0, 0xFF, 1.0),
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
                      icon: Lottie.asset(
                        'assets/images/call.json',
                        fit: BoxFit.contain,
                        width: 70,
                      ),
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
                      icon: Lottie.asset(
                        'assets/images/video_call.json',
                        width: 90,
                      ),
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
                    Consumer(
                      builder: (context, ref, _) {
                        return _MenuButton(
                          onPressed: () => _navigateToPreferences(ref),
                          icon: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Image.asset(
                              'assets/images/preferences.png',
                              width: 44,
                            ),
                          ),
                          color: MenuScreenTheme.of(context).buttonColorBottom,
                          child: Text(
                            'Preferences',
                            style: buttonStyle,
                          ),
                        );
                      },
                    ),
                    const Spacer(flex: 4),
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
        ),
        if (_showSeriousOverlay)
          Positioned.fill(
            child: _SeriousModeOverlay(onClose: () {
              setState(() => _showSeriousOverlay = false);
            }),
          ),
      ],
    );
  }

  void _navigateToPreferences(WidgetRef ref) {
    final userState = ref.read(userProvider);
    final preferences = widget.purpose == Purpose.friends
        ? userState.friendsPreferences
        : userState.datingPreferences;
    final route = widget.purpose == Purpose.friends ? 'friends' : 'dating';
    Navigator.of(context).pushNamed(
      '$route-preferences',
      arguments: preferences,
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
          child: Stack(
            children: [
              const SizedBox(width: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: icon,
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 86.0 + 8.0, right: 16.0),
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
      onPressed: onPressed,
    );
  }
}

class _SeriousModeOverlay extends StatelessWidget {
  final VoidCallback onClose;
  const _SeriousModeOverlay({
    Key? key,
    required this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(
        sigmaX: 4,
        sigmaY: 4,
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
              offset: Offset(0.0, 4.0),
              color: Color.fromRGBO(0x00, 0x00, 0x00, 0.25),
              blurRadius: 4,
            ),
          ],
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromRGBO(0xFD, 0x8C, 0x8C, 1.0),
              Color.fromRGBO(0xBD, 0x20, 0x20, 0.74),
            ],
          ),
        ),
        child: Column(
          children: [
            SizedBox(
              height: MediaQuery.of(context).padding.top + 32,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 32.0),
                child: Button(
                  onPressed: onClose,
                  child: Image.asset('assets/images/close_circle.png'),
                ),
              ),
            ),
            const Spacer(),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 357),
                child: Text.rich(
                  TextSpan(
                    style: Theming.of(context).text.body.copyWith(
                        fontSize: 18, fontWeight: FontWeight.w700, height: 1.7),
                    children: [
                      const TextSpan(
                          text:
                              'Serious about meeting people? We can help you out with that! Toggling this switch '),
                      WidgetSpan(
                        child: SizedBox(
                          width: 23,
                          height: 28,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: IgnorePointer(
                              child: ToggleButton(
                                color:
                                    const Color.fromRGBO(0xFF, 0x86, 0x86, 1.0),
                                value: true,
                                useShadow: true,
                                onChanged: (_) {},
                              ),
                            ),
                          ),
                        ),
                      ),
                      const TextSpan(
                          text:
                              ' will only connect you with others who are serious about connecting too. When toggled, both parties are required to stay for the entire call. If any person leaves early they will be penalized from serious play for five minutes. We do this to help you find someone who is serious about finding others too.'),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 54),
            Padding(
              padding: const EdgeInsets.only(left: 125),
              child: Text(
                '- openup',
                style: Theming.of(context)
                    .text
                    .body
                    .copyWith(fontSize: 36, fontWeight: FontWeight.w700),
              ),
            ),
            const Spacer(),
          ],
        ),
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
