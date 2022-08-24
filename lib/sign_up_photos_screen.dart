import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/widgets/back_button.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/photo_grid.dart';
import 'package:openup/widgets/theming.dart';

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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 100),
          Text(
            'Add pictures',
            style: Theming.of(context).text.body.copyWith(
                  fontWeight: FontWeight.w300,
                  fontSize: 32,
                ),
          ),
          Text(
            'Adding pictures increases your chances of making friends (must add at least one)',
            style: Theming.of(context).text.body.copyWith(
                  fontWeight: FontWeight.w300,
                  fontSize: 24,
                ),
          ),
          const Expanded(
            child: PhotoGrid(
              horizontal: true,
              itemColor: Color.fromRGBO(0x00, 0x00, 0x00, 0.5),
            ),
          ),
          Consumer(
            builder: (context, ref, _) {
              final gallery = ref
                  .watch(userProvider.select((p) => p.profile?.gallery ?? []));
              return Button(
                onPressed: gallery.isEmpty
                    ? null
                    : () => Navigator.of(context)
                        .pushReplacementNamed('sign-up-photos-hide'),
                child: const OutlinedArea(
                  child: Center(
                    child: Text('continue'),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}
