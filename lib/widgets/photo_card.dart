import 'package:flutter/material.dart';

class PhotoCard extends StatelessWidget {
  final double width;
  final double height;
  final BoxDecoration? decoration;
  final Widget photo;
  final WidgetBuilder titleBuilder;
  final Widget? subtitle;
  final Widget firstButton;
  final Widget secondButton;
  final Widget indicatorButton;

  const PhotoCard({
    super.key,
    required this.width,
    required this.height,
    this.decoration,
    required this.photo,
    required this.titleBuilder,
    this.subtitle,
    required this.firstButton,
    required this.secondButton,
    required this.indicatorButton,
  });

  @override
  Widget build(BuildContext context) {
    const margin = 24.0;
    const topPadding = 20.0;
    const bottomHeight = 132.0;
    const leftPadding = 20.0;
    const rightPadding = 20.0;
    const requiredWidth = leftPadding + rightPadding;
    const requiredHeight = topPadding + bottomHeight;
    final availableWidth = width - requiredWidth - margin;
    final availableHeight = height - requiredHeight - margin;
    final availableAspect = availableWidth / availableHeight;
    const targetAspect = 17 / 23;

    final double outputWidth, outputHeight;
    if (availableAspect > targetAspect) {
      outputHeight = height;
      outputWidth = height * targetAspect;
    } else {
      outputWidth = width;
      outputHeight = width / targetAspect;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(margin),
        child: Container(
          width: outputWidth,
          height: outputHeight,
          decoration: decoration ?? const BoxDecoration(color: Colors.white),
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: leftPadding,
                    top: topPadding,
                    right: rightPadding,
                  ),
                  child: SizedBox.expand(child: photo),
                ),
              ),
              SizedBox(
                height: bottomHeight,
                child: Column(
                  children: [
                    const SizedBox(height: 11),
                    Padding(
                      padding: const EdgeInsets.only(
                        left: leftPadding,
                        right: rightPadding,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                DefaultTextStyle(
                                  style: const TextStyle(
                                    fontFamily: 'Covered By Your Grace',
                                    fontSize: 29,
                                    color:
                                        Color.fromRGBO(0x27, 0x27, 0x27, 1.0),
                                  ),
                                  child: Builder(
                                    builder: (context) {
                                      return titleBuilder(context);
                                    },
                                  ),
                                ),
                                if (subtitle != null)
                                  DefaultTextStyle(
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w300,
                                      color:
                                          Color.fromRGBO(0x27, 0x27, 0x27, 1.0),
                                    ),
                                    child: subtitle!,
                                  ),
                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                          indicatorButton,
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Divider(
                      height: 1,
                      color: Color.fromRGBO(0xD2, 0xD2, 0xD2, 1.0),
                    ),
                    SizedBox(
                      height: 50,
                      child: DefaultTextStyle(
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: firstButton,
                            ),
                            const VerticalDivider(
                              width: 1,
                              color: Color.fromRGBO(0xD2, 0xD2, 0xD2, 1.0),
                            ),
                            Expanded(
                              child: secondButton,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
