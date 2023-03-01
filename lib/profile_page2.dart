import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dartz/dartz.dart' show Either;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:intl/intl.dart';
import 'package:image/image.dart' as img;
import 'package:openup/api/api.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/view_collection_page.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/menu_page.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/gallery.dart';
import 'package:openup/widgets/image_builder.dart';
import 'package:openup/widgets/screenshot.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

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
                        const Text('Login to create a profile'),
                        ElevatedButton(
                          onPressed: () => context.pushNamed('signup'),
                          child: const Text('Login'),
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

                return Stack(
                  children: [
                    Positioned.fill(
                      child: Image.network(
                        profile.photo,
                        fit: BoxFit.cover,
                        loadingBuilder: loadingBuilder,
                        errorBuilder: iconErrorBuilder,
                      ),
                    ),
                    Positioned(
                      left: 0,
                      top: 16 + MediaQuery.of(context).padding.top,
                      right: 0,
                      child: Row(
                        children: [
                          Container(
                            width: 45,
                            height: 45,
                            margin: const EdgeInsets.only(left: 13, right: 7),
                            clipBehavior: Clip.hardEdge,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                            ),
                            child: Image.network(
                              profile.photo,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  profile.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium!
                                      .copyWith(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w300),
                                ),
                                Text(
                                  'Friends ${profile.friendCount}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium!
                                      .copyWith(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w300),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton(
                            padding: const EdgeInsets.only(left: 8, right: 16),
                            child: const Icon(
                              Icons.more_horiz,
                              size: 32,
                            ),
                            itemBuilder: (context) {
                              return [
                                PopupMenuItem(
                                  onTap: () =>
                                      context.pushNamed('account_settings'),
                                  child: const Text('Account Settings'),
                                ),
                              ];
                            },
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 12 + MediaQuery.of(context).padding.bottom,
                      height: 189,
                      child: Builder(
                        builder: (context) {
                          final collections = ref
                              .watch(userProvider.select((p) => p.collections));
                          return ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 7),
                            itemCount: 2 + collections.length,
                            itemBuilder: (context, index) {
                              return Container(
                                width: 106,
                                height: 189,
                                clipBehavior: Clip.hardEdge,
                                margin: const EdgeInsets.all(7),
                                decoration: const BoxDecoration(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(15)),
                                ),
                                child: Builder(
                                  builder: (context) {
                                    if (index == 0) {
                                      return _BottomButton(
                                        label: 'Update voice bio',
                                        icon: const Icon(
                                          Icons.mic_none,
                                          color: Color.fromRGBO(
                                              0xFF, 0x5C, 0x5C, 1.0),
                                        ),
                                        onPressed: () async {
                                          final audio =
                                              await _showRecordPanel(context);
                                          if (mounted && audio != null) {
                                            _upload(audio);
                                          }
                                        },
                                      );
                                    } else if (index == 1) {
                                      return _BottomButton(
                                        label: 'Upload new collection',
                                        icon: const Icon(Icons.upload),
                                        onPressed: () => setState(() =>
                                            _showCollectionCreation = true),
                                      );
                                    }
                                    final realIndex = index - 2;
                                    final collection = collections[realIndex];
                                    return _CollectionPreview(
                                      collection: collection,
                                      onView: () {
                                        context.pushNamed(
                                          'view_collection',
                                          extra: ViewCollectionPageArguments(
                                            collections: collections,
                                            collectionIndex: realIndex,
                                          ),
                                        );
                                      },
                                      onDelete: () {
                                        GetIt.instance
                                            .get<Api>()
                                            .deleteCollection(collection.uid,
                                                collection.collectionId);
                                        final collections = ref.read(
                                            userProvider
                                                .select((p) => p.collections));
                                        final newCollections =
                                            List.of(collections)
                                              ..removeAt(realIndex);
                                        ref
                                            .read(userProvider.notifier)
                                            .collections(newCollections);
                                      },
                                    );
                                  },
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    if (_showCollectionCreation)
                      _CollectionCreation(
                        onCancel: () =>
                            setState(() => _showCollectionCreation = false),
                        onDone: (collection) {
                          final collections = ref
                              .read(userProvider.select((p) => p.collections));
                          final newCollections = List.of(collections)
                            ..insert(0, collection);
                          ref
                              .read(userProvider.notifier)
                              .collections(newCollections);
                          setState(() => _showCollectionCreation = false);
                        },
                      ),
                  ],
                );
              },
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.bounceOut,
              right: 22,
              bottom: 12 + MediaQuery.of(context).padding.bottom + 120,
              height: 184,
              child: const MenuButton(
                color: Color.fromRGBO(0xFF, 0xFF, 0xFF, 0.5),
              ),
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
            onSubmit: (audio) => Navigator.of(context).pop(audio),
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
}

class _CollectionPreview extends StatefulWidget {
  final Collection collection;
  final VoidCallback onView;
  final VoidCallback onDelete;

  const _CollectionPreview({
    super.key,
    required this.collection,
    required this.onView,
    required this.onDelete,
  });

  @override
  State<_CollectionPreview> createState() => _CollectionPreviewState();
}

class _CollectionPreviewState extends State<_CollectionPreview> {
  @override
  Widget build(BuildContext context) {
    final format = DateFormat.yMd();
    return Button(
      onLongPressStart: _showDeleteDialog,
      onPressed: widget.onView,
      child: Stack(
        children: [
          Positioned.fill(
            child: CinematicGallery(
              slideshow: true,
              gallery: widget.collection.photos,
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 11.0),
              child: Text(
                format.format(widget.collection.date),
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium!
                    .copyWith(fontSize: 15, fontWeight: FontWeight.w300),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog() async {
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
      widget.onDelete();
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
    return ColoredBox(
      color: const Color.fromRGBO(0x13, 0x13, 0x13, 0.5),
      child: BlurredSurface(
        blur: 2.0,
        child: Button(
          onPressed: onPressed,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium!
                    .copyWith(fontSize: 15, fontWeight: FontWeight.w400),
              ),
              const SizedBox(height: 15),
              icon,
            ],
          ),
        ),
      ),
    );
  }
}

class _CollectionCreation extends StatefulWidget {
  final VoidCallback onCancel;
  final void Function(Collection collection) onDone;

  const _CollectionCreation({
    super.key,
    required this.onCancel,
    required this.onDone,
  });

  @override
  State<_CollectionCreation> createState() => __CollectionCreationState();
}

class __CollectionCreationState extends State<_CollectionCreation> {
  bool _showPhotoGallery = true;
  bool _readyToUpload = false;

  final _selectedFiles = <File>[];
  File? _audioFile;

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
                          if (_showPhotoGallery) {
                            widget.onCancel();
                          } else {
                            if (!_readyToUpload) {
                              setState(() => _showPhotoGallery = true);
                            } else {
                              setState(() => _readyToUpload = false);
                            }
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!_showPhotoGallery) ...[
                                const Icon(Icons.chevron_left),
                                const SizedBox(width: 8),
                              ],
                              Text(
                                _showPhotoGallery ? 'Cancel' : 'Back',
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
                    if (_showPhotoGallery)
                      Center(
                        child: Text(
                          '${_selectedFiles.length}/3',
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
                        visible: !_readyToUpload,
                        child: Button(
                          onPressed: _selectedFiles.isEmpty
                              ? null
                              : () {
                                  if (_showPhotoGallery) {
                                    setState(() => _showPhotoGallery = false);
                                  } else {
                                    setState(() => _readyToUpload = true);
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
            const SizedBox(height: 8),
            if (!_showPhotoGallery && !_readyToUpload)
              SizedBox(
                width: 249,
                child: Text(
                  'Want to say something\nabout this collection?',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 20, fontWeight: FontWeight.w500, height: 1.5),
                ),
              )
            else if (!_showPhotoGallery && _readyToUpload)
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
              child: AspectRatio(
                aspectRatio: 9 / 16,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    const cacheWidth = 800;
                    return Button(
                      onPressed: _selectedFiles.isEmpty || !_showPhotoGallery
                          ? null
                          : () {},
                      useFadeWheNoPressedCallback: false,
                      onLongPressStart:
                          _selectedFiles.isEmpty || !_showPhotoGallery
                              ? null
                              : () {
                                  setState(() => _selectedFiles.removeLast());
                                },
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          for (var i = 0; i < _selectedFiles.length; i++)
                            AnimatedContainer(
                              key: ValueKey(_selectedFiles[i].path),
                              duration: const Duration(milliseconds: 200),
                              transform: Matrix4.identity()
                                ..scale(1.0 -
                                    0.05 * (_selectedFiles.length - i - 1))
                                ..translate(
                                    constraints.maxWidth, constraints.maxHeight)
                                ..rotateZ(radians(
                                    -5.12 * (_selectedFiles.length - i - 1)))
                                ..translate(-constraints.maxWidth,
                                    -constraints.maxHeight),
                              child: Container(
                                clipBehavior: Clip.hardEdge,
                                margin: const EdgeInsets.all(7),
                                decoration: _selectedFiles.isEmpty
                                    ? const BoxDecoration()
                                    : const BoxDecoration(
                                        color: Colors.black,
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(15)),
                                        boxShadow: [
                                          BoxShadow(
                                            offset: Offset(
                                              0.0,
                                              4.0,
                                            ),
                                            blurRadius: 8,
                                            color: Color.fromRGBO(
                                                0x00, 0x00, 0x00, 0.25),
                                          ),
                                        ],
                                      ),
                                child: Image.file(
                                  _selectedFiles[i],
                                  fit: BoxFit.cover,
                                  filterQuality: FilterQuality.high,
                                  cacheWidth: cacheWidth,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            if (!_showPhotoGallery)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!_readyToUpload)
                      Button(
                        onPressed: () async {
                          final result = await _showRecordPanel(context);
                          if (mounted && result != null) {
                            setState(() => _audioFile = result);
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
                                .copyWith(
                                    fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                        ),
                      )
                    else ...[
                      Button(
                        onPressed: widget.onCancel,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 4.0, horizontal: 8.0),
                          child: Text(
                            'Delete',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                    color: const Color.fromRGBO(
                                        0xFF, 0x00, 0x00, 1.0),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                      const SizedBox(width: 100),
                      Button(
                        onPressed: () => _upload(_selectedFiles, _audioFile),
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
                                  .copyWith(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500),
                            ),
                          ),
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            if (!_showPhotoGallery)
              Padding(
                padding: const EdgeInsets.all(8.0),
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
            else ...[
              Text(
                'hold down image to remove from collection',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium!
                    .copyWith(fontSize: 14, fontWeight: FontWeight.w400),
              ),
              const SizedBox(height: 10),
              Container(
                height: 32,
                color: const Color.fromRGBO(0x00, 0x00, 0x00, 0.25),
                child: Center(
                  child: Text(
                    'Add up to three photos in a collection',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium!
                        .copyWith(fontSize: 14, fontWeight: FontWeight.w300),
                  ),
                ),
              ),
              SizedBox(
                height: 300,
                child: _PhotoPickerGrid(
                  selected: _selectedFiles,
                  onPicked: _selectedFiles.length >= 3
                      ? null
                      : (file) => setState(() => _selectedFiles.add(file)),
                ),
              ),
            ],
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
            onSubmit: (audio) => Navigator.of(context).pop(audio),
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

  void _upload(List<File> photos, File? audio) async {
    final result = await withBlockingModal(
      context: context,
      label: 'Uploading collection...',
      future: _uploadCore(photos, audio),
    );

    if (!mounted || result == null) {
      return;
    }

    result.fold(
      (l) => displayError(context, l),
      (r) {
        showCupertinoDialog(
          context: context,
          builder: (context) {
            return CupertinoAlertDialog(
              title: const Text('Successfully uploaded collection'),
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
          widget.onDone(r);
        }
      },
    );
  }

  Future<Either<ApiError, Collection>?> _uploadCore(
    List<File> photos,
    File? audio,
  ) async {
    final api = GetIt.instance.get<Api>();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return null;
    }

    final photoBytes = await Future.wait(photos.map((f) => f.readAsBytes()));
    final images = await Future.wait(photoBytes.map(decodeImageFromList));
    final resized =
        await Future.wait(images.map((i) => downscaleImage(i, 2000)));
    final jpgs = await Future.wait(resized.map(encodeJpg));
    if (jpgs.contains(null)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to prepare photos'),
          ),
        );
      }
      return null;
    }
    final tempDir = await getTemporaryDirectory();

    final jpgFiles = <File>[];
    for (var i = 0; i < jpgs.length; i++) {
      final file = await File(
              path.join(tempDir.path, 'upload', 'collection_photo_$i.jpg'))
          .create(recursive: true);
      jpgFiles.add(await file.writeAsBytes(jpgs[i]!));
    }

    return api.createCollection(
      uid,
      jpgFiles.map((e) => e.path).toList(),
      audio?.path,
    );
  }

  Future<ui.Image> downscaleImage(ui.Image image, int targetSide) async {
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

  Future<Uint8List?> encodeJpg(ui.Image image, {int quality = 80}) async {
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
}

class _PhotoPickerGrid extends StatefulWidget {
  final List<File> selected;
  final void Function(File file)? onPicked;
  const _PhotoPickerGrid({
    required this.selected,
    required this.onPicked,
  });

  @override
  State<_PhotoPickerGrid> createState() => _PhotoPickerGridState();
}

class _PhotoPickerGridState extends State<_PhotoPickerGrid> {
  final _pagingController = PagingController<int, File>(firstPageKey: 0);
  final _allFiles = <File>[];
  bool _needsPermission = false;
  final _oldSelected = <File>[];

  @override
  void initState() {
    super.initState();

    _pagingController.addPageRequestListener((pageKey) async {
      final end = pageKey + 24;
      try {
        final files = await _fetchGallery(pageKey, end);
        if (mounted) {
          _allFiles.addAll(files);
          if (files.isNotEmpty) {
            _pagingController.appendPage(files, end);
          } else {
            _pagingController.appendLastPage(files);
          }
        }
      } catch (e) {
        _pagingController.error = e;
      }
    });

    _requestPermission().then((granted) {
      if (!granted) {
        _pagingController.appendPage([], 0);
      }
    });
  }

  @override
  void didUpdateWidget(covariant _PhotoPickerGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_oldSelected.length != widget.selected.length) {
      final newFiles = List.of(_allFiles);
      newFiles.removeWhere((file) => widget.selected.contains(file));
      setState(() => _pagingController.itemList = newFiles);
    }
    _oldSelected
      ..clear()
      ..addAll(widget.selected);
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  Future<bool> _requestPermission({
    bool canShowOpenSettingsDialog = true,
  }) async {
    final PermissionStatus status;
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt < 33) {
        status = await Permission.storage.request();
      } else {
        status = await Permission.photos.request();
      }
    } else {
      status = await Permission.photos.request();
    }

    if (status == PermissionStatus.permanentlyDenied ||
        status == PermissionStatus.restricted) {
      if (mounted) {
        setState(() {
          _needsPermission = true;
        });
      }

      if (status == PermissionStatus.permanentlyDenied &&
          mounted &&
          canShowOpenSettingsDialog) {
        final shown = await showCupertinoDialog(
          context: context,
          builder: (context) {
            return CupertinoAlertDialog(
              title: const Text('Photos access required'),
              content: const Text('Enable photos access for Openup'),
              actions: [
                CupertinoDialogAction(
                  onPressed: Navigator.of(context).pop,
                  child: const Text('Deny'),
                ),
                CupertinoDialogAction(
                  onPressed: () async {
                    final result = await openAppSettings();
                    if (mounted) {
                      Navigator.of(context).pop(result);
                    }
                  },
                  child: const Text('Open settings'),
                ),
              ],
            );
          },
        );
        if (!mounted || !shown) {
          return false;
        }
        return _requestPermission(canShowOpenSettingsDialog: false);
      }

      return false;
    }
    if (status == PermissionStatus.denied) {
      if (mounted) {
        setState(() => _needsPermission = true);
      }
      return false;
    }

    if (mounted) {
      setState(() => _needsPermission = false);
    }

    return true;
  }

  Future<List<File>> _fetchGallery(int start, int end) async {
    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: true, // Only "Recents" album
      filterOption: FilterOptionGroup(
        orders: const [OrderOption(asc: false)],
      ),
    );

    if (albums.isEmpty) {
      return [];
    }

    final recentsAlbum = albums.first;
    final photoEntities =
        await recentsAlbum.getAssetListRange(start: start, end: end);
    final photoFiles =
        await Future.wait(photoEntities.map((photoEntity) => photoEntity.file));
    final nonNullPhotoFiles =
        List<File>.from(photoFiles.where((f) => f != null));
    return nonNullPhotoFiles;
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth / 3;
          final cacheWidth =
              (width * MediaQuery.of(context).devicePixelRatio).toInt();
          return PagedGridView<int, File>(
            pagingController: _pagingController,
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: width,
              childAspectRatio: 9 / 16,
            ),
            padding: EdgeInsets.zero,
            builderDelegate: PagedChildBuilderDelegate(
              itemBuilder: (context, file, index) {
                final onPicked = widget.onPicked;
                return Button(
                  onPressed: onPicked == null ? null : () => onPicked(file),
                  useFadeWheNoPressedCallback: false,
                  child: Image.file(
                    file,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                    cacheWidth: cacheWidth,
                  ),
                );
              },
              firstPageProgressIndicatorBuilder: (context) {
                return const Center(
                  child: LoadingIndicator(size: 35),
                );
              },
              newPageProgressIndicatorBuilder: (context) {
                return const Center(
                  child: LoadingIndicator(size: 35),
                );
              },
              noItemsFoundIndicatorBuilder: (context) {
                if (!_needsPermission) {
                  return Center(
                    child: Text(
                      'No photos found',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium!
                          .copyWith(fontSize: 20, fontWeight: FontWeight.w300),
                    ),
                  );
                }
                return Center(
                  child: PermissionButton(
                    icon: const Icon(Icons.photo),
                    label: const Text('Enable Photos'),
                    granted: !_needsPermission,
                    onPressed: () {
                      _requestPermission().then((value) {
                        _pagingController.notifyPageRequestListeners(
                            _pagingController.nextPageKey ?? 0);
                      });
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
