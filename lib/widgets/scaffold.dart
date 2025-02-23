import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/restart_app.dart';

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
  final EdgeInsets leadingPadding;
  final EdgeInsets trailingPadding;

  const OpenupAppBarBody({
    super.key,
    this.leading,
    this.center,
    this.trailing,
    this.leadingPadding = EdgeInsets.zero,
    this.trailingPadding = const EdgeInsets.all(8),
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (leading != null)
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: leadingPadding,
              child: leading,
            ),
          ),
        if (center != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48.0),
            child: DefaultTextStyle(
              style: const TextStyle(
                fontFamily: 'Covered By Your Grace',
                fontSize: 24,
                height: 1.1,
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
              padding: trailingPadding,
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: RotatedBox(
          quarterTurns: 2,
          child: SvgPicture.asset(
            'assets/images/chevron_right.svg',
            colorFilter: const ColorFilter.mode(
              Color.fromRGBO(0x00, 0x7C, 0xEE, 1.0),
              BlendMode.srcIn,
            ),
            height: 24,
          ),
        ),
      ),
    );
  }
}

class OpenupAppBarBackButtonOutlined extends StatelessWidget {
  final Color iconColor;
  final Color backgroundColor;
  final EdgeInsets padding;

  const OpenupAppBarBackButtonOutlined({
    super.key,
    this.iconColor = Colors.black,
    this.backgroundColor = Colors.white,
    this.padding = const EdgeInsets.only(left: 8),
  });

  @override
  Widget build(BuildContext context) {
    return Button(
      onPressed: () {
        if (context.canPop()) {
          Navigator.of(context).pop();
        } else {
          RestartApp.restartApp(context);
        }
      },
      child: Padding(
        padding: padding,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SizedBox(
            width: 33,
            height: 33,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: backgroundColor,
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: RotatedBox(
                  quarterTurns: 2,
                  child: SvgPicture.asset(
                    'assets/images/chevron_right.svg',
                    colorFilter: ColorFilter.mode(
                      iconColor,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class OpenupAppBarCloseButton extends StatelessWidget {
  const OpenupAppBarCloseButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Button(
      onPressed: Navigator.of(context).pop,
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(
          'Close',
          style: TextStyle(
            color: Color.fromRGBO(0x00, 0x7C, 0xEE, 1.0),
          ),
        ),
      ),
    );
  }
}

class OpenupAppBarTextButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;

  const OpenupAppBarTextButton({
    super.key,
    this.onPressed,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Button(
      onPressed: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w300,
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
      darkTop: false,
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
  final bool darkTop;

  const _BlurredBackground({
    super.key,
    required this.child,
    this.darkTop = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: darkTop ? Alignment.topCenter : Alignment.bottomCenter,
          end: darkTop ? Alignment.bottomCenter : Alignment.topCenter,
          colors: const [
            Color.fromRGBO(0x00, 0x00, 0x00, 0.8),
            Color.fromRGBO(0x00, 0x00, 0x00, 0.3),
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
