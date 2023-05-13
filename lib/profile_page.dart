import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/view_profile_page.dart';
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
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
                controller: _scrollController,
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
                                      onPressed: () =>
                                          _showRecordPanel(context),
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
                                Positioned(
                                  right: 14,
                                  bottom: 30,
                                  width: 48,
                                  height: 48,
                                  child: Button(
                                    onPressed: () {
                                      _scrollController.animateTo(
                                        _scrollController
                                            .position.maxScrollExtent,
                                        duration:
                                            const Duration(milliseconds: 200),
                                        curve: Curves.easeOut,
                                      );
                                    },
                                    child: Center(
                                      child: Container(
                                        width: 29,
                                        height: 29,
                                        alignment: Alignment.center,
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              offset: Offset(0, 2),
                                              blurRadius: 4,
                                              color: Color.fromRGBO(
                                                  0x00, 0x00, 0x00, 0.25),
                                            ),
                                          ],
                                        ),
                                        child: const RotatedBox(
                                          quarterTurns: 1,
                                          child: Icon(
                                            Icons.chevron_right,
                                            color: Color.fromRGBO(
                                                0x71, 0x71, 0x71, 1.0),
                                          ),
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
                                      'view_profile',
                                      extra: ViewProfilePageArguments.profile(
                                        profile: profile,
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
                            child: const _NameField(),
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

  Future<void> _showRecordPanel(BuildContext context) {
    return showModalBottomSheet<Uint8List>(
      backgroundColor: Colors.transparent,
      context: context,
      builder: (context) {
        return const Surface(
          child: _RecordOrUpload(),
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

class _RecordOrUpload extends StatefulWidget {
  const _RecordOrUpload({super.key});

  @override
  State<_RecordOrUpload> createState() => _RecordOrUploadState();
}

class _RecordOrUploadState extends State<_RecordOrUpload> {
  _AudioBioState _audioBioState = _AudioBioState.creating;
  Timer? _animationTimer;

  @override
  void dispose() {
    _animationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 234,
      child: Builder(
        builder: (context) {
          switch (_audioBioState) {
            case _AudioBioState.creating:
              return Consumer(
                builder: (context, ref, _) {
                  return RecordPanelContents(
                    onSubmit: (audio, duration) =>
                        _submit(audio, duration, ref),
                  );
                },
              );
            case _AudioBioState.uploading:
              return const Center(
                child: LoadingIndicator(color: Colors.white),
              );
            case _AudioBioState.uploaded:
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.done,
                    size: 64,
                    color: Colors.green,
                  ),
                  Text(
                    'updated',
                    style: TextStyle(
                      color: Colors.green,
                    ),
                  )
                ],
              );
          }
        },
      ),
    );
  }

  void _submit(Uint8List audio, Duration duration, WidgetRef ref) async {
    if (!mounted) {
      return;
    }
    setState(() => _audioBioState = _AudioBioState.uploading);
    final tempDir = await getTemporaryDirectory();
    final file = await File(path.join(
            tempDir.path, 'audio_bio_${DateTime.now().toIso8601String()}.m4a'))
        .create();
    await file.writeAsBytes(audio);
    if (!mounted) {
      return;
    }
    final result = await updateAudio(
      ref: ref,
      bytes: await file.readAsBytes(),
    );
    if (mounted) {
      result.fold(
        (l) => displayError(context, l),
        (r) => setState(() {
          _audioBioState = _AudioBioState.uploaded;
          _animationTimer = Timer(const Duration(milliseconds: 1500), () {
            if (mounted) {
              Navigator.of(context).pop();
            }
          });
        }),
      );
    }
  }
}

enum _AudioBioState { creating, uploading, uploaded }

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
                    height: 1.5,
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

class _NameField extends ConsumerStatefulWidget {
  const _NameField({super.key});

  @override
  ConsumerState<_NameField> createState() => _NameFieldState();
}

class _NameFieldState extends ConsumerState<_NameField> {
  bool _editingName = false;
  final _nameFocusNode = FocusNode();
  final _nameController = TextEditingController();
  bool _initial = true;
  bool _submittingName = false;

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
  void dispose() {
    _nameFocusNode.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _nameController,
              autofocus: true,
              focusNode: _nameFocusNode,
              enabled: _editingName,
              textCapitalization: TextCapitalization.sentences,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium!
                  .copyWith(fontSize: 16, fontWeight: FontWeight.w400),
              decoration: const InputDecoration.collapsed(
                hintText: '',
              ),
            ),
          ),
        ),
        Button(
          onPressed: () async {
            if (!_editingName) {
              setState(() => _editingName = true);
              FocusScope.of(context).requestFocus(_nameFocusNode);
            } else {
              setState(() => _submittingName = true);
              final result = await ref
                  .read(userProvider2.notifier)
                  .updateName(_nameController.text);
              if (mounted) {
                setState(() => _submittingName = false);
                result.fold(
                  (l) => displayError(context, l),
                  (r) {
                    setState(() => _editingName = false);
                    _nameFocusNode.unfocus();
                  },
                );
              }
            }
          },
          child: Builder(
            builder: (context) {
              if (_submittingName) {
                return const Padding(
                  padding: EdgeInsets.only(right: 12.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),
                );
              }
              if (!_editingName) {
                return const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Edit',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Color.fromRGBO(0xFF, 0x03, 0x03, 1.0)),
                  ),
                );
              } else {
                return const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Done',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Color.fromRGBO(0x03, 0x58, 0xFF, 1.0)),
                  ),
                );
              }
            },
          ),
        ),
      ],
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
