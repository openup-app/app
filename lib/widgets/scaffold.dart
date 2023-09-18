import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:openup/widgets/button.dart';

class OpenupAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget body;
  final Widget? toolbar;
  final bool blurBackground;

  const OpenupAppBar({
    super.key,
    required this.body,
    this.toolbar,
    this.blurBackground = true,
  });

  @override
  Size get preferredSize =>
      Size.fromHeight(48.0 + (toolbar == null ? 8.0 : 44.0));

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SizedBox(
          height: 48,
          child: body,
        ),
        if (toolbar != null) toolbar!,
        if (toolbar == null) const SizedBox(height: 8),
      ],
    );
    if (blurBackground) {
      return _BlurredBackground(
        child: content,
      );
    } else {
      return content;
    }
  }
}

class OpenupAppBarBody extends StatelessWidget {
  final Widget? leading;
  final Widget? center;
  final Widget? trailing;

  const OpenupAppBarBody({
    super.key,
    this.leading,
    this.center,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (leading != null)
          Align(
            alignment: Alignment.centerLeft,
            child: leading,
          ),
        if (center != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48.0),
            child: DefaultTextStyle(
              style: const TextStyle(
                fontFamily: 'Covered By Your Grace',
                fontSize: 24,
                fontWeight: FontWeight.w400,
                color: Colors.white,
              ),
              child: center!,
            ),
          ),
        if (trailing != null)
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: trailing,
            ),
          ),
      ],
    );
  }
}

class OpenupAppBarBackButton extends StatelessWidget {
  const OpenupAppBarBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Button(
      onPressed: Navigator.of(context).pop,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: RotatedBox(
          quarterTurns: 2,
          child: SvgPicture.asset(
            'assets/images/chevron_right.svg',
            colorFilter: const ColorFilter.mode(
              Color.fromRGBO(0x00, 0x7C, 0xEE, 1.0),
              BlendMode.srcIn,
            ),
            height: 28,
          ),
        ),
      ),
    );
  }
}

class OpenupBottomBar extends StatelessWidget {
  final Widget child;

  const OpenupBottomBar({
    super.key,
    required this.child,
  });

  /// Height of the bottom bar before system padding is applied.
  static const kBaseHeight = 80.0;

  @override
  Widget build(BuildContext context) {
    return _BlurredBackground(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        child: SizedBox(
          height: kBaseHeight,
          child: child,
        ),
      ),
    );
  }
}

class _BlurredBackground extends StatelessWidget {
  final Widget child;

  const _BlurredBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.fromRGBO(0xD9, 0xD9, 0xD9, 0.05),
            Color.fromRGBO(0x3D, 0x3D, 0x3D, 0.05),
          ],
        ),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 30,
          sigmaY: 30,
          tileMode: TileMode.mirror,
        ),
        child: child,
      ),
    );
  }
}
