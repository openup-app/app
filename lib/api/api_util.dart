import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:image/image.dart' as img;
import 'package:openup/api/api.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/widgets/loading_dialog.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

void displayError(BuildContext context, ApiError error) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(errorToMessage(error)),
    ),
  );
}

String errorToMessage(ApiError error) {
  return error.map(
    network: (_) => 'Unable to connect to server',
    client: (client) {
      return client.error.map(
        badRequest: (_) => 'Failed to perform action',
        unauthorized: (_) => 'You are not logged in',
        notFound: (_) => 'Not found',
        forbidden: (_) => 'Something went wrong, access denied',
        conflict: (_) => 'Busy, try again',
      );
    },
    server: (_) => 'Something went wrong on our end, please try again',
  );
}

Future<Either<ApiError, void>> updateGender({
  required BuildContext context,
  required WidgetRef ref,
  required Gender gender,
}) async {
  final api = GetIt.instance.get<Api>();
  final userState = ref.read(userProvider);
  final newProfile = userState.profile!.copyWith(gender: gender);
  final result = await api.updateProfile(userState.uid, newProfile);

  if (result.isRight()) {
    ref.read(userProvider.notifier).profile(newProfile);
  }

  return result;
}

Future<Either<ApiError, String>> updateLocation({
  required BuildContext context,
  required Profile profile,
  required UserStateNotifier notifier,
  required double latitude,
  required double longitude,
}) async {
  final api = GetIt.instance.get<Api>();
  final result = await api.updateLocation(profile.uid, latitude, longitude);

  result.fold(
    (l) {},
    (r) {
      final newProfile = profile.copyWith(location: r);
      notifier.profile(newProfile);
    },
  );

  return result;
}

Future<Either<ApiError, void>> updateProfileCollection({
  required WidgetRef ref,
  required Collection collection,
}) async {
  final api = GetIt.instance.get<Api>();
  final userState = ref.read(userProvider);
  final newProfile = userState.profile!.copyWith(collection: collection);
  final result = await api.updateProfileCollection(
    collectionId: collection.collectionId,
    uid: ref.read(userProvider).uid,
  );

  if (result.isRight()) {
    ref.read(userProvider.notifier).profile(newProfile);
  }

  return result;
}

Future<Either<ApiError, void>> updateAudio({
  required BuildContext context,
  required WidgetRef ref,
  required Uint8List bytes,
}) async {
  final api = GetIt.instance.get<Api>();
  final userState = ref.read(userProvider);
  final result = await api.updateProfileAudio(userState.uid, bytes);

  result.fold(
    (l) {},
    (url) {
      final profile = userState.profile!.copyWith(audio: url);
      ref.read(userProvider.notifier).profile(profile);
    },
  );

  return result;
}

Future<Either<ApiError, Profile>> updatePhoto({
  required BuildContext context,
  required WidgetRef ref,
  required Uint8List bytes,
  required int index,
}) async {
  final api = GetIt.instance.get<Api>();
  final userState = ref.read(userProvider);
  final result =
      await api.updateProfileGalleryPhoto(userState.uid, bytes, index);

  result.fold(
    (l) {},
    (profile) => ref.read(userProvider.notifier).profile(profile),
  );

  return result;
}

Future<Either<ApiError, Profile>> deletePhoto({
  required BuildContext context,
  required WidgetRef ref,
  required int index,
}) async {
  final api = GetIt.instance.get<Api>();
  final userState = ref.read(userProvider);
  final result = await api.deleteProfileGalleryPhoto(userState.uid, index);

  result.fold(
    (l) {},
    (profile) => ref.read(userProvider.notifier).profile(profile),
  );

  return result;
}

Future<Either<ApiError, Collection>> uploadCollection({
  required List<File> photos,
  required File? audio,
  bool useAsProfile = false,
}) async {
  final photoBytes = await Future.wait(photos.map((f) => f.readAsBytes()));
  final images = await Future.wait(photoBytes.map(decodeImageFromList));
  final resized =
      await Future.wait(images.map((i) => _downscaleImage(i, 2000)));
  final jpgs = await Future.wait(resized.map(_encodeJpg));
  if (jpgs.contains(null)) {
    return Future.value(const Left(ApiError.client(ClientError.badRequest())));
  }
  final tempDir = await getTemporaryDirectory();

  final jpgFiles = <File>[];
  for (var i = 0; i < jpgs.length; i++) {
    final file =
        await File(path.join(tempDir.path, 'upload', 'collection_photo_$i.jpg'))
            .create(recursive: true);
    jpgFiles.add(await file.writeAsBytes(jpgs[i]!));
  }

  final api = GetIt.instance.get<Api>();
  return api.createCollection(
    jpgFiles.map((e) => e.path).toList(),
    audio?.path,
    useAsProfile: useAsProfile,
  );
}

Future<ui.Image> _downscaleImage(ui.Image image, int targetSide) async {
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
    img.Image.fromBytes(image.width, image.height, bytes),
    quality: quality,
  );
  return Uint8List.fromList(jpg);
}

Future<T> withBlockingModal<T>({
  required BuildContext context,
  required String label,
  required Future<T> future,
}) async {
  final popDialog = showBlockingModalDialog(
    context: context,
    builder: (context) {
      return Loading(
        title: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    },
  );

  final result = await future;
  popDialog();
  return result;
}
