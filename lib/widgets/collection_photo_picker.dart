import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/collection_photo_stack.dart';
import 'package:openup/widgets/common.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';

class CollectionPhotoPicker extends StatefulWidget {
  final List<File> photos;
  final void Function(List<File> photos) onPhotosUpdated;
  final int max;
  final String? behindPhotoLabel;
  final String belowPhotoLabel;
  final String aboveGalleryLabel;

  const CollectionPhotoPicker({
    super.key,
    required this.photos,
    required this.onPhotosUpdated,
    this.max = 3,
    this.behindPhotoLabel,
    required this.belowPhotoLabel,
    required this.aboveGalleryLabel,
  });

  @override
  State<CollectionPhotoPicker> createState() => _CollectionPhotoPickerState();
}

class _CollectionPhotoPickerState extends State<CollectionPhotoPicker> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        Expanded(
          child: Button(
            onPressed: () {},
            useFadeWheNoPressedCallback: false,
            onLongPressStart: widget.photos.isEmpty
                ? null
                : () => widget
                    .onPhotosUpdated(List.of(widget.photos)..removeLast()),
            child: Stack(
              children: [
                if (widget.photos.isEmpty && widget.behindPhotoLabel != null)
                  Center(
                    child: Text(
                      widget.behindPhotoLabel!,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium!
                          .copyWith(fontSize: 16, fontWeight: FontWeight.w400),
                    ),
                  ),
                CollectionPhotoStack(
                  photos: widget.photos,
                ),
              ],
            ),
          ),
        ),
        if (widget.photos.isNotEmpty)
          Text(
            widget.belowPhotoLabel,
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
              widget.aboveGalleryLabel,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium!
                  .copyWith(fontSize: 16, fontWeight: FontWeight.w300),
            ),
          ),
        ),
        SizedBox(
          height: 300,
          child: _PhotoPickerGrid(
            selected: widget.photos,
            onPicked: widget.photos.length >= widget.max
                ? null
                : (file) =>
                    widget.onPhotosUpdated(List.of(widget.photos)..add(file)),
          ),
        ),
      ],
    );
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
      final end = pageKey + 18;
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
              (width / 1.5 * MediaQuery.of(context).devicePixelRatio).toInt();
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
