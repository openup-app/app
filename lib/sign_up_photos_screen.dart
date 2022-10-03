import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/three_photo_gallery.dart';
import 'package:openup/widgets/toggle_button.dart';

class SignUpPhotosScreen extends StatefulWidget {
  const SignUpPhotosScreen({Key? key}) : super(key: key);

  @override
  State<SignUpPhotosScreen> createState() => _SignUpPhotosScreenState();
}

class _SignUpPhotosScreenState extends State<SignUpPhotosScreen> {
  bool _blur = false;

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
            const SizedBox(height: 32),
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: 260,
                  maxHeight: 297,
                ),
                child: ThreePhotoGallery(blur: _blur),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Blur Pictures',
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                ),
                const SizedBox(width: 8),
                Consumer(
                  builder: (context, ref, _) {
                    return ToggleButton(
                      value: _blur,
                      onChanged: (value) {
                        setState(() => _blur = value);
                        updateBlurPhotos(
                          context: context,
                          ref: ref,
                          blur: value,
                        );
                      },
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: Text(
                  'No one can see your pictures if the blurred toggle is on. Toggle on or off anytime in your profile',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Consumer(
              builder: (context, ref, _) {
                final canGoNext = ref.watch(userProvider
                    .select((p) => p.profile?.gallery.isNotEmpty == true));
                return OvalButton(
                  onPressed: !canGoNext
                      ? null
                      : () => context.pushNamed('onboarding-audio'),
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
