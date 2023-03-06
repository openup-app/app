import 'dart:io';

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

class CollectionPhotoStack extends StatelessWidget {
  final List<File> photos;
  const CollectionPhotoStack({
    super.key,
    required this.photos,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 9 / 16,
      child: LayoutBuilder(builder: (context, constraints) {
        const cacheWidth = 800;
        return Stack(
          fit: StackFit.expand,
          children: [
            for (var i = 0; i < photos.length; i++)
              AnimatedContainer(
                key: ValueKey(photos[i].path),
                duration: const Duration(milliseconds: 200),
                transform: Matrix4.identity()
                  ..scale(1.0 - 0.05 * (photos.length - i - 1))
                  ..translate(constraints.maxWidth, constraints.maxHeight)
                  ..rotateZ(radians(-5.12 * (photos.length - i - 1)))
                  ..translate(-constraints.maxWidth, -constraints.maxHeight),
                child: Container(
                  clipBehavior: Clip.hardEdge,
                  margin: const EdgeInsets.all(7),
                  decoration: photos.isEmpty
                      ? const BoxDecoration()
                      : const BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.all(Radius.circular(15)),
                          boxShadow: [
                            BoxShadow(
                              offset: Offset(
                                0.0,
                                4.0,
                              ),
                              blurRadius: 8,
                              color: Color.fromRGBO(0x00, 0x00, 0x00, 0.25),
                            ),
                          ],
                        ),
                  child: Image.file(
                    photos[i],
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                    cacheWidth: cacheWidth,
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }
}
