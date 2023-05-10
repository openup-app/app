import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/widgets/back_button.dart';
import 'package:openup/widgets/button.dart';

class SignupCollectionPhotosPreview extends ConsumerWidget {
  const SignupCollectionPhotosPreview({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photos = ref.watch(accountCreationParamsProvider).photos ?? [];
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            itemCount: photos.length,
            itemBuilder: (context, index) {
              return Image.file(
                File(photos[index]),
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
                          child: Consumer(
                            builder: (context, ref, child) {
                              return Button(
                                onPressed: () =>
                                    context.pushNamed('signup_audio'),
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
                              );
                            },
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
