import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openup/api/user_profile_cache.dart';
import 'package:openup/api/user_state.dart';

class ProfileButton extends StatelessWidget {
  final double _width;
  final double _height;

  const ProfileButton({
    super.key,
    double width = 32,
    double height = 32,
  })  : _width = width,
        _height = height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _width,
      height: _height,
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: UserProfileCache(
        builder: (context, cachedPhoto) {
          return Consumer(
            builder: (context, ref, child) {
              final myProfile = ref.watch(userProvider2.select((p) {
                return p.map(
                  guest: (_) => null,
                  signedIn: (signedIn) => signedIn.account.profile,
                );
              }));
              if (myProfile != null) {
                return Image(
                  image: NetworkImage(myProfile.photo),
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                );
              } else if (cachedPhoto != null) {
                return Image.file(
                  cachedPhoto,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                );
              } else {
                return const Icon(
                  Icons.person,
                  size: 22,
                  color: Color.fromRGBO(0x8D, 0x8D, 0x8D, 1.0),
                );
              }
            },
          );
        },
      ),
    );
  }
}
