import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/menu_page.dart';
import 'package:openup/widgets/back_button.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/collections_preview_list.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/gallery.dart';

class ViewCollectionPage extends ConsumerStatefulWidget {
  final String? collectionId;
  final List<Collection>? relatedCollections;
  final int? relatedCollectionIndex;

  const ViewCollectionPage({
    super.key,
    required this.collectionId,
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
    if (collectionId == null) {
      setState(() => _error = true);
      return;
    }

    final api = GetIt.instance.get<Api>();
    final uid = ref.read(userProvider).uid;
    final collectionWithRelated = await api.getCollection(
      uid,
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
              r.related?.indexWhere((c) => c == r.collection);
        });
      },
    );
  }

  bool _showing = false;
  @override
  Widget build(BuildContext context) {
    final collection = _collection;
    final collections = _relatedCollections;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
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
              onPressed: () {
                setState(() => _showing = !_showing);
              },
              child: CinematicGallery(
                slideshow: true,
                gallery: collection.photos,
              ),
            ),
          if (collections != null)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              left: 0,
              right: 0,
              bottom: _showing ? 0 : -200,
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
