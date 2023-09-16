import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openup/analytics/analytics.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/util/photo_picker.dart';
import 'package:openup/widgets/back_button.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';

class SignupPhotos extends ConsumerStatefulWidget {
  const SignupPhotos({super.key});

  @override
  ConsumerState<SignupPhotos> createState() => _SignupPhotosState();
}

class _SignupPhotosState extends ConsumerState<SignupPhotos> {
  final _photos = <File?>[];

  @override
  void initState() {
    super.initState();
    _photos.addAll(ref.read(
        accountCreationParamsProvider.select((p) => p.photos ?? <File?>[])));
    if (_photos.length != 3) {
      _photos.addAll(List<File?>.generate(3 - _photos.length, (_) => null));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(0xF2, 0xF2, 0xF6, 1.0),
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          SizedBox(
            height: MediaQuery.of(context).padding.top,
          ),
          const SizedBox(height: 16),
          const Align(
            alignment: Alignment.topCenter,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: BackIconButton(
                    color: Colors.black,
                  ),
                ),
                Text(
                  'Photos',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          const Text(
            'To join, you must add at least 1 image of yourself\n( Maximum 3 photos in a collection )',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              height: 2.0,
              color: Color.fromRGBO(0x8D, 0x8D, 0x8D, 1.0),
            ),
          ),
          const SizedBox(height: 51),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (var i = 0; i < 3; i++)
                Builder(
                  builder: (context) {
                    final photo = _photos[i];
                    final hasPhoto = photo != null;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Button(
                          onPressed: () async {
                            final photos = await selectPhotos(
                              context,
                              label: 'These photo will be used in your profile',
                            );
                            if (mounted && photos != null) {
                              setState(() => _photos.replaceRange(
                                  i, i + min(3 - i, photos.length), photos));
                              ref
                                  .read(accountCreationParamsProvider.notifier)
                                  .photos(_photos.whereType<File>().toList());
                            }
                          },
                          child: RoundedRectangleContainer(
                            child: SizedBox(
                              width: 76,
                              height: 148,
                              child: photo == null
                                  ? const SizedBox.shrink()
                                  : Image.file(
                                      photo,
                                      fit: BoxFit.cover,
                                      cacheHeight: 148,
                                      filterQuality: FilterQuality.medium,
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: 24,
                          height: 24,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: !hasPhoto
                                ? Border.all(width: 2, color: Colors.white)
                                : const Border(),
                            color: !hasPhoto
                                ? Colors.transparent
                                : const Color.fromRGBO(0x2D, 0xDA, 0x01, 1.0),
                          ),
                          child: !hasPhoto
                              ? const SizedBox.shrink()
                              : const Icon(Icons.done, size: 16),
                        )
                      ],
                    );
                  },
                ),
            ],
          ),
          const Spacer(),
          Button(
            onPressed: _photos.whereType<File>().isEmpty
                ? null
                : () => _submit(_photos.whereType<File>().toList()),
            child: RoundedRectangleContainer(
              child: SizedBox(
                width: 171,
                height: 42,
                child: Center(
                  child: Text(
                    'Next',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium!
                        .copyWith(fontSize: 20, fontWeight: FontWeight.w400),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 36),
          SizedBox(
            height: MediaQuery.of(context).padding.bottom,
          ),
        ],
      ),
    );
  }

  void _submit(List<File> photos) {
    ref.read(accountCreationParamsProvider.notifier).photos(photos);
    ref.read(analyticsProvider).trackSignupSubmitPhotos();
    context.pushNamed('signup_audio');
  }
}
