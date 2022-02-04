import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openup/api/users/profile.dart';
import 'package:openup/api/users/users_api.dart';
import 'package:openup/widgets/loading_dialog.dart';

Future<List<String>?> uploadPhoto({
  required BuildContext context,
  required Uint8List photo,
  required int index,
}) async {
  try {
    final profile = await _updateData(
      context: context,
      label: 'Uploading photo',
      request: (usersApi, uid) {
        return usersApi.updateGalleryPhoto(uid, photo, index);
      },
    );
    return profile?.gallery;
  } catch (e) {
    print(e);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Failed to add photo'),
      ),
    );
    return null;
  }
}

Future<List<String>?> deletePhoto({
  required BuildContext context,
  required int index,
}) async {
  try {
    final profile = await _updateData(
      context: context,
      label: 'Deleting photo',
      request: (usersApi, uid) {
        return usersApi.deleteGalleryPhoto(uid, index);
      },
    );
    return profile?.gallery;
  } catch (e) {
    print(e);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Failed to delete photo'),
      ),
    );
    return null;
  }
}

Future<String?> uploadAudio({
  required BuildContext context,
  required Uint8List audio,
}) async {
  try {
    final profile = await _updateData(
      context: context,
      label: 'Uploading audio',
      request: (usersApi, uid) {
        return usersApi.updateAudioBio(uid, audio);
      },
    );
    return profile?.audio;
  } catch (e) {
    print(e);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Failed to update audio'),
      ),
    );
    return null;
  }
}

Future<List<String>?> deleteAudio({required BuildContext context}) async {
  try {
    final profile = await _updateData(
      context: context,
      label: 'Deleting audio',
      request: (usersApi, uid) {
        return usersApi.deleteAudioBio(uid);
      },
    );
    return profile?.gallery;
  } catch (e) {
    print(e);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Failed to delete audio'),
      ),
    );
    return null;
  }
}

Future<void> updateName({
  required BuildContext context,
  required String name,
}) async {
  try {
    await _updateData(
      context: context,
      label: 'Updating profile',
      request: (usersApi, uid) {
        final profile = usersApi.publicProfile;
        if (profile != null) {
          return usersApi.updatePublicProfile(
            uid,
            profile.copyWith(name: name),
          );
        } else {
          return Future.value();
        }
      },
    );
  } catch (e) {
    print(e);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Failed to update profile'),
      ),
    );
  }
}

Future<PublicProfile?> _updateData({
  required BuildContext context,
  required String label,
  required Future<void> Function(UsersApi usersApi, String uid) request,
}) async {
  final auth = FirebaseAuth.instance;
  final uid = auth.currentUser?.uid;
  if (uid == null) {
    return null;
  }

  final popDialog = showBlockingModalDialog(
    context: context,
    builder: (context) {
      return Loading(
        title: Text(label),
      );
    },
  );

  final container = ProviderScope.containerOf(context);
  final usersApi = container.read(usersApiProvider);

  try {
    await request(usersApi, uid);
  } catch (e) {
    rethrow;
  }
  popDialog();

  return usersApi.publicProfile;
}
