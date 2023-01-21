import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:image/image.dart' as img;
import 'package:openup/api/api.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/image_builder.dart';
import 'package:openup/widgets/profile_display.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

class ProfilePage2 extends ConsumerStatefulWidget {
  const ProfilePage2({super.key});

  @override
  ConsumerState<ProfilePage2> createState() => _ProfilePage2State();
}

class _ProfilePage2State extends ConsumerState<ProfilePage2> {
  bool _showCollectionCreation = false;
  @override
  Widget build(BuildContext context) {
    final loggedIn = FirebaseAuth.instance.currentUser != null;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Builder(
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

          final profile = ref.watch(userProvider.select((p) => p.profile));
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
                                    fontSize: 20, fontWeight: FontWeight.w300),
                          ),
                          Text(
                            'Friends 215',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                    fontSize: 15, fontWeight: FontWeight.w300),
                          ),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(left: 8, right: 16),
                      child: Icon(
                        Icons.more_horiz,
                        size: 32,
                      ),
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
                    final collections =
                        ref.watch(userProvider.select((p) => p.collections));
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
                            borderRadius: BorderRadius.all(Radius.circular(15)),
                          ),
                          child: Builder(
                            builder: (context) {
                              if (index == 0) {
                                return _BottomButton(
                                  label: 'Update voice bio',
                                  icon: const Icon(
                                    Icons.mic_none,
                                    color:
                                        Color.fromRGBO(0xFF, 0x5C, 0x5C, 1.0),
                                  ),
                                  onPressed: () {},
                                );
                              } else if (index == 1) {
                                return _BottomButton(
                                  label: 'Upload new collection',
                                  icon: const Icon(Icons.upload),
                                  onPressed: () => setState(
                                      () => _showCollectionCreation = true),
                                );
                              }
                              final realIndex = index - 2;
                              final collection = collections[realIndex];
                              return _CollectionPreview(
                                collection: collection,
                                onDelete: () {
                                  GetIt.instance.get<Api>().deleteCollection(
                                      collection.uid, collection.collectionId);
                                  final collections = ref.read(userProvider
                                      .select((p) => p.collections));
                                  final newCollections = List.of(collections)
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
                    final collections =
                        ref.read(userProvider.select((p) => p.collections));
                    final newCollections = List.of(collections)
                      ..insert(0, collection);
                    ref.read(userProvider.notifier).collections(newCollections);
                    setState(() => _showCollectionCreation = false);
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CollectionPreview extends StatefulWidget {
  final Collection collection;
  final VoidCallback onDelete;

  const _CollectionPreview({
    super.key,
    required this.collection,
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
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) {
              return Scaffold(
                body: UserProfileDisplay(
                  profile: Profile(
                    uid: widget.collection.uid,
                    name: 'Jaween',
                    photo: widget.collection.photos.first,
                    gallery: widget.collection.photos,
                    blurPhotos: false,
                    location: '',
                    topic: Topic.conversation,
                  ),
                  play: false,
                  invited: true,
                  onInvite: () {},
                  onBeginRecording: () {},
                  onBlocked: () {},
                  onMenu: () {},
                  onNext: () {},
                ),
              );
            },
          ),
        );
      },
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              widget.collection.photos.first,
              fit: BoxFit.cover,
              loadingBuilder: loadingBuilder,
              errorBuilder: iconErrorBuilder,
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

  List<File>? _allFiles;
  final _selectedFiles = <File>[];

  @override
  void initState() {
    super.initState();

    PhotoManager.getAssetPathList(type: RequestType.image)
        .then((assetPaths) async {
      final assetEntityListFutures = <Future<List<AssetEntity>>>[];
      for (var assetPath in assetPaths) {
        assetEntityListFutures
            .add(assetPath.getAssetListRange(start: 0, end: 80));
      }
      final assetEntityLists = await Future.wait(assetEntityListFutures);
      final nullableFiles = await Future.wait(
          assetEntityLists.expand((e) => [...e]).map((e) => e.file));
      final files = List<File>.from(nullableFiles.where((e) => e != null));
      if (mounted) {
        setState(() => _allFiles = files);
      }
    });
  }

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
                    Center(
                      child: Text(
                        '${_selectedFiles.length}/6',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
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
                                  filterQuality: FilterQuality.medium,
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
                        onPressed: () {},
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
                        onPressed: () => _upload(_selectedFiles),
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
                    'Add up to six photos in a collection',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium!
                        .copyWith(fontSize: 14, fontWeight: FontWeight.w300),
                  ),
                ),
              ),
              Container(
                height: 300,
                color: Colors.black,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final files = _allFiles
                        ?.where((file) => !_selectedFiles.contains(file))
                        .toList();
                    if (files == null) {
                      return const Center(
                        child: LoadingIndicator(size: 35),
                      );
                    }

                    final width = constraints.maxWidth / 3;

                    return GridView.builder(
                      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: width,
                        childAspectRatio: 9 / 16,
                      ),
                      padding: EdgeInsets.zero,
                      itemCount: files.length,
                      itemBuilder: (context, index) {
                        final file = files[index];
                        return Button(
                          onPressed: _selectedFiles.length >= 6
                              ? () {}
                              : () => setState(() => _selectedFiles.add(file)),
                          child: Image.file(
                            file,
                            fit: BoxFit.cover,
                            filterQuality: FilterQuality.medium,
                            width: width,
                            cacheWidth: width.toInt(),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _upload(List<File> photos) async {
    final api = GetIt.instance.get<Api>();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return;
    }

    final photoBytes = await Future.wait(photos.map((f) => f.readAsBytes()));
    final images = await Future.wait(photoBytes.map(decodeImageFromList));
    final resized =
        await Future.wait(images.map((i) => downscaleImage(i, 800)));
    final jpgs = await Future.wait(resized.map(encodeJpg));
    if (jpgs.contains(null)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to prepare photos'),
          ),
        );
      }
      return;
    }
    final tempDir = await getTemporaryDirectory();

    final jpgFiles = <File>[];
    for (var i = 0; i < jpgs.length; i++) {
      final file = await File(
              path.join(tempDir.path, 'upload', 'collection_photo_$i.jpg'))
          .create(recursive: true);
      jpgFiles.add(await file.writeAsBytes(jpgs[i]!));
    }

    final apiFuture =
        api.createCollection(uid, jpgFiles.map((e) => e.path).toList(), null);
    if (!mounted) {
      return;
    }

    final result = await withBlockingModal(
      context: context,
      label: 'Uploading collection...',
      future: apiFuture,
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

  Future<Uint8List?> encodeJpg(ui.Image image) async {
    final bytes = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))
        ?.buffer
        .asUint8List();
    if (bytes == null) {
      return null;
    }

    final jpg = img.encodeJpg(
      img.Image.fromBytes(image.width, image.height, bytes),
    );
    return Uint8List.fromList(jpg);
  }
}
