import 'dart:ui';

import 'package:flutter/material.dart';

class TextBackground extends StatelessWidget {
  final Widget child;

  const TextBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ColoredBox(
          color: Colors.black,
          child: Stack(
            fit: StackFit.expand,
            alignment: Alignment.center,
            children: [
              RepaintBoundary(
                child: OverflowBox(
                  minWidth: constraints.maxWidth * 1.3,
                  minHeight: constraints.maxHeight * 1.3,
                  maxWidth: constraints.maxWidth * 1.3,
                  maxHeight: constraints.maxHeight * 1.3,
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(
                      sigmaX: 12,
                      sigmaY: 12,
                      tileMode: TileMode.decal,
                    ),
                    child: DefaultTextStyle.merge(
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.visible,
                      maxLines: 1,
                      softWrap: false,
                      style: const TextStyle(
                        fontSize: 90,
                        fontWeight: FontWeight.w400,
                        color: Color.fromRGBO(0xFF, 0xFF, 0xFF, 0.5),
                      ),
                      child: Column(
                        children: [
                          SizedBox(height: MediaQuery.of(context).padding.top),
                          SizedBox(height: constraints.maxHeight * 0.15),
                          const Text('EVERYONE'),
                          const Spacer(),
                          const Text('NEEDS AN'),
                          const Spacer(),
                          const Text('ICE BREAKER'),
                          SizedBox(height: constraints.maxHeight * 0.15),
                          SizedBox(
                              height: MediaQuery.of(context).padding.bottom),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              child,
            ],
          ),
        );
      },
    );
  }
}
