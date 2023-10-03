import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/shell_page.dart';
import 'package:openup/widgets/background.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/photo_card.dart';
import 'package:openup/widgets/profile_display.dart';
import 'package:openup/widgets/scaffold.dart';

part 'view_profile_page.freezed.dart';

class ViewProfilePage extends ConsumerStatefulWidget {
  final ViewProfilePageArguments args;

  const ViewProfilePage({
    super.key,
    required this.args,
  });

  @override
  ConsumerState<ViewProfilePage> createState() => _ViewProfilePageState();
}

class _ViewProfilePageState extends ConsumerState<ViewProfilePage> {
  Profile? _profile;
  bool _play = true;

  final _profileBuilderKey = GlobalKey<ProfileBuilderState>();

  @override
  void initState() {
    super.initState();
    _init();
  }

  void _init() async {
    widget.args.when(
      profile: (profile) async {
        setState(() => _profile = profile);
        _playAudio();
      },
      uid: (uid) async {
        final profile = await _fetchProfile(uid);
        if (profile != null && mounted) {
          setState(() => _profile = profile);
          _playAudio();
        }
      },
    );
  }

  Future<Profile?> _fetchProfile(String uid) async {
    final api = ref.read(apiProvider);
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

  void _playAudio() => _profileBuilderKey.currentState?.play();

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: const OpenupAppBar(
        blurBackground: false,
        body: OpenupAppBarBody(
          leading: OpenupAppBarBackButtonOutlined(),
          center: Text('Profile View'),
        ),
      ),
      body: TextBackground(
        child: ActivePage(
          onActivate: () {
            setState(() => _play = true);
            _playAudio();
          },
          onDeactivate: () {
            setState(() => _play = false);
            _profileBuilderKey.currentState?.pause();
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Shimmer(
                linearGradient: kShimmerGradient,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (profile == null) {
                      return PhotoCardLoading(
                        width: constraints.maxWidth,
                        height: constraints.maxHeight,
                        useExtraTopPadding: true,
                      );
                    }
                    return ProfileBuilder(
                      key: _profileBuilderKey,
                      profile: profile,
                      play: _play,
                      builder: (context, playbackState, playbackInfoStream) {
                        return PhotoCardWiggle(
                          child: PhotoCardProfile(
                            width: constraints.maxWidth,
                            height: constraints.maxHeight,
                            profile: DiscoverProfile(
                              profile: profile,
                              location: const UserLocation(
                                latLong: LatLong(latitude: 0, longitude: 0),
                                radius: 20,
                                visibility: LocationVisibility.private,
                              ),
                              favorite: false,
                            ),
                            distance: 2,
                            playbackState: playbackState,
                            playbackInfoStream: playbackInfoStream,
                            onPlay: () => setState(() => _play = true),
                            onPause: () => setState(() => _play = false),
                            onMessage: () {},
                          ),
                        );
                      },
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

@freezed
class ViewProfilePageArguments with _$ViewProfilePageArguments {
  const factory ViewProfilePageArguments.profile({
    required Profile profile,
  }) = _Profile;

  const factory ViewProfilePageArguments.uid({
    required String uid,
  }) = _Uid;
}
