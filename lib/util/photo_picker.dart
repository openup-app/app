import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

Future<File?> selectPhoto(
  BuildContext context, {
  String? label,
}) async {
  final source = await showCupertinoDialog<ImageSource>(
    context: context,
    builder: (context) {
      return CupertinoAlertDialog(
        title: const Text('Pick a photo'),
        content: label == null ? null : Text(label),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(ImageSource.camera),
            child: const Text('Take new photo'),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(ImageSource.gallery),
            child: const Text('Pick from Gallery'),
          ),
          CupertinoDialogAction(
            onPressed: Navigator.of(context).pop,
            child: const Text('Cancel'),
          ),
        ],
      );
    },
  );
  if (source == null) {
    return null;
  }

  final picker = ImagePicker();
  XFile? result;
  try {
    if (source == ImageSource.camera) {
      await Permission.camera.request();
    }
    result = await picker.pickImage(source: source);
  } on PlatformException catch (e) {
    if (e.code == 'camera_access_denied') {
      result = null;
    } else {
      rethrow;
    }
  }
  if (result == null) {
    return null;
  }

  return File(result.path);
}

Future<List<File>?> selectPhotos(
  BuildContext context, {
  String? label,
}) async {
  final source = await showCupertinoDialog<ImageSource>(
    context: context,
    builder: (context) {
      return CupertinoAlertDialog(
        title: const Text('Pick a photo'),
        content: label == null ? null : Text(label),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(ImageSource.camera),
            child: const Text('Take new photo'),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(ImageSource.gallery),
            child: const Text('Pick from Gallery'),
          ),
          CupertinoDialogAction(
            onPressed: Navigator.of(context).pop,
            child: const Text('Cancel'),
          ),
        ],
      );
    },
  );
  if (!context.mounted || source == null) {
    return null;
  }

  final picker = ImagePicker();
  List<XFile>? result;
  try {
    if (source == ImageSource.camera) {
      await Permission.camera.request();
      final image = await picker.pickImage(source: source);
      if (image != null) {
        result = [image];
      }
    } else {
      result = await picker.pickMultiImage();
    }
  } on PlatformException catch (e) {
    if (e.code == 'camera_access_denied') {
      result = null;
    } else {
      rethrow;
    }
  }
  if (!context.mounted || result == null) {
    return null;
  }

  return result.map((e) => File(e.path)).toList();
}
