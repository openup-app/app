import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/theming.dart';
import 'package:openup/widgets/three_photo_gallery.dart';

class SignUpPhotosScreen extends StatefulWidget {
  const SignUpPhotosScreen({Key? key}) : super(key: key);

  @override
  State<SignUpPhotosScreen> createState() => _SignUpPhotosScreenState();
}

class _SignUpPhotosScreenState extends State<SignUpPhotosScreen> {
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.black,
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 75),
            Text(
              'Add pictures',
              style: Theming.of(context).text.body.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 36,
                  ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 353),
                child: Text(
                  'Adding pictures increases your chances of making friends (must add at least one)',
                  textAlign: TextAlign.center,
                  style: Theming.of(context).text.body.copyWith(
                      fontWeight: FontWeight.w400, fontSize: 20, height: 1.4),
                ),
              ),
            ),
            const SizedBox(height: 55),
            const SizedBox(
              height: 297,
              child: ThreePhotoGallery(
                canDeleteAllPhotos: true,
              ),
            ),
            const Spacer(),
            Consumer(
              builder: (context, ref, _) {
                final canGoNext = ref.watch(userProvider
                    .select((p) => p.profile?.gallery.isNotEmpty == true));
                return OvalButton(
                  onPressed: !canGoNext
                      ? null
                      : () => Navigator.of(context)
                          .pushNamed('sign-up-photos-hide'),
                  child: const Text('continue'),
                );
              },
            ),
            const SizedBox(height: 59),
          ],
        ),
      ),
    );
  }
}
