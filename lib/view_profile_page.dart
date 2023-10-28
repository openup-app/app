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
import 'package:openup/widgets/record.dart';
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

  ProfileController? _controller;

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

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    return Scaffold(
      extendBodyBehindAppBar: false,
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
          onActivate: () {},
          onDeactivate: () {},
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
                      profile: profile,
                      onController: (controller) =>
                          setState(() => _controller = controller),
                      builder: (context, video, controller) {
                        return PhotoCardWiggle(
                          child: PhotoCardProfile(
                            width: constraints.maxWidth,
                            height: constraints.maxHeight,
                            profile: profile,
                            distance: 2,
                            playbackStream: controller.audioPlaybackStream,
                            onPlay: controller.play,
                            onPause: controller.pause,
                            onMessage: ref.watch(uidProvider) == profile.uid
                                ? () {}
                                : () => _showRecordPanel(context, profile.uid),
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

  void _showRecordPanel(BuildContext context, String uid) async {
    _pauseAudio();
    final userState = ref.read(userProvider);
    final signedIn = userState.map(
      guest: (_) => null,
      signedIn: (signedIn) => signedIn,
    );
    if (signedIn == null) {
      return;
    }

    final result = await showRecordPanel(
      context: context,
      title: const Text('Recording Message'),
      submitLabel: const Text('Tap to send'),
    );

    if (!mounted) {
      return;
    }
    if (result == null) {
      return;
    }

    final notifier = ref.read(userProvider.notifier);
    await withBlockingModal(
      context: context,
      label: 'Sending invite...',
      future: notifier.sendMessage(uid: uid, audio: result.audio),
    );
    notifier.refreshChatrooms();
  }

  void _playAudio() => _controller?.play();

  void _pauseAudio() => _controller?.pause();
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
