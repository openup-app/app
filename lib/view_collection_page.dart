import 'package:flutter/material.dart';
import 'package:openup/api/api.dart';
import 'package:openup/menu_page.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/gallery.dart';

class ViewCollectionPage extends StatefulWidget {
  final List<Collection> collections;
  final int collectionIndex;

  const ViewCollectionPage({
    super.key,
    required this.collections,
    required this.collectionIndex,
  });

  @override
  State<ViewCollectionPage> createState() => _ViewCollectionPageState();
}

class _ViewCollectionPageState extends State<ViewCollectionPage> {
  bool _showing = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Button(
        onPressed: () {
          setState(() => _showing = !_showing);
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            CinematicGallery(
              slideshow: true,
              gallery: widget.collections[widget.collectionIndex].photos,
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              left: 0,
              right: 0,
              bottom: _showing ? 0 : -200,
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: widget.collections.length,
                itemBuilder: (context, index) {
                  return SizedBox(
                    width: 150,
                    child: Image.network(
                      widget.collections[index].photos.first.url,
                      fit: BoxFit.cover,
                    ),
                  );
                },
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              right: 22,
              bottom: 12 +
                  MediaQuery.of(context).padding.bottom +
                  (_showing ? 200 : 0),
              child: const MenuButton(
                color: Color.fromRGBO(0xFF, 0xFF, 0xFF, 0.5),
              ),
            ),
          ],
        ),
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
