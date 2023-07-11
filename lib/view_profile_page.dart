import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:openup/analytics/analytics.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/chat_api.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/platform/just_audio_audio_player.dart';
import 'package:openup/shell_page.dart';
import 'package:openup/widgets/back_button.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/profile_display.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

part 'view_profile_page.freezed.dart';

class ViewProfilePage extends ConsumerStatefulWidget {
  final ViewProfilePageArguments args;

  const ViewProfilePage({
    super.key,
    required this.args,
  });

  @override
  ConsumerState<ViewProfilePage> createState() => _ViewCollectionPageState();
}

class _ViewCollectionPageState extends ConsumerState<ViewProfilePage> {
  Profile? _profile;

  final _player = JustAudioAudioPlayer();
  bool _play = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
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

  void _playAudio() {
    _player.stop();
    final audio = _profile?.audio;
    if (audio != null) {
      _player
        ..setUrl(audio)
        ..play(loop: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    return ActivePage(
      onActivate: () {
        setState(() => _play = true);
        _player.play();
      },
      onDeactivate: () {
        setState(() => _play = false);
        _player.stop();
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          Builder(
            builder: (context) {
              if (profile == null) {
                return const SizedBox.shrink();
              }
              return ClipRRect(
                clipBehavior: Clip.hardEdge,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
                child: Container(
                  margin: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 20,
                    bottom: 16 + MediaQuery.of(context).padding.bottom,
                  ),
                  clipBehavior: Clip.hardEdge,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(48)),
                  ),
                  child: ProfileDisplay(
                    profile: profile,
                    play: _play,
                    onPlayPause: () => setState(() => _play = !_play),
                    onRecord: () => _showRecordPanel(context, profile.uid),
                    onBlock: () {},
                  ),
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

  void _showRecordPanel(BuildContext context, String uid) async {
    final audio = await showModalBottomSheet<Uint8List>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return RecordPanelSurface(
          child: RecordPanel(
            onCancel: Navigator.of(context).pop,
            onSubmit: (audio, duration) {
              Navigator.of(context).pop(audio);
              return Future.value(true);
            },
          ),
        );
      },
    );

    if (audio == null || !mounted) {
      return;
    }

    ref.read(mixpanelProvider).track(
      "send_message",
      properties: {"type": "collection"},
    );

    final tempDir = await getTemporaryDirectory();
    final file = File(path.join(tempDir.path, 'chat.m4a'));
    await file.writeAsBytes(audio);
    if (!mounted) {
      return;
    }

    final api = ref.read(apiProvider);
    final future = api.sendMessage(uid, ChatType.audio, file.path);
    await withBlockingModal(
      context: context,
      label: 'Sending message...',
      future: future,
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
