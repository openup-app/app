import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/platform/just_audio_audio_player.dart';
import 'package:openup/widgets/back_button.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/gallery.dart';

class InvitePage extends ConsumerStatefulWidget {
  final String uid;
  final Profile? profile;
  final String? invitationAudio;
  const InvitePage({
    super.key,
    required this.uid,
    this.profile,
    this.invitationAudio,
  });

  @override
  ConsumerState<InvitePage> createState() => _InvitationPageState();
}

class _InvitationPageState extends ConsumerState<InvitePage> {
  final _player = JustAudioAudioPlayer();

  Profile? _profile;
  String? _invitationAudio;
  bool _submittingReject = false;
  bool _submittingAccept = false;

  @override
  void initState() {
    super.initState();

    final api = GetIt.instance.get<Api>();

    _profile = widget.profile;
    _invitationAudio = widget.invitationAudio;
    if (_profile == null) {
      api.getProfile(widget.uid).then((result) {
        if (mounted) {
          result.fold(
            (l) => displayError(context, l),
            (r) => setState(() => _profile = r),
          );
        }
      });
    }

    if (_invitationAudio == null) {
      api
          .getMessages(ref.read(userProvider).uid, widget.uid, limit: 1)
          .then((result) {
        if (mounted) {
          result.fold(
            (l) => displayError(context, l),
            (r) {
              setState(() => _invitationAudio = r.last.content);
              _player.setUrl(_invitationAudio!);
              _player.play(loop: true);
            },
          );
        }
      });
    } else {
      _player.setUrl(_invitationAudio!);
      _player.play(loop: true);
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        context.goNamed('friendships');
        return Future.value(false);
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.fromRGBO(0x00, 0x00, 0x00, 1.0),
                Color.fromRGBO(0x6F, 0x00, 0x00, 1.0),
              ],
            ),
          ),
          child: SafeArea(
            child: Builder(builder: (context) {
              final profile = _profile;
              if (profile == null || _invitationAudio == null) {
                return const Center(
                  child: LoadingIndicator(),
                );
              }
              return Column(
                children: [
                  const SizedBox(height: 16),
                  Text(
                    'A personal invitation for you',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium!
                        .copyWith(fontSize: 24),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: BackIconButton(
                      onPressed: () => context.goNamed('friendships'),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OnlineIndicatorBuilder(
                        uid: profile.uid,
                        builder: (context, online) {
                          return online
                              ? const OnlineIndicator()
                              : const SizedBox.shrink();
                        },
                      ),
                      const SizedBox(width: 8),
                      Column(
                        children: [
                          AutoSizeText(
                            profile.name,
                            minFontSize: 16,
                            maxFontSize: 20,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          AutoSizeText(
                            profile.location,
                            minFontSize: 9,
                            maxFontSize: 16,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(fontWeight: FontWeight.w300),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 31),
                  Expanded(
                    child: Container(
                      clipBehavior: Clip.hardEdge,
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(24)),
                      ),
                      child: Gallery(
                        gallery: profile.gallery,
                        slideshow: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<PlaybackInfo>(
                    stream: _player.playbackInfoStream,
                    initialData: const PlaybackInfo(),
                    builder: (context, snapshot) {
                      final value = snapshot.requireData;
                      final position = value.position.inMilliseconds;
                      final duration = value.duration.inMilliseconds;
                      final ratio = duration == 0 ? 0.0 : position / duration;
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: ratio < 0 ? 0 : ratio,
                          child: Container(
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 32),
                            decoration: const BoxDecoration(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(3)),
                              color: Color.fromRGBO(0xD9, 0xD9, 0xD9, 1.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Color.fromRGBO(0x00, 0x00, 0x00, 0.25),
                                  blurRadius: 4,
                                  offset: Offset(0.0, 4.0),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 31),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Button(
                        onPressed: _submittingAccept || _submittingReject
                            ? null
                            : () async {
                                final uid = ref.read(userProvider).uid;
                                final api = GetIt.instance.get<Api>();
                                setState(() => _submittingAccept = true);
                                GetIt.instance
                                    .get<Mixpanel>()
                                    .track("accept_invite");
                                await api.acceptInvitation(uid, profile.uid);
                                if (mounted) {
                                  setState(() => _submittingAccept = false);
                                  context.goNamed(
                                    'chat',
                                    params: {'uid': profile.uid},
                                  );
                                }
                              },
                        child: Container(
                          width: 111,
                          height: 50,
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(28)),
                            color: Colors.white,
                          ),
                          alignment: Alignment.center,
                          child: _submittingAccept
                              ? const LoadingIndicator(size: 32)
                              : Text(
                                  'Accept',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium!
                                      .copyWith(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w300,
                                        color: Colors.black,
                                      ),
                                ),
                        ),
                      ),
                      Button(
                        onPressed: _submittingAccept || _submittingReject
                            ? null
                            : () async {
                                final uid = ref.read(userProvider).uid;
                                final api = GetIt.instance.get<Api>();
                                setState(() => _submittingReject = true);
                                GetIt.instance
                                    .get<Mixpanel>()
                                    .track("reject_invite");
                                await api.declineInvitation(uid, profile.uid);
                                if (mounted) {
                                  setState(() => _submittingReject = false);
                                  context.goNamed('friendships');
                                }
                              },
                        child: Container(
                          width: 111,
                          height: 50,
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(28)),
                            color: Colors.white,
                          ),
                          alignment: Alignment.center,
                          child: _submittingReject
                              ? const LoadingIndicator(size: 32)
                              : Text(
                                  'Reject',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium!
                                      .copyWith(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w300,
                                        color: Colors.black,
                                      ),
                                ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 31),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 291,
                      ),
                      child: Text(
                        'Accept and begin chatting now, reject and they can send you another message tomorrow.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w300,
                              color:
                                  const Color.fromRGBO(0xDE, 0xDE, 0xDE, 1.0),
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}

class InvitePageArgs {
  final Profile profile;
  final String invitaitonAudio;

  const InvitePageArgs(
    this.profile,
    this.invitaitonAudio,
  );
}
