import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:go_router/go_router.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/shell_page.dart';
import 'package:openup/widgets/back_button.dart';
import 'package:openup/widgets/profile_display.dart';

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
    return ActivePage(
      onActivate: () {
        setState(() => _play = true);
        _playAudio();
      },
      onDeactivate: () {
        setState(() => _play = false);
        _profileBuilderKey.currentState?.pause();
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          Builder(
            builder: (context) {
              if (profile == null) {
                return const SizedBox.shrink();
              }
              return ColoredBox(
                color: Colors.white,
                child: ProfileBuilder(
                  key: _profileBuilderKey,
                  profile: _profile,
                  play: _play,
                  builder: (context, playbackState, playbackInfoStream) {
                    return ProfileDisplayBehavior(
                      profile: profile,
                      profileBuilderKey: _profileBuilderKey,
                      useBackIconForCloseButton: false,
                      playbackState: playbackState,
                      playbackInfoStream: playbackInfoStream,
                      onReportedOrBlocked: () {
                        context.go('/');
                      },
                    );
                  },
                ),
              );
            },
          ),
          Positioned(
            left: 16 + 20,
            top: 24 + 20,
            child: Row(
              children: [
                ProfileButton(
                  onPressed: Navigator.of(context).pop,
                  icon: const BackIcon(
                    color: Colors.black,
                    size: 24,
                  ),
                  size: 29,
                ),
              ],
            ),
          ),
        ],
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
