import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/theming.dart';

class ThreePhotoGallery extends ConsumerStatefulWidget {
  final bool canDeleteAllPhotos;
  final bool blur;
  const ThreePhotoGallery({
    super.key,
    this.canDeleteAllPhotos = false,
    this.blur = false,
  });

  @override
  ConsumerState<ThreePhotoGallery> createState() => _ThreePhotoGalleryState();
}

class _ThreePhotoGalleryState extends ConsumerState<ThreePhotoGallery> {
  @override
  Widget build(BuildContext context) {
    final gallery = ref.watch(userProvider).profile?.gallery ?? [];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _PhotoOrUploadButton(
            url: gallery.isNotEmpty ? gallery[0] : null,
            label: '1',
            blur: widget.blur,
            onPressed: () => _onPressed(0),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _PhotoOrUploadButton(
                  url: gallery.length > 1 ? gallery[1] : null,
                  label: '2',
                  blur: widget.blur,
                  onPressed: () => _onPressed(1),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _PhotoOrUploadButton(
                  url: gallery.length > 2 ? gallery[2] : null,
                  label: '3',
                  blur: widget.blur,
                  onPressed: () => _onPressed(2),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _onPressed(int index) async {
    final gallery = ref.read(userProvider).profile?.gallery ?? [];
    final showDeleteButton = (gallery.length > index) ||
        ((gallery.length == index + 1) && widget.canDeleteAllPhotos);
    final changeOrDelete = await _showChangeOrDeleteDialog(showDeleteButton);
    if (!mounted) {
      return;
    }

    if (changeOrDelete == 'photo' || changeOrDelete == 'gallery') {
      final bytes = await _pickAndCropPhoto(
          changeOrDelete == 'photo' ? ImageSource.camera : ImageSource.gallery);
      if (mounted && bytes != null) {
        _uploadPhoto(context, bytes, index);
      }
    } else if (changeOrDelete == 'delete') {
      _deletePhoto(context, index);
    }
  }

  void _uploadPhoto(
    BuildContext context,
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

    if (!mounted) {
      return;
    }
    result.fold(
      (l) => displayError(context, l),
      (r) {},
    );
  }

  void _deletePhoto(BuildContext context, int index) async {
    final result = await withBlockingModal(
      context: context,
      label: 'Deleting photo',
      future: deletePhoto(
        context: context,
        ref: ref,
        index: index,
      ),
    );

    if (!mounted) {
      return;
    }
    result.fold(
      (l) => displayError(context, l),
      (r) {},
    );
  }

  Future<Uint8List?> _pickAndCropPhoto(ImageSource source) async {
    final imagePicker = ImagePicker();
    XFile? xFile;
    try {
      xFile = await imagePicker.pickImage(
        maxWidth: 800,
        maxHeight: 800,
        source: source,
      );
    } on PlatformException catch (e) {
      if (e.code == 'camera_access_denied') {
        return null;
      }
      debugPrint(e.toString());
      return null;
    }

    final path = xFile?.path;
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

  Future<String?> _showChangeOrDeleteDialog(bool showDeleteButton) {
    return showDialog<String>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          backgroundColor: Colors.black,
          children: [
            ListTile(
              leading: const Icon(
                Icons.camera_alt,
                color: Colors.white,
              ),
              title: Text(
                'Take a photo',
                style: Theming.of(context).text.body,
              ),
              onTap: () => Navigator.of(context).pop('photo'),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo,
                color: Colors.white,
              ),
              title: Text(
                'Choose from gallery',
                style: Theming.of(context).text.body,
              ),
              onTap: () => Navigator.of(context).pop('gallery'),
            ),
            if (showDeleteButton)
              ListTile(
                leading: const Icon(
                  Icons.delete,
                  color: Colors.red,
                ),
                title: Text(
                  'Delete photo',
                  style:
                      Theming.of(context).text.body.copyWith(color: Colors.red),
                ),
                onTap: () => Navigator.of(context).pop('delete'),
              ),
          ],
        );
      },
    );
  }
}

class _PhotoOrUploadButton extends StatelessWidget {
  final String? url;
  final String label;
  final bool blur;
  final VoidCallback onPressed;
  const _PhotoOrUploadButton({
    Key? key,
    required this.url,
    required this.label,
    required this.blur,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(24)),
      child: Button(
        onPressed: onPressed,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Builder(
              builder: (context) {
                final photoUrl = url;
                if (photoUrl != null) {
                  return ProfileImage(
                    photoUrl,
                    blur: blur,
                  );
                }
                return Container(
                  color: const Color.fromRGBO(0x7D, 0x7D, 0x7D, 1.0),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.add_photo_alternate,
                    color: Colors.white,
                    size: 34,
                  ),
                );
              },
            ),
            Positioned(
              bottom: 16,
              right: 8,
              width: 24,
              height: 24,
              child: Center(
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: Theming.of(context).text.body.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w300,
                        color: Colors.black),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
