import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/photo_grid.dart';
import 'package:openup/widgets/theming.dart';

class SignUpPhotosHideScreen extends StatefulWidget {
  const SignUpPhotosHideScreen({Key? key}) : super(key: key);

  @override
  State<SignUpPhotosHideScreen> createState() => _SignUpPhotosHideScreenState();
}

class _SignUpPhotosHideScreenState extends State<SignUpPhotosHideScreen> {
  bool _hide = false;
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
            'Hide pictures',
            style: Theming.of(context).text.body.copyWith(
                  fontWeight: FontWeight.w300,
                  fontSize: 32,
                ),
          ),
          Text(
            'Hide your pictures if you do not want others to see you until you are comfortable with them',
            style: Theming.of(context).text.body.copyWith(
                  fontWeight: FontWeight.w300,
                  fontSize: 24,
                ),
          ),
          Expanded(
            child: PhotoGrid(
              horizontal: true,
              itemColor: const Color.fromRGBO(0x00, 0x00, 0x00, 0.5),
              blur: _hide,
            ),
          ),
          CupertinoSwitch(
            value: _hide,
            onChanged: (value) => setState(() => _hide = value),
          ),
          Consumer(
            builder: (context, ref, _) {
              final gallery = ref
                  .watch(userProvider.select((p) => p.profile?.gallery ?? []));
              return Button(
                onPressed: gallery.isEmpty
                    ? null
                    : () => Navigator.of(context)
                        .pushReplacementNamed('sign-up-audio'),
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
