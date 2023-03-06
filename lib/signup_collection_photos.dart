import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:openup/signup_collection_photos_preview.dart';
import 'package:openup/widgets/back_button.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/collection_photo_picker.dart';

class SignupCollectionPhotos extends StatefulWidget {
  const SignupCollectionPhotos({super.key});

  @override
  State<SignupCollectionPhotos> createState() => _SignupCollectionPhotosState();
}

class _SignupCollectionPhotosState extends State<SignupCollectionPhotos> {
  final _photos = <File>[];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/signup_background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            Column(
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
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: BackIconButton(),
                        ),
                        Center(
                          child: Text(
                            '${_photos.length}/3',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    color: _photos.length != 3
                                        ? null
                                        : const Color.fromRGBO(
                                            0x22, 0xFF, 0x38, 1.0)),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Visibility(
                            visible: _photos.length == 3,
                            child: Button(
                              onPressed: _photos.length != 3
                                  ? null
                                  : () => context.pushNamed(
                                        'signup_collection_photos_preview',
                                        extra:
                                            SignupCollectionPhotosPreviewArgs(
                                                _photos),
                                      ),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  'next',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium!
                                      .copyWith(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w400),
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
                  child: CollectionPhotoPicker(
                    photos: _photos,
                    onPhotosUpdated: (List<File> photos) =>
                        setState(() => _photos
                          ..clear()
                          ..addAll(photos)),
                    belowPhotoLabel: 'Hold down an image to remove',
                    behindPhotoLabel: 'To join you must add three photos',
                    aboveGalleryLabel:
                        'You can see your full images on the next screen',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
