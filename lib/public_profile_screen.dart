import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openup/api/users/profile.dart';
import 'package:openup/api/users/users_api.dart';
import 'package:openup/util/users_api_util.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/home_button.dart';
import 'package:openup/widgets/profile_bio.dart';
import 'package:openup/widgets/image_builder.dart';
import 'package:openup/widgets/theming.dart';

class PublicProfileScreen extends ConsumerStatefulWidget {
  final PublicProfile publicProfile;
  final bool editable;

  const PublicProfileScreen({
    Key? key,
    required this.publicProfile,
    required this.editable,
  }) : super(key: key);

  @override
  ConsumerState<PublicProfileScreen> createState() =>
      _PublicProfileScreenState();
}

class _PublicProfileScreenState extends ConsumerState<PublicProfileScreen> {
  final _audioBioKey = GlobalKey<ProfileBioState>();
  PageController? _pageController;

  @override
  void initState() {
    super.initState();
    _resetPage();
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  void _resetPage() {
    final gallery = widget.publicProfile.gallery;
    _pageController?.dispose();
    setState(() {
      _pageController = PageController(initialPage: gallery.length * 100000);
    });
  }

  @override
  Widget build(BuildContext context) {
    final gallery = widget.publicProfile.gallery;
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          if (gallery.isEmpty)
            Center(
              child: Text(
                  widget.editable ? 'Add your first photo' : 'No photos',
                  style: Theming.of(context).text.subheading),
            ),
          Positioned.fill(
            child: PageView.builder(
              controller: _pageController,
              itemBuilder: (context, index) {
                final gallery = widget.publicProfile.gallery;
                if (gallery.isEmpty) {
                  return const SizedBox.shrink();
                }
                final i = index % gallery.length;
                return Image.network(
                  gallery[i],
                  fit: BoxFit.cover,
                  frameBuilder: fadeInFrameBuilder,
                  loadingBuilder: circularProgressLoadingBuilder,
                  errorBuilder: iconErrorBuilder,
                );
              },
            ),
          ),
          if (widget.editable)
            Positioned(
              right: MediaQuery.of(context).padding.right + 16,
              top: MediaQuery.of(context).padding.top + 16,
              child: Button(
                onPressed: () async {
                  final state = _audioBioKey.currentState;
                  state?.stopAll();
                  await Navigator.of(context).pushNamed('public-profile-edit');
                  _resetPage();
                },
                child: Container(
                  width: 128,
                  height: 128,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(40)),
                    color: Color.fromRGBO(0xC4, 0xC4, 0xC4, 0.5),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.add,
                        size: 48,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Edit Photos',
                        style: Theming.of(context)
                            .text
                            .body
                            .copyWith(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 80,
            height: 88,
            child: Builder(
              builder: (context) {
                if (widget.editable) {
                  return Consumer(
                    builder: (context, ref, child) {
                      final editableProfile = ref.watch(profileProvider);
                      return ProfileBio(
                        key: _audioBioKey,
                        name: editableProfile?.name,
                        birthday: editableProfile?.birthday,
                        url: editableProfile?.audio,
                        editable: true,
                        onRecorded: (audio) =>
                            uploadAudio(context: context, audio: audio),
                        onUpdateName: (name) {
                          updateName(
                            context: context,
                            name: name,
                          );
                        },
                      );
                    },
                  );
                } else {
                  return ProfileBio(
                    name: widget.publicProfile.name,
                    birthday: widget.publicProfile.birthday,
                    url: widget.publicProfile.audio,
                    editable: false,
                    onRecorded: (_) {},
                    onUpdateName: (_) {},
                  );
                }
              },
            ),
          ),
          Positioned(
            left: MediaQuery.of(context).padding.left + 16,
            bottom: MediaQuery.of(context).padding.bottom + 16,
            child: const BackButton(),
          ),
          Positioned(
            right: MediaQuery.of(context).padding.right + 16,
            bottom: MediaQuery.of(context).padding.bottom + 16,
            child: const HomeButton(
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class PublicProfileArguments {
  final PublicProfile publicProfile;
  final bool editable;

  PublicProfileArguments({
    required this.publicProfile,
    required this.editable,
  });
}
