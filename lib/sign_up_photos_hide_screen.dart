import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/three_photo_gallery.dart';
import 'package:openup/widgets/toggle_button.dart';

class SignUpPhotosHideScreen extends StatefulWidget {
  const SignUpPhotosHideScreen({Key? key}) : super(key: key);

  @override
  State<SignUpPhotosHideScreen> createState() => _SignUpPhotosHideScreenState();
}

class _SignUpPhotosHideScreenState extends State<SignUpPhotosHideScreen> {
  bool _blur = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 50),
            Text(
              'Hide pictures',
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
                  'Hide your pictures if you do not want others to see you until you are comfortable with them',
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
                child: ThreePhotoGallery(
                  blur: _blur,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '(Toggle on or off anytime in your profile)',
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                  ),
            ),
            const SizedBox(height: 16),
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
            const Spacer(),
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
