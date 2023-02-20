import 'package:flutter/material.dart';
import 'package:openup/api/api.dart';
import 'package:openup/widgets/gallery.dart';

class ViewCollectionPage extends StatelessWidget {
  final List<Collection> collections;
  final int collectionIndex;

  const ViewCollectionPage({
    super.key,
    required this.collections,
    required this.collectionIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CinematicGallery(
        slideshow: true,
        gallery: collections[collectionIndex].photos,
      ),
    );
  }
}

class ViewCollectionPageArguments {
  final List<Collection> collections;
  final int collectionIndex;

  const ViewCollectionPageArguments({
    required this.collections,
    required this.collectionIndex,
  });
}
