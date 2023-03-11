import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
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

part 'view_collection_page.freezed.dart';

class ViewCollectionPage extends ConsumerStatefulWidget {
  final ViewCollectionPageArguments args;

  const ViewCollectionPage({
    super.key,
    required this.args,
  });

  @override
  ConsumerState<ViewCollectionPage> createState() => _ViewCollectionPageState();
}

class _ViewCollectionPageState extends ConsumerState<ViewCollectionPage> {
  int? _profileCollectionIndex;
  List<Collection>? _collections;
  int _index = 0;

  bool _error = false;
  bool _play = true;
  bool _showCollectionPreviews = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  void _init() async {
    widget.args.when(
      profile: (profile, collections, index) async {
        if (collections != null) {
          setState(() {
            _profileCollectionIndex = 0;
            _collections = [
              profile.collection,
              ...collections,
            ];
            // Index was relative to incoming collection
            _index = index == null ? _index : (index + 1);
          });
        } else {
          final result = await _fetchCollections(profile.uid);
          if (result != null && mounted) {
            _profileCollectionIndex = 0;
            setState(() {
              _collections = [
                profile.collection,
                ...result,
              ];
            });
          }
        }
      },
      uid: (uid) async {
        final profileFuture = _fetchProfile(uid);
        final collectionsFuture = _fetchCollections(uid);
        final results = await Future.wait([profileFuture, collectionsFuture]);
        final profile = results[0] as Profile?;
        final collections = results[1] as List<Collection>?;
        if (profile != null && collections != null && mounted) {
          setState(() {
            _profileCollectionIndex = 0;
            _collections = [
              profile.collection,
              ...collections,
            ];
          });
        }
      },
      collectionId: (collectionId) async {
        final collection = await _fetchCollection(collectionId);
        if (collection != null && mounted) {
          setState(() => _collections = [collection]);
        }
      },
    );
  }

  Future<List<Collection>?> _fetchCollections(String uid) async {
    final api = GetIt.instance.get<Api>();
    final collections = await api.getCollections(uid);

    if (!mounted) {
      return null;
    }
    return collections.fold(
      (l) {
        displayError(context, l);
        return null;
      },
      (r) => r,
    );
  }

  Future<Collection?> _fetchCollection(String collectionId) async {
    final api = GetIt.instance.get<Api>();
    final collection = await api.getCollection(collectionId);

    if (!mounted) {
      return null;
    }
    return collection.fold(
      (l) {
        displayError(context, l);
        return null;
      },
      (r) => r.collection,
    );
  }

  Future<Profile?> _fetchProfile(String uid) async {
    final api = GetIt.instance.get<Api>();
    final profile = await api.getProfile(uid);

    if (!mounted) {
      return null;
    }
    return profile.fold(
      (l) {
        displayError(context, l);
        return null;
      },
      (r) => r,
    );
  }

  @override
  Widget build(BuildContext context) {
    final collections = _collections;
    const listHeight = 200.0;
    final bottomPadding = MediaQuery.of(context).padding.bottom + 16;
    return Scaffold(
      backgroundColor: Colors.black,
      body: ActivePage(
        onActivate: () => setState(() => _play = true),
        onDeactivate: () => setState(() => _play = false),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (collections == null && !_error)
              const Center(
                child: LoadingIndicator(),
              )
            else if (collections == null && _error)
              Center(
                child: Text(
                  'Unable to load Collection',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium!
                      .copyWith(fontSize: 20, fontWeight: FontWeight.w400),
                ),
              ),
            if (collections != null)
              Button(
                onPressed: () => setState(
                    () => _showCollectionPreviews = !_showCollectionPreviews),
                child: CinematicGallery(
                  slideshow: _play,
                  gallery: collections[_index].photos,
                ),
              ),
            if (collections != null)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                left: 0,
                right: 0,
                bottom: _showCollectionPreviews
                    ? bottomPadding
                    : -(listHeight + bottomPadding),
                height: listHeight,
                child: CollectionsPreviewList(
                  profileCollectionIndex: _profileCollectionIndex,
                  collections: collections,
                  index: _index,
                  onView: (index) => setState(() => _index = index),
                ),
              ),
            Positioned(
              left: 8,
              top: MediaQuery.of(context).padding.top + 8,
              child: const BackIconButton(),
            ),
            if (collections != null &&
                collections[_index].uid == ref.read(userProvider).uid)
              Positioned(
                right: 8,
                top: MediaQuery.of(context).padding.top + 8,
                child: PopupMenuButton(
                  icon: const Icon(Icons.more_horiz),
                  itemBuilder: (context) {
                    return [
                      PopupMenuItem(
                        onTap: () =>
                            _showSetAsProfileDialog(collections[_index]),
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
              bottom:
                  bottomPadding + (_showCollectionPreviews ? listHeight : 0),
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

@freezed
class ViewCollectionPageArguments with _$ViewCollectionPageArguments {
  const factory ViewCollectionPageArguments.profile({
    required Profile profile,
    @Default(null) List<Collection>? collections,
    @Default(null) int? index,
  }) = _Profile;

  const factory ViewCollectionPageArguments.uid({
    required String uid,
  }) = _Uid;

  const factory ViewCollectionPageArguments.collectionId({
    required String collectionId,
  }) = _CollectionId;
}
