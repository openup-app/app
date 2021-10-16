import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openup/api/users/users_api.dart';
import 'package:openup/util/users_api_util.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/home_button.dart';
import 'package:openup/widgets/profile_audio_bio.dart';
import 'package:openup/widgets/theming.dart';

class PublicProfileScreen extends ConsumerStatefulWidget {
  const PublicProfileScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PublicProfileScreen> createState() =>
      _PublicProfileScreenState();
}

class _PublicProfileScreenState extends ConsumerState<PublicProfileScreen> {
  final _audioBioKey = GlobalKey<ProfileAudioBioState>();
  final _pageController = PageController(initialPage: 10000);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usersApi = ref.watch(usersApiProvider);
    return Stack(
      children: [
        Positioned.fill(
          child: PageView.builder(
            controller: _pageController,
            itemBuilder: (context, index) {
              final gallery = usersApi.publicProfile?.gallery ?? [];
              if (gallery.isEmpty) {
                return const SizedBox.shrink();
              }
              final i = index % gallery.length;
              return Image.network(
                gallery[i],
                fit: BoxFit.cover,
              );
            },
          ),
        ),
        Positioned(
          right: MediaQuery.of(context).padding.right + 16,
          top: MediaQuery.of(context).padding.top + 16,
          child: Button(
            onPressed: () {
              final state = _audioBioKey.currentState;
              state?.stopAll();
              Navigator.of(context).pushNamed('public-profile-edit');
            },
            child: Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(40)),
                color: Colors.black.withOpacity(0.3),
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
                    style: Theming.of(context).text.body.copyWith(fontSize: 14),
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
          child: Consumer(builder: (context, ref, child) {
            final audio = ref
                .watch(profileProvider.select((value) => value.state?.audio));
            return ProfileAudioBio(
              key: _audioBioKey,
              url: audio,
              onRecorded: (audio) =>
                  uploadAudio(context: context, audio: audio),
              onNameUpdated: (name) => updateName(context: context, name: name),
              onDescriptionUpdated: (desc) =>
                  updateDescription(context: context, description: desc),
            );
          }),
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
    );
  }
}
