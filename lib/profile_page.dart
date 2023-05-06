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
import 'package:openup/widgets/gallery.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePage2State();
}

class _ProfilePage2State extends ConsumerState<ProfilePage> {
  bool _showCollectionCreation = false;
  final _nameController = TextEditingController();
  bool _initial = true;

  @override
  void initState() {
    super.initState();
    ref.listenManual<UserState2?>(
      userProvider2,
      (previous, next) {
        if (_initial && next != null) {
          next.map(
            guest: (_) {},
            signedIn: (signedIn) {
              _initial = false;
              _nameController.text = signedIn.profile.name;
            },
          );
        }
      },
      fireImmediately: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ref.watch(userProvider2).map(
      guest: (_) {
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
      },
      signedIn: (signedIn) {
        final profile = signedIn.profile;
        return Container(
          margin: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 24 + MediaQuery.of(context).padding.top,
            bottom: 16 + MediaQuery.of(context).padding.bottom,
          ),
          clipBehavior: Clip.hardEdge,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(48)),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: Builder(
                  builder: (context) {
                    if (!_showCollectionCreation) {
                      return Column(
                        children: [
                          Container(
                            height: constraints.maxHeight,
                            clipBehavior: Clip.hardEdge,
                            decoration: const BoxDecoration(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(48)),
                            ),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: CinematicGallery(
                                    slideshow: true,
                                    gallery: profile.collection.photos,
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 30),
                                    child: Button(
                                      onPressed: () async {
                                        final audio =
                                            await _showRecordPanel(context);
                                        if (mounted && audio != null) {
                                          _upload(audio);
                                        }
                                      },
                                      child: Container(
                                        width: 146,
                                        height: 51,
                                        alignment: Alignment.center,
                                        decoration: const BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Color.fromRGBO(
                                                  0xF3, 0x49, 0x50, 1.0),
                                              Color.fromRGBO(
                                                  0xDF, 0x39, 0x3F, 1.0),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(25)),
                                          boxShadow: [
                                            BoxShadow(
                                              offset: Offset(0, 4),
                                              blurRadius: 4,
                                              color: Color.fromRGBO(
                                                  0x00, 0x00, 0x00, 0.25),
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          'update bio',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium!
                                              .copyWith(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w400,
                                                  color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 189,
                            child: Builder(
                              builder: (context) {
                                final collections = signedIn.collections ?? [];
                                return CollectionsPreviewList(
                                  collections: collections,
                                  play: _showCollectionCreation == false,
                                  leadingChildren: [
                                    _BottomButton(
                                      label: 'Create Collection',
                                      icon: const Icon(Icons.collections),
                                      onPressed: () => setState(
                                          () => _showCollectionCreation = true),
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
                                  onLongPress: (index) => _showDeleteDialog(
                                      collections[index].collectionId),
                                );
                              },
                            ),
                          ),
                          const _SectionTitle(label: 'Name'),
                          Container(
                            height: 42,
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.all(
                                Radius.circular(64),
                              ),
                            ),
                            child: TextField(
                              controller: _nameController,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400),
                              decoration:
                                  const InputDecoration.collapsed(hintText: ''),
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: MediaQuery.of(context).viewInsets.bottom,
                          ),
                        ],
                      );
                    } else {
                      return SizedBox(
                        height: constraints.maxHeight,
                        child: _CollectionCreation(
                          onDone: () =>
                              setState(() => _showCollectionCreation = false),
                        ),
                      );
                    }
                  },
                ),
              );
            },
          ),
        );
      },
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

  void _showDeleteDialog(String collectionId) async {
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
      final deleteResult =
          await ref.read(userProvider2.notifier).deleteCollection(collectionId);
      if (mounted) {
        deleteResult.fold(
          (l) => displayError(context, l),
          (r) {},
        );
      }
    }
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
      child: Container(
        alignment: Alignment.bottomLeft,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromRGBO(0xFF, 0x7F, 0x7A, 1.0),
              Color.fromRGBO(0xFC, 0x35, 0x35, 1.0),
            ],
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: icon,
            ),
            Positioned(
              left: 8,
              bottom: 8,
              right: 8,
              child: Text(
                label,
                textAlign: TextAlign.start,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: Colors.white),
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String label;

  const _SectionTitle({
    super.key,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodyMedium!
              .copyWith(fontSize: 12, fontWeight: FontWeight.w400),
        ),
      ),
    );
  }
}

class _CollectionCreation extends StatefulWidget {
  final VoidCallback onDone;

  const _CollectionCreation({
    super.key,
    required this.onDone,
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
        widget.onDone();
        return Future.value(false);
      },
      child: BlurredSurface(
        blur: 25,
        child: Column(
          children: [
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
                              widget.onDone();
                              break;
                            case _CreationStep.upload:
                              setState(() => _step = _CreationStep.photos);
                              break;
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_step != _CreationStep.photos) ...[
                                const Icon(
                                  Icons.chevron_left,
                                  color: Colors.black,
                                ),
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
                                const Icon(
                                  Icons.chevron_right,
                                  color: Colors.black,
                                ),
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
                    case _CreationStep.upload:
                      return _UploadStep(
                        photos: _photos,
                        onUpload: _uploadCollection,
                        onDelete: widget.onDone,
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
        photos: _photos,
        audio: _audio,
      ),
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
      },
    );
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

enum _CreationStep { photos, upload }
