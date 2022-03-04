import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/api/users/profile.dart';
import 'package:openup/widgets/loading_dialog.dart';

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
        forbidden: (_) => 'Something went wrong',
      );
    },
    server: (_) => 'Something went wrong on our end, please try again',
  );
}

Future<Either<ApiError, void>> updateName({
  required BuildContext context,
  required WidgetRef ref,
  required String name,
}) async {
  final api = GetIt.instance.get<Api>();
  final userState = ref.read(userProvider);
  final newProfile = userState.profile!.copyWith(name: name);
  final result = await api.updateProfile(userState.uid, newProfile);

  if (result.isRight()) {
    ref
        .read(userProvider.notifier)
        .update(userState.copyWith(profile: newProfile));
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
      ref
          .read(userProvider.notifier)
          .update(userState.copyWith(profile: profile));
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
    (profile) {
      ref
          .read(userProvider.notifier)
          .update(userState.copyWith(profile: profile));
    },
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
    (profile) {
      ref
          .read(userProvider.notifier)
          .update(userState.copyWith(profile: profile));
    },
  );

  return result;
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
        title: Text(label),
      );
    },
  );

  final result = await future;
  popDialog();
  return result;
}
