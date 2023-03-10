import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/menu_page.dart';
import 'package:openup/widgets/back_button.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/collections_preview_list.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/gallery.dart';

class ViewCollectionPage extends ConsumerStatefulWidget {
  final String? collectionId;
  final String? collectionsOfUid;
  final List<Collection>? relatedCollections;
  final int? relatedCollectionIndex;

  const ViewCollectionPage({
    super.key,
    required this.collectionId,
    this.collectionsOfUid,
    required this.relatedCollections,
    required this.relatedCollectionIndex,
  });

  @override
  ConsumerState<ViewCollectionPage> createState() => _ViewCollectionPageState();
}

class _ViewCollectionPageState extends ConsumerState<ViewCollectionPage> {
  Collection? _collection;
  List<Collection>? _relatedCollections;
  int? _relatedCollectionIndex;
  bool _error = false;
  bool _play = true;
  bool _showCollectionPreviews = false;

  @override
  void initState() {
    super.initState();
    _relatedCollections = widget.relatedCollections;
    _relatedCollectionIndex = widget.relatedCollectionIndex;
    if (_relatedCollections == null || _relatedCollectionIndex == null) {
      _fetchCollection();
    } else {
      _collection = _relatedCollections![_relatedCollectionIndex!];
    }
  }

  void _fetchCollection() async {
    final collectionId = widget.collectionId;
    final collectionsOfUid = widget.collectionsOfUid;
    if (collectionId == null && collectionsOfUid == null) {
      setState(() => _error = true);
      return;
    }

    final api = GetIt.instance.get<Api>();
    if (collectionId != null) {
      final collectionWithRelated = await api.getCollection(
        collectionId,
        withRelated: RelatedCollectionsType.user,
      );

      if (!mounted) {
        return;
      }
      collectionWithRelated.fold(
        (l) {
          setState(() => _error = true);
          displayError(context, l);
        },
        (r) {
          setState(() {
            _collection = r.collection;
            _relatedCollections = r.related;
            _relatedCollectionIndex =
                r.related.indexWhere((c) => c == r.collection);
          });
        },
      );
    } else if (collectionsOfUid != null) {
      final collections = await api.getCollections(collectionsOfUid);

      if (!mounted) {
        return;
      }
      collections.fold(
        (l) {
          setState(() => _error = true);
          displayError(context, l);
        },
        (r) {
          setState(() {
            _collection = r.isEmpty ? null : r.first;
            _relatedCollections = r;
            _relatedCollectionIndex = 0;
          });
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final collection = _collection;
    final collections = _relatedCollections;
    return Scaffold(
      backgroundColor: Colors.black,
      body: ActivePage(
        onActivate: () => setState(() => _play = true),
        onDeactivate: () => setState(() => _play = false),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (collection == null && !_error)
              const Center(
                child: LoadingIndicator(),
              )
            else if (collection == null && _error)
              Center(
                child: Text(
                  'Unable to load Collection',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium!
                      .copyWith(fontSize: 20, fontWeight: FontWeight.w400),
                ),
              ),
            if (collection != null)
              Button(
                onPressed: () => setState(
                    () => _showCollectionPreviews = !_showCollectionPreviews),
                child: CinematicGallery(
                  slideshow: _play,
                  gallery: collection.photos,
                ),
              ),
            if (collections != null)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                left: 0,
                right: 0,
                bottom: _showCollectionPreviews ? 0 : -200,
                height: 200,
                child: CollectionsPreviewList(
                  collections: collections,
                  index: collections.indexWhere((c) => c == collection),
                  onView: (index) {
                    setState(() => _collection = collections[index]);
                  },
                ),
              ),
            Positioned(
              left: 8,
              top: MediaQuery.of(context).padding.top + 8,
              child: const BackIconButton(),
            ),
            if (collection != null)
              Positioned(
                right: 8,
                top: MediaQuery.of(context).padding.top + 8,
                child: PopupMenuButton(
                  icon: const Icon(Icons.more_horiz),
                  itemBuilder: (context) {
                    return [
                      PopupMenuItem(
                        onTap: () => _showSetAsProfileDialog(collection),
                        child: const Text('Set as profile'),
                      ),
                    ];
                  },
                ),
              ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              right: 22,
              bottom: 12 +
                  MediaQuery.of(context).padding.bottom +
                  (_showCollectionPreviews ? 200 : 0),
              child: const MenuButton(
                color: Color.fromRGBO(0xFF, 0xFF, 0xFF, 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSetAsProfileDialog(Collection collection) async {
    final replace = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text('Set as profile?'),
          content: const Text('This will replace your existing audio bio.'),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Replace'),
            ),
            CupertinoDialogAction(
              onPressed: Navigator.of(context).pop,
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );

    if (!mounted || replace != true) {
      return;
    }

    final api = GetIt.instance.get<Api>();
    final result = await withBlockingModal(
      context: context,
      label: 'Setting as profile',
      future: updateProfileCollection(ref: ref, collection: collection),
    );

    if (!mounted) {
      return;
    }
    result.fold(
      (l) => displayError(context, l),
      (r) {},
    );
  }
}

class ViewCollectionPageArguments {
  final List<Collection> relatedCollections;
  final int relatedCollectionIndex;

  const ViewCollectionPageArguments({
    required this.relatedCollections,
    required this.relatedCollectionIndex,
  });
}
