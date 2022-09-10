import 'package:flutter/material.dart';
import 'package:openup/widgets/common.dart';

class ProfilePhoto extends StatelessWidget {
  final String url;
  final BoxFit fit;

  const ProfilePhoto({
    Key? key,
    required this.url,
    this.fit = BoxFit.cover,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ProfileImage(
      url,
      fit: fit,
      blur: false,
    );
  }
}
