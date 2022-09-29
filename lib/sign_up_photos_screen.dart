import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/three_photo_gallery.dart';

class SignUpPhotosScreen extends StatefulWidget {
  const SignUpPhotosScreen({Key? key}) : super(key: key);

  @override
  State<SignUpPhotosScreen> createState() => _SignUpPhotosScreenState();
}

class _SignUpPhotosScreenState extends State<SignUpPhotosScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 50),
            Text(
              'Add pictures',
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
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
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.w400,
                        fontSize: 20,
                        height: 1.4,
                      ),
                ),
              ),
            ),
            const SizedBox(height: 55),
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: 260,
                  maxHeight: 297,
                ),
                child: const ThreePhotoGallery(),
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
                      : () => context.pushNamed('onboarding-photos-hide'),
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
