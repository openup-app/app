import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

Future<File?> downscaleImage(File image, {int targetSize = 2000}) async {
  final imageBytes = await image.readAsBytes();
  final images = await decodeImageFromList(imageBytes);
  final resized = await _downscaleImage(images);
  final jpg = await _encodeJpg(resized);
  if (jpg == null) {
    return null;
  }
  final tempDir = await getTemporaryDirectory();
  final file = await File(
          path.join(tempDir.path, 'downscaled', path.basename(image.path)))
      .create(recursive: true);
  return file.writeAsBytes(jpg);
}

Future<ui.Image> _downscaleImage(
  ui.Image image, {
  int targetSide = 2000,
}) async {
  if (max(image.width, image.height) < targetSide) {
    return image;
  }

  final aspect = image.width / image.height;
  final int targetWidth;
  final int targetHeight;
  if (aspect < 1) {
    targetWidth = targetSide;
    targetHeight = targetWidth ~/ aspect;
  } else {
    targetHeight = targetSide;
    targetWidth = (targetHeight * aspect).toInt();
  }

  final pictureRecorder = ui.PictureRecorder();
  final canvas = ui.Canvas(pictureRecorder);
  canvas.drawImageRect(
    image,
    Offset.zero & Size(image.width.toDouble(), image.height.toDouble()),
    Offset.zero & Size(targetWidth.toDouble(), targetHeight.toDouble()),
    Paint(),
  );

  final picture = pictureRecorder.endRecording();
  return picture.toImage(targetWidth, targetHeight);
}

Future<Uint8List?> _encodeJpg(ui.Image image, {int quality = 80}) async {
  final bytes = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))
      ?.buffer
      .asUint8List();
  if (bytes == null) {
    return null;
  }

  final jpg = img.encodeJpg(
    img.Image.fromBytes(
      width: image.width,
      height: image.height,
      bytes: bytes.buffer,
      numChannels: 4,
      order: img.ChannelOrder.rgba,
    ),
    quality: quality,
  );
  return Uint8List.fromList(jpg);
}

Future<ui.Image> fetchImage(
  ImageProvider provider, {
  required Size size,
  required double pixelRatio,
}) {
  final completer = Completer<ui.Image>();
  final listener = ImageStreamListener((imageInfo, _) {
    completer.complete(imageInfo.image);
  }, onError: (error, stackTrace) {
    completer.completeError(error, stackTrace);
  });
  provider
      .resolve(ImageConfiguration(size: size, devicePixelRatio: pixelRatio))
      .addListener(listener);
  return completer.future;
}
