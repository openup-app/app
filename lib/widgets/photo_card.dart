import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:openup/widgets/common.dart';

class PhotoCard extends StatelessWidget {
  final double width;
  final double height;
  final bool useExtraTopPadding;
  final BoxDecoration? decoration;
  final Widget photo;
  final WidgetBuilder titleBuilder;
  final Widget? subtitle;
  final Widget? firstButton;
  final Widget? secondButton;
  final Widget indicatorButton;

  const PhotoCard({
    super.key,
    required this.width,
    required this.height,
    this.useExtraTopPadding = false,
    this.decoration,
    required this.photo,
    required this.titleBuilder,
    this.subtitle,
    this.firstButton,
    this.secondButton,
    required this.indicatorButton,
  });

  @override
  Widget build(BuildContext context) {
    const margin = 24.0;
    const doubleMargin = margin * 2;
    final topPadding = 16.0 + (useExtraTopPadding ? 16.0 : 0.0);
    final bottomHeight =
        (firstButton != null && secondButton != null) ? 140.0 : 72.0;
    const horizontalPadding = 32.0;
    final verticalPadding = topPadding + bottomHeight;
    final maxContentsWidth = width - horizontalPadding - doubleMargin;
    final maxContentsHeight = height - verticalPadding - doubleMargin;

    final availableAspect = maxContentsWidth / maxContentsHeight;
    const targetAspect = 3 / 4;
    final double outputWidth, outputHeight;

    if (availableAspect > targetAspect) {
      outputHeight = height - doubleMargin;
      outputWidth = maxContentsHeight * targetAspect + horizontalPadding;
    } else {
      outputWidth = width - doubleMargin;
      outputHeight = maxContentsWidth / targetAspect + verticalPadding;
    }
    final contentWidth = outputWidth - horizontalPadding;
    final contentHeight = outputHeight - verticalPadding;

    return Center(
      child: Container(
        width: outputWidth,
        height: outputHeight,
        margin: const EdgeInsets.all(margin),
        clipBehavior: Clip.hardEdge,
        decoration: decoration ?? const BoxDecoration(color: Colors.white),
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  left: horizontalPadding / 2,
                  top: topPadding,
                  right: horizontalPadding / 2,
                ),
                child: SizedBox(
                  width: contentWidth,
                  height: contentHeight,
                  child: AspectRatio(
                    aspectRatio: targetAspect,
                    child: photo,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: bottomHeight,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: horizontalPadding / 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              DefaultTextStyle(
                                style: const TextStyle(
                                  fontFamily: 'Covered By Your Grace',
                                  fontSize: 34,
                                  color: Color.fromRGBO(0x27, 0x27, 0x27, 1.0),
                                ),
                                child: Builder(
                                  builder: (context) {
                                    return titleBuilder(context);
                                  },
                                ),
                              ),
                              if (subtitle != null)
                                DefaultTextStyle.merge(
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w300,
                                    color:
                                        Color.fromRGBO(0x45, 0x45, 0x45, 1.0),
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
                  if (firstButton != null && secondButton != null) ...[
                    const Divider(
                      height: 1,
                      color: Color.fromRGBO(0xD2, 0xD2, 0xD2, 1.0),
                    ),
                    SizedBox(
                      height: 50,
                      child: DefaultTextStyle.merge(
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: firstButton!,
                            ),
                            const VerticalDivider(
                              width: 1,
                              color: Color.fromRGBO(0xD2, 0xD2, 0xD2, 1.0),
                            ),
                            Expanded(
                              child: secondButton!,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PhotoCardLoading extends StatelessWidget {
  final double width;
  final double height;
  final bool useExtraTopPadding;

  const PhotoCardLoading({
    super.key,
    required this.width,
    required this.height,
    this.useExtraTopPadding = false,
  });

  @override
  Widget build(BuildContext context) {
    return PhotoCard(
      width: width,
      height: height,
      useExtraTopPadding: useExtraTopPadding,
      photo: const ShimmerLoading(
        isLoading: true,
        child: ColoredBox(
          color: Colors.black,
        ),
      ),
      titleBuilder: (_) {
        return ShimmerLoading(
          isLoading: true,
          child: Container(
            width: double.infinity,
            height: 24,
            margin: const EdgeInsets.only(right: 16, top: 5),
            decoration: const BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.all(
                Radius.circular(10),
              ),
            ),
          ),
        );
      },
      subtitle: ShimmerLoading(
        isLoading: true,
        child: Container(
          width: double.infinity,
          height: 16,
          margin: const EdgeInsets.only(top: 12, right: 16, bottom: 2),
          decoration: const BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.all(
              Radius.circular(6),
            ),
          ),
        ),
      ),
      firstButton: const ShimmerLoading(
        isLoading: true,
        child: Center(
          child: SizedBox(
            width: 100,
            height: 16,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.all(
                  Radius.circular(10),
                ),
              ),
            ),
          ),
        ),
      ),
      secondButton: const ShimmerLoading(
        isLoading: true,
        child: Center(
          child: SizedBox(
            width: 100,
            height: 16,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.all(
                  Radius.circular(10),
                ),
              ),
            ),
          ),
        ),
      ),
      indicatorButton: ShimmerLoading(
        isLoading: true,
        child: Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: Colors.black,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class SimplePhotoCard extends StatelessWidget {
  final Widget contents;
  final Widget? title;
  final Widget? trailing;

  const SimplePhotoCard({
    super.key,
    required this.contents,
    this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 14, right: 14, top: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(1)),
      ),
      child: Column(
        children: [
          Expanded(
            child: AspectRatio(
              aspectRatio: 3 / 4,
              child: contents,
            ),
          ),
          SizedBox(
            height: 56,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Container(
                color: Colors.pink,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: DefaultTextStyle(
                        style: const TextStyle(
                          fontFamily: 'Covered By Your Grace',
                          fontSize: 34,
                          color: Color.fromRGBO(0x27, 0x27, 0x27, 1.0),
                        ),
                        child: title ?? const SizedBox.shrink(),
                      ),
                    ),
                    if (trailing != null) trailing!,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Silhouette extends SingleChildRenderObjectWidget {
  const _Silhouette({
    Key? key,
    required Widget child,
  }) : super(child: child);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderProfile();
  }
}

class _RenderProfile extends RenderProxyBox {
  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    canvas.clipRect(offset & size);
    // Solid black fill is the destination
    canvas.drawPaint(Paint()..color = Colors.black);
    // Cut out the child's silhouette
    canvas.saveLayer(
      offset & size,
      Paint()..blendMode = BlendMode.dstOut,
    );
    super.paint(context, offset);
    canvas.restore();
  }
}
