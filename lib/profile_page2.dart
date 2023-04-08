import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/view_collection_page.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/collection_photo_picker.dart';
import 'package:openup/widgets/collection_photo_stack.dart';
import 'package:openup/widgets/collections_preview_list.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/image_builder.dart';
import 'package:openup/widgets/profile_display.dart';
import 'package:openup/widgets/screenshot.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class ProfilePage2 extends ConsumerStatefulWidget {
  const ProfilePage2({super.key});

  @override
  ConsumerState<ProfilePage2> createState() => _ProfilePage2State();
}

class _ProfilePage2State extends ConsumerState<ProfilePage2> {
  bool _showCollectionCreation = false;

  final _screenshotController = ScreenshotController();

  @override
  Widget build(BuildContext context) {
    final loggedIn = FirebaseAuth.instance.currentUser != null;
    return Screenshot(
      controller: _screenshotController,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            Builder(
              builder: (context) {
                if (!loggedIn) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Log in to create a profile'),
                        ElevatedButton(
                          onPressed: () => context.pushNamed('signup'),
                          child: const Text('Log in'),
                        ),
                      ],
                    ),
                  );
                }

                final profile =
                    ref.watch(userProvider.select((p) => p.profile));
                if (profile == null) {
                  return const Center(
                    child: LoadingIndicator(),
                  );
                }

                return Column(
                  children: [
                    Expanded(
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Image.network(
                              profile.collection.photos.first.url,
                              fit: BoxFit.cover,
                              loadingBuilder: loadingBuilder,
                              errorBuilder: iconErrorBuilder,
                            ),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 12 + MediaQuery.of(context).padding.bottom,
                            height: 189,
                            child: Builder(
                              builder: (context) {
                                final collections = ref.watch(
                                    userProvider.select((p) => p.collections));
                                return CollectionsPreviewList(
                                    collections: collections,
                                    play: _showCollectionCreation == false,
                                    leadingChildren: [
                                      _BottomButton(
                                        label: 'Create Collection',
                                        icon: const Icon(Icons.upload),
                                        onPressed: () => setState(() =>
                                            _showCollectionCreation = true),
                                      ),
                                    ],
                                    onView: (index) {
                                      context.pushNamed(
                                        'view_collection',
                                        extra:
                                            ViewCollectionPageArguments.profile(
                                          profile: profile,
                                          collections: collections,
                                          index: index,
                                        ),
                                      );
                                    },
                                    onLongPress: (index) =>
                                        _showDeleteDialog(collections[index]));
                              },
                            ),
                          ),
                          if (_showCollectionCreation)
                            _CollectionCreation(
                              onCreated: (collection) {
                                final collections = ref.read(
                                    userProvider.select((p) => p.collections));
                                final newCollections = List.of(collections)
                                  ..insert(0, collection);
                                ref
                                    .read(userProvider.notifier)
                                    .collections(newCollections);
                                setState(() => _showCollectionCreation = false);
                              },
                              onCancel: () => setState(
                                  () => _showCollectionCreation = false),
                            ),
                        ],
                      ),
                    ),
                    UserNameAndRecordButton(
                      profile: profile,
                      recordButtonLabel: 'Update Voice Bio',
                      onRecordPressed: () async {
                        final audio = await _showRecordPanel(context);
                        if (mounted && audio != null) {
                          _upload(audio);
                        }
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<File?> _showRecordPanel(BuildContext context) async {
    final audio = await showModalBottomSheet<Uint8List>(
      backgroundColor: Colors.transparent,
      context: context,
      builder: (context) {
        return Surface(
          child: RecordPanelContents(
            onSubmit: (audio, duration) => Navigator.of(context).pop(audio),
          ),
        );
      },
    );

    if (audio == null || !mounted) {
      return null;
    }

    final tempDir = await getTemporaryDirectory();
    final file = await File(path.join(
            tempDir.path, 'audio_bio_${DateTime.now().toIso8601String()}.m4a'))
        .create();
    return file.writeAsBytes(audio);
  }

  void _upload(File audio) async {
    final api = GetIt.instance.get<Api>();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return null;
    }

    final result = await withBlockingModal(
      context: context,
      label: 'Uploading voice bio...',
      future: api.updateProfileAudio(uid, await audio.readAsBytes()),
    );

    if (!mounted) {
      return;
    }

    result.fold(
      (l) => displayError(context, l),
      (r) {
        showCupertinoDialog(
          context: context,
          builder: (context) {
            return CupertinoAlertDialog(
              title: const Text('Successfully uploaded void bio'),
              actions: [
                CupertinoDialogAction(
                  onPressed: Navigator.of(context).pop,
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteDialog(Collection collection) async {
    final result = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text('Delete collection?'),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(true),
              isDestructiveAction: true,
              child: const Text('Delete'),
            ),
            CupertinoDialogAction(
              onPressed: Navigator.of(context).pop,
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
    if (result == true && mounted) {
      _deleteCollection(collection);
    }
  }

  void _deleteCollection(Collection collection) {
    GetIt.instance.get<Api>().deleteCollection(collection.collectionId);
    final collections = ref.read(userProvider.select((p) => p.collections));
    final newCollections = List.of(collections)
      ..removeWhere((c) => c == collection);
    ref.read(userProvider.notifier).collections(newCollections);
  }
}

class _BottomButton extends StatelessWidget {
  final String label;
  final Icon icon;
  final VoidCallback? onPressed;
  const _BottomButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Button(
      onPressed: onPressed,
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.start,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium!
                      .copyWith(fontSize: 15, fontWeight: FontWeight.w400),
                ),
              ),
              const SizedBox(width: 4),
              icon,
            ],
          ),
        ),
      ),
    );
  }
}

class _CollectionCreation extends StatefulWidget {
  final void Function(Collection collection) onCreated;
  final VoidCallback onCancel;

  const _CollectionCreation({
    super.key,
    required this.onCreated,
    required this.onCancel,
  });

  @override
  State<_CollectionCreation> createState() => __CollectionCreationState();
}

class __CollectionCreationState extends State<_CollectionCreation> {
  final _photos = <File>[];
  File? _audio;
  _CreationStep _step = _CreationStep.photos;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        widget.onCancel();
        return Future.value(false);
      },
      child: BlurredSurface(
        blur: 25,
        child: Column(
          children: [
            SizedBox(height: MediaQuery.of(context).padding.top),
            const SizedBox(height: 16),
            SizedBox(
              height: 40,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Button(
                        onPressed: () {
                          switch (_step) {
                            case _CreationStep.photos:
                              widget.onCancel();
                              break;
                            case _CreationStep.audio:
                              setState(() => _step = _CreationStep.photos);
                              break;
                            case _CreationStep.upload:
                              setState(() => _step = _CreationStep.audio);
                              break;
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_step != _CreationStep.photos) ...[
                                const Icon(Icons.chevron_left),
                                const SizedBox(width: 8),
                              ],
                              Text(
                                _step == _CreationStep.photos
                                    ? 'Cancel'
                                    : 'Back',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium!
                                    .copyWith(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (_step == _CreationStep.photos)
                      Center(
                        child: Text(
                          '${_photos.length}/3',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium!
                              .copyWith(
                                  fontSize: 16, fontWeight: FontWeight.w400),
                        ),
                      ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Visibility(
                        visible: _step != _CreationStep.upload,
                        child: Button(
                          onPressed: _photos.isEmpty
                              ? null
                              : () {
                                  switch (_step) {
                                    case _CreationStep.photos:
                                      setState(
                                          () => _step = _CreationStep.audio);
                                      break;
                                    case _CreationStep.audio:
                                      setState(
                                          () => _step = _CreationStep.upload);
                                      break;
                                    case _CreationStep.upload:
                                      // Ignore
                                      break;
                                  }
                                },
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Next',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium!
                                      .copyWith(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w400),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.chevron_right),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Builder(
                builder: (context) {
                  switch (_step) {
                    case _CreationStep.photos:
                      return CollectionPhotoPicker(
                        photos: _photos,
                        onPhotosUpdated: (photos) {
                          setState(() => _photos
                            ..clear()
                            ..addAll(photos));
                        },
                        belowPhotoLabel:
                            'hold down image to remove from collection',
                        aboveGalleryLabel:
                            'Add up to three photos in a collection',
                      );
                    case _CreationStep.audio:
                      return _AudioStep(
                        photos: _photos,
                        onAudio: (audio) => setState(() => _audio = audio),
                      );
                    case _CreationStep.upload:
                      return _UploadStep(
                        photos: _photos,
                        onUpload: _uploadCollection,
                        onDelete: widget.onCancel,
                      );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _uploadCollection() async {
    final result = await withBlockingModal(
      context: context,
      label: 'Uploading',
      future: uploadCollection(
        context: context,
        photos: _photos,
        audio: _audio,
      ),
    );
    if (!mounted) {
      return;
    }

    if (result == null) {
      return;
    }

    result.fold(
      (l) => displayError(context, l),
      (r) {
        showCupertinoDialog(
          context: context,
          builder: (context) {
            return CupertinoAlertDialog(
              title: const Text('Collection uploaded'),
              content: const Text(
                  'You will be notified when it has finished processing'),
              actions: [
                CupertinoDialogAction(
                  onPressed: Navigator.of(context).pop,
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );

        if (mounted) {
          widget.onCreated(r);
        }
      },
    );
  }
}

class _AudioStep extends StatefulWidget {
  final List<File> photos;
  final void Function(File audio) onAudio;
  const _AudioStep({
    super.key,
    required this.photos,
    required this.onAudio,
  });

  @override
  State<_AudioStep> createState() => _AudioStepState();
}

class _AudioStepState extends State<_AudioStep> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        SizedBox(
          width: 249,
          child: Text(
            'Want to say something\nabout this collection?',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                fontSize: 20, fontWeight: FontWeight.w500, height: 1.5),
          ),
        ),
        Expanded(
          child: CollectionPhotoStack(
            photos: widget.photos,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Button(
                onPressed: () async {
                  final result = await _showRecordPanel(context);
                  if (result != null) {
                    widget.onAudio(result);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 4.0, horizontal: 8.0),
                  decoration: const BoxDecoration(
                    color: Color.fromRGBO(0x80, 0x0B, 0x06, 1.0),
                    borderRadius: BorderRadius.all(Radius.circular(6)),
                  ),
                  child: Text(
                    'Record',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium!
                        .copyWith(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
              )
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.only(
            left: 8,
            right: 8,
            top: 8,
            bottom: 8 + MediaQuery.of(context).padding.bottom,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 346),
            child: Text(
              'A professional photographer will check your images and make sure they are edited to the highest quality. We will have this collection up as soon as possible.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontSize: 13, fontWeight: FontWeight.w500, height: 1.7),
            ),
          ),
        )
      ],
    );
  }

  Future<File?> _showRecordPanel(BuildContext context) async {
    final audio = await showModalBottomSheet<Uint8List>(
      backgroundColor: Colors.transparent,
      context: context,
      builder: (context) {
        return Surface(
          child: RecordPanelContents(
            onSubmit: (audio, duration) => Navigator.of(context).pop(audio),
          ),
        );
      },
    );

    if (audio == null || !mounted) {
      return null;
    }

    final tempDir = await getTemporaryDirectory();
    final file = File(path.join(tempDir.path, 'collection_audio.m4a'));
    await file.writeAsBytes(audio);
    return file;
  }
}

class _UploadStep extends StatelessWidget {
  final List<File> photos;
  final VoidCallback onUpload;
  final VoidCallback onDelete;

  const _UploadStep({
    super.key,
    required this.photos,
    required this.onUpload,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        SizedBox(
          width: 249,
          child: Text(
            'Upload as a new\ncollection?',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                fontSize: 20, fontWeight: FontWeight.w500, height: 1.5),
          ),
        ),
        Expanded(
          child: CollectionPhotoStack(
            photos: photos,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Button(
                onPressed: onDelete,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 4.0, horizontal: 8.0),
                  child: Text(
                    'Delete',
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: const Color.fromRGBO(0xFF, 0x00, 0x00, 1.0),
                        fontSize: 16,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              const SizedBox(width: 100),
              Button(
                onPressed: onUpload,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color.fromRGBO(0xFF, 0xFF, 0xFF, 0.5),
                    borderRadius: BorderRadius.all(Radius.circular(6)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 4.0, horizontal: 8.0),
                    child: Text(
                      'Upload',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium!
                          .copyWith(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.only(
            left: 8,
            right: 8,
            top: 8,
            bottom: 8 + MediaQuery.of(context).padding.bottom,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 346),
            child: Text(
              'A professional photographer will check your images and make sure they are edited to the highest quality. We will have this collection up as soon as possible.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontSize: 13, fontWeight: FontWeight.w500, height: 1.7),
            ),
          ),
        )
      ],
    );
  }
}

enum _CreationStep { photos, audio, upload }
