import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:openup/signup_collection_audio.dart';
import 'package:openup/widgets/back_button.dart';
import 'package:openup/widgets/button.dart';

class SignupCollectionPhotosPreview extends StatelessWidget {
  final List<File> photos;
  const SignupCollectionPhotosPreview({
    super.key,
    required this.photos,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            itemCount: photos.length,
            itemBuilder: (context, index) {
              return Image.file(
                photos[index],
                fit: BoxFit.cover,
              );
            },
          ),
          Container(
            height: 96 + MediaQuery.of(context).padding.top,
            color: Colors.black.withOpacity(0.2),
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 13, sigmaY: 13),
                child: Padding(
                  padding:
                      EdgeInsets.only(top: MediaQuery.of(context).padding.top),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: BackIconButton(),
                        ),
                        Center(
                          child: Text(
                            'Happy with your images?',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                    fontSize: 16, fontWeight: FontWeight.w400),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Button(
                            onPressed: () {
                              context.pushNamed(
                                'signup_collection_audio',
                                extra: SignupCollectionAudioArgs(photos),
                              );
                            },
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
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SignupCollectionPhotosPreviewArgs {
  final List<File> photos;

  const SignupCollectionPhotosPreviewArgs(this.photos);
}
