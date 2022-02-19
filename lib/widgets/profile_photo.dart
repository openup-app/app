import 'package:flutter/material.dart';
import 'package:openup/widgets/image_builder.dart';

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
    return Image.network(
      url,
      fit: fit,
      frameBuilder: fadeInFrameBuilder,
      loadingBuilder: circularProgressLoadingBuilder,
      errorBuilder: iconErrorBuilder,
    );
  }
}
