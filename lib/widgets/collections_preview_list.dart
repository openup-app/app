import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:openup/api/api.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/gallery.dart';

class CollectionsPreviewList extends StatelessWidget {
  final List<Collection> collections;
  final int index;
  final List<Widget> leadingChildren;
  final void Function(int index) onView;
  final void Function(int index)? onLongPress;
  const CollectionsPreviewList({
    super.key,
    required this.collections,
    this.index = -1,
    this.leadingChildren = const <Widget>[],
    required this.onView,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      itemCount: leadingChildren.length + collections.length,
      itemBuilder: (context, index) {
        return Container(
          width: 106,
          height: 189,
          clipBehavior: Clip.hardEdge,
          margin: const EdgeInsets.all(7),
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(15)),
          ),
          child: _BlurredBackground(
            child: Builder(
              builder: (context) {
                if (index < leadingChildren.length) {
                  return leadingChildren[index];
                }
                final realIndex = index - leadingChildren.length;
                final collection = collections[realIndex];
                return _CollectionPreview(
                  collection: collection,
                  onView: () => onView(realIndex),
                  onLongPress: onLongPress == null
                      ? null
                      : () => onLongPress!(realIndex),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _BlurredBackground extends StatelessWidget {
  final Widget child;

  const _BlurredBackground({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color.fromRGBO(0x13, 0x13, 0x13, 0.5),
      child: BlurredSurface(
        blur: 2.0,
        child: child,
      ),
    );
  }
}

class _CollectionPreview extends StatefulWidget {
  final Collection collection;
  final VoidCallback onView;
  final VoidCallback? onLongPress;

  const _CollectionPreview({
    super.key,
    required this.collection,
    required this.onView,
    required this.onLongPress,
  });

  @override
  State<_CollectionPreview> createState() => _CollectionPreviewState();
}

class _CollectionPreviewState extends State<_CollectionPreview> {
  @override
  Widget build(BuildContext context) {
    final format = DateFormat.yMd();
    final isReady = widget.collection.state == CollectionState.ready;
    return Button(
      onLongPressStart: widget.onLongPress,
      onPressed: isReady ? widget.onView : null,
      useFadeWheNoPressedCallback: false,
      child: Stack(
        children: [
          if (!isReady)
            Center(
              child: Text(
                'Processing...',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium!
                    .copyWith(fontSize: 15, fontWeight: FontWeight.w300),
              ),
            )
          else
            Positioned.fill(
              child: CinematicGallery(
                slideshow: true,
                gallery: widget.collection.photos,
              ),
            ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 11.0),
              child: Text(
                format.format(widget.collection.date),
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium!
                    .copyWith(fontSize: 15, fontWeight: FontWeight.w300),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
