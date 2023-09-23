import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:openup/api/api.dart';
import 'package:openup/widgets/map_display.dart';
import 'package:openup/widgets/map_marker_rendering.dart';

part 'map_rendering.freezed.dart';

class MapRendering extends StatefulWidget {
  final List<EventMapItem> items;
  final EventMapItem? selectedItem;
  final int frameCount;
  final void Function(MarkerRenderStatus status) onMarkerRenderStatus;
  final Widget Function(BuildContext context, List<RenderedItem> renderedItems,
      RenderedItem? selectedRenderedItem) builder;

  const MapRendering({
    super.key,
    required this.items,
    required this.selectedItem,
    required this.frameCount,
    required this.onMarkerRenderStatus,
    required this.builder,
  });

  @override
  State<MapRendering> createState() => MapRenderingState();
}

class MapRenderingState extends State<MapRendering> {
  late final MarkerRenderingStateMachine _markerRenderStateMachine;

  CancelableOperation<List<Uint8List>>? _selectedRenderOp;

  List<RenderedItem> _renderedItems = [];
  RenderedItem? _renderedSelectedItem;

  @override
  void initState() {
    super.initState();

    _markerRenderStateMachine = MarkerRenderingStateMachine(
      onRenderStart: _onRenderStart,
      onRenderEnd: _onRenderEnd,
    );
  }

  @override
  void didUpdateWidget(covariant MapRendering oldWidget) {
    super.didUpdateWidget(oldWidget);
    _renderedItems.clear();

    // Animate selected item
    final selectedItem = widget.selectedItem;
    final oldSelectedItem = oldWidget.selectedItem;
    final selectedItemChanged = selectedItem?.id != oldSelectedItem?.id;
    final selectedItemFavoriteChanged =
        selectedItem?.id == oldSelectedItem?.id &&
            selectedItem?.favorite != oldSelectedItem?.favorite;

    final pixelRatio = MediaQuery.of(context).devicePixelRatio;

    if (selectedItem != null && selectedItemChanged) {
      // Render newly selected
      _selectedRenderOp?.cancel();
      final renderFuture = _renderMapMarker(
        event: selectedItem.event,
        pixelRatio: pixelRatio,
        selected: true,
      );
      _selectedRenderOp = CancelableOperation.fromFuture(renderFuture);
      _selectedRenderOp?.then((frames) {
        final stillSelected = widget.selectedItem?.id == selectedItem.id;
        if (mounted && stillSelected) {
          setState(() {
            _renderedSelectedItem = RenderedItem(
              item: selectedItem,
              frames: frames,
            );
          });
        }
      });
    } else if (selectedItem != null && selectedItemFavoriteChanged) {
      // Render selected with updated favorites icon
      final unselectedFramesFuture = _renderMapMarker(
        event: selectedItem.event,
        pixelRatio: pixelRatio,
        selected: false,
      );
      final selectedFramesFuture = _renderMapMarker(
        event: selectedItem.event,
        pixelRatio: pixelRatio,
        selected: true,
      );
      Future.wait([unselectedFramesFuture, selectedFramesFuture])
          .then((results) {
        if (mounted) {
          setState(() {
            _renderedSelectedItem = RenderedItem(
              item: selectedItem,
              frames: results[1],
            );
          });
        }
      });
    } else if (selectedItem == null && selectedItemChanged) {
      setState(() => _renderedSelectedItem = null);
    }

    _markerRenderStateMachine.itemsUpdated(items: widget.items);
  }

  @override
  void dispose() {
    _markerRenderStateMachine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(
      context,
      _renderedItems,
      widget.selectedItem == null ? null : _renderedSelectedItem,
    );
  }

  void resetMarkers() => _markerRenderStateMachine.reset();

  Future<List<RenderedItem>> _onRenderStart(List<MapItem> items) {
    if (!mounted) {
      return Future.value([]);
    }
    widget.onMarkerRenderStatus(MarkerRenderStatus.rendering);
    return _renderMapMarkers(items);
  }

  void _onRenderEnd(List<RenderedItem> renders) {
    if (!mounted) {
      return;
    }

    setState(() => _renderedItems = renders);
    widget.onMarkerRenderStatus(MarkerRenderStatus.ready);
  }

  Future<List<RenderedItem>> _renderMapMarkers(List<MapItem> inputItems) async {
    final items = inputItems.map((e) => e as EventMapItem).toList();
    final rendered = <RenderedItem>[];
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final frames = await _renderMapMarker(
        event: item.event,
        pixelRatio: pixelRatio,
        selected: false,
      );
      rendered.add(RenderedItem(item: item, frames: frames));
    }
    return rendered;
  }

  Future<List<Uint8List>> _renderMapMarker({
    required Event event,
    required double pixelRatio,
    required bool selected,
  }) async {
    return Future.wait([
      for (var i = 0; i < widget.frameCount; i++)
        Future.microtask(() {
          final t = i / (widget.frameCount - 1);
          final animation = CurveTween(
                  curve: selected ? Curves.easeOutQuart : Curves.bounceOut)
              .animate(AlwaysStoppedAnimation(t));
          final imageFuture = selected
              ? _renderSelectedMapMarkerFrame(event, pixelRatio, animation)
              : _renderMapMarkerFrame(event, pixelRatio, animation);
          return imageFuture.then((i) {
            return i.toByteData(format: ui.ImageByteFormat.png).then((b) {
              i.dispose();

              return b!.buffer.asUint8List();
            });
          });
        })
    ]);
  }

  Future<ui.Image> _renderMapMarkerFrame(
    Event event,
    double pixelRatio,
    Animation<double> animation,
  ) async {
    final textPainter = _createTextPainter(
      text: event.title.substring(0, min(event.title.length, 20)),
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: Colors.black,
      ),
    );
    final metrics = textPainter.computeLineMetrics()[0];

    final pictureRecorder = ui.PictureRecorder();
    final canvas = ui.Canvas(pictureRecorder);

    final textWidth = metrics.width;
    const horizontalPadding = 6.0;
    const verticalPadding = 16.0;
    const photoSize = 30.0;
    final width = photoSize + 4 + textWidth + horizontalPadding + 8;
    const height = photoSize + 4 + verticalPadding;

    final scaleAnimation = Matrix4.identity()
      ..translate(width / 2, height / 2)
      ..scale(animation.value)
      ..translate(-width / 2, -height / 2);
    canvas.scale(pixelRatio);
    canvas.transform(scaleAnimation.storage);

    _paintItemPill(
      canvas: canvas,
      textPainter: textPainter,
      metrics: metrics,
      backgroundColor: Colors.white,
      elevation: 4,
      shadowColor: const Color.fromRGBO(0x00, 0x00, 0x00, 0.5),
      horizontalPadding: horizontalPadding,
      verticalPadding: verticalPadding,
      width: width,
      height: height,
    );

    final picture = pictureRecorder.endRecording();
    return picture.toImage(
      (pixelRatio * width).toInt(),
      (pixelRatio * height).toInt(),
    );
  }

  Future<ui.Image> _renderSelectedMapMarkerFrame(
    Event event,
    double pixelRatio,
    Animation<double> animation,
  ) async {
    final textPainter = _createTextPainter(
      text: event.title.substring(0, min(event.title.length, 20)),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: ColorTween(begin: Colors.black, end: Colors.white)
            .evaluate(animation),
      ),
    );
    final metrics = textPainter.computeLineMetrics()[0];

    final pictureRecorder = ui.PictureRecorder();
    final canvas = ui.Canvas(pictureRecorder);

    final textWidth = metrics.width;
    const horizontalPadding = 16.0;
    const verticalPadding = 28.0;
    const photoSize = 36.0;
    final width = photoSize + textWidth + horizontalPadding + 8;
    const height = photoSize + verticalPadding;

    final scale = 1.0 + 0.33 * animation.value;

    final scaleAnimation = Matrix4.identity()
      ..translate(width * scale / 2, height * scale / 2)
      ..scale(scale)
      ..translate(-width / 2, -height / 2);
    canvas.scale(pixelRatio);
    canvas.transform(scaleAnimation.storage);

    _paintItemPill(
      canvas: canvas,
      textPainter: textPainter,
      metrics: metrics,
      backgroundColor: ColorTween(
        begin: Colors.white,
        end: const Color.fromRGBO(0x0A, 0x7B, 0xFF, 1.0),
      ).evaluate(animation)!,
      photoOutlineColor: ColorTween(
        begin: null,
        end: Colors.white,
      ).evaluate(animation),
      elevation: 8,
      shadowColor: Colors.black,
      horizontalPadding: horizontalPadding,
      verticalPadding: verticalPadding,
      width: width,
      height: height,
    );

    final picture = pictureRecorder.endRecording();
    return picture.toImage(
      (pixelRatio * width * scale).toInt(),
      (pixelRatio * height * scale).toInt(),
    );
  }

  void _paintItemPill({
    required Canvas canvas,
    required TextPainter textPainter,
    required ui.LineMetrics metrics,
    required Color backgroundColor,
    Color? photoOutlineColor,
    required double elevation,
    required Color shadowColor,
    required double horizontalPadding,
    required double verticalPadding,
    required double width,
    required double height,
  }) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(width / 2, height / 2),
        width: width - horizontalPadding,
        height: height - verticalPadding,
      ),
      Radius.circular((height - verticalPadding) / 2),
    );
    canvas.drawShadow(
      Path()..addRRect(rrect),
      shadowColor,
      elevation,
      false,
    );

    final extraPhotoPadding = photoOutlineColor == null ? 0 : 2;
    final photoSize = height - verticalPadding - 7 - extraPhotoPadding;
    final photoCenter = Offset(
      horizontalPadding / 2 + 3 + extraPhotoPadding + photoSize / 2,
      height / 2,
    );

    canvas.drawRRect(rrect, Paint()..color = backgroundColor);
    final textLeftPadding = photoCenter.dx + photoSize / 2 + 4;
    final textTopPadding = (height - metrics.height) / 2;
    textPainter.paint(
      canvas,
      Offset(textLeftPadding, textTopPadding),
    );

    if (photoOutlineColor != null) {
      canvas.drawCircle(
        photoCenter,
        photoSize / 2 + 1.5,
        Paint()..color = photoOutlineColor,
      );
    }

    canvas.clipPath(
      Path()
        ..addOval(Rect.fromCenter(
          center: photoCenter,
          width: photoSize,
          height: photoSize,
        )),
    );
  }

  TextPainter _createTextPainter({
    required String text,
    required TextStyle style,
    double maxWidth = 200,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: style,
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: maxWidth);
    return textPainter;
  }
}

enum MarkerRenderStatus { ready, rendering }

@freezed
class EventMapItem with _$EventMapItem implements MapItem {
  const factory EventMapItem(Event event) = _MapItem;

  const EventMapItem._();

  @override
  int get id => event.id.hashCode;

  @override
  bool get favorite => false;

  @override
  LatLong get latLong => event.location.latLong;
}
