import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/image_builder.dart';

class PhotoGrid extends ConsumerWidget {
  final bool horizontal;
  final Color? itemColor;
  const PhotoGrid({
    Key? key,
    this.horizontal = false,
    this.itemColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rowCount = horizontal ? 2 : 3;
    final colCount = horizontal ? 3 : 2;
    return Column(
      children: [
        for (var row = 0; row < rowCount; row++)
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: horizontal
                  ? (row == 0
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start)
                  : CrossAxisAlignment.stretch,
              children: [
                for (var col = 0; col < colCount; col++)
                  Expanded(
                    child: Consumer(
                      builder: (context, ref, _) {
                        final gallery = ref.watch(userProvider
                            .select((p) => p.profile?.gallery ?? []));

                        final index = row * colCount + col;
                        return Stack(
                          children: [
                            Button(
                              onPressed: () async {
                                final bytes = await _pickAndCropPhoto(context);
                                if (bytes != null) {
                                  _uploadPhoto(context, ref, bytes, index);
                                }
                              },
                              child: Container(
                                constraints:
                                    const BoxConstraints(maxHeight: 145),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 12,
                                ),
                                clipBehavior: Clip.hardEdge,
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(21)),
                                  color: itemColor ??
                                      const Color.fromRGBO(
                                          0xC4, 0xC4, 0xC4, 0.5),
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  fit: StackFit.expand,
                                  children: [
                                    if (index < gallery.length)
                                      ColorFiltered(
                                        colorFilter: ColorFilter.mode(
                                          Colors.black.withOpacity(0.25),
                                          BlendMode.darken,
                                        ),
                                        child: Image.network(
                                          gallery[index],
                                          fit: BoxFit.cover,
                                          frameBuilder: fadeInFrameBuilder,
                                          loadingBuilder:
                                              circularProgressLoadingBuilder,
                                          errorBuilder: iconErrorBuilder,
                                          opacity: const AlwaysStoppedAnimation(
                                              0.75),
                                        ),
                                      ),
                                    if (index >= gallery.length)
                                      const Icon(
                                        Icons.add,
                                        size: 48,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            if (index < gallery.length)
                              Positioned(
                                right: 20,
                                top: 20,
                                child: Button(
                                  onPressed: () {
                                    _deletePhoto(
                                      context: context,
                                      ref: ref,
                                      index: index,
                                    );
                                  },
                                  child: const Icon(
                                    Icons.close,
                                    size: 21,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Future<Uint8List?> _pickAndCropPhoto(BuildContext context) async {
    final path = await _showPickPhotoInterface(context);
    if (path == null) {
      return null;
    }

    final cropped = await ImageCropper().cropImage(
      sourcePath: path,
      uiSettings: [
        AndroidUiSettings(
          hideBottomControls: true,
          statusBarColor: Colors.black,
        ),
        IOSUiSettings(
          resetButtonHidden: true,
          rotateButtonsHidden: true,
          rotateClockwiseButtonHidden: true,
          aspectRatioPickerButtonHidden: true,
        ),
      ],
    );

    if (cropped != null) {
      return cropped.readAsBytes();
    }
    return null;
  }
}

Future<String?> _showPickPhotoInterface(BuildContext context) async {
  final useCamera = await showDialog<bool>(
    context: context,
    builder: (context) {
      return Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.of(context).pop(true),
            ),
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text('Gallery'),
              onTap: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      );
    },
  );

  if (useCamera != null) {
    final imagePicker = ImagePicker();
    final image = await imagePicker.pickImage(
      maxWidth: 800,
      maxHeight: 800,
      source: useCamera ? ImageSource.camera : ImageSource.gallery,
    );
    return image?.path;
  }

  return null;
}

void _uploadPhoto(
  BuildContext context,
  WidgetRef ref,
  Uint8List bytes,
  int index,
) async {
  final result = await withBlockingModal(
    context: context,
    label: 'Uploading photo',
    future: updatePhoto(
      context: context,
      ref: ref,
      bytes: bytes,
      index: index,
    ),
  );

  result.fold(
    (l) => displayError(context, l),
    (r) {},
  );
}

void _deletePhoto({
  required BuildContext context,
  required WidgetRef ref,
  required int index,
}) async {
  final result = await withBlockingModal(
    context: context,
    label: 'Deleting photo',
    future: deletePhoto(
      context: context,
      ref: ref,
      index: index,
    ),
  );

  result.fold(
    (l) => displayError(context, l),
    (r) {},
  );
}
