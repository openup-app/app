import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:openup/api/users/profile.dart';
import 'package:openup/platform/just_audio_audio_player.dart';
import 'package:openup/profile_screen.dart';
import 'package:openup/share_page.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/theming.dart';

class ProfileView extends StatefulWidget {
  final Profile profile;
  final DateTime? endTime;

  const ProfileView({
    Key? key,
    required this.profile,
    this.endTime,
  }) : super(key: key);

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final _player = JustAudioAudioPlayer();

  @override
  void initState() {
    super.initState();
    final audio = widget.profile.audio;
    if (audio != null) {
      _player.setUrl(audio);
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
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            clipBehavior: Clip.hardEdge,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            foregroundDecoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black,
                ],
                stops: [
                  0.4,
                  1.0,
                ],
              ),
            ),
            child: Gallery(
              gallery: widget.profile.gallery,
              withWideBlur: false,
              slideshow: true,
              blurPhotos: widget.profile.blurPhotos,
            ),
          ),
        ),
        if (widget.endTime != null)
          Align(
            alignment: Alignment.topRight,
            child: Column(
              children: [
                const SizedBox(height: 16),
                ReportBlockPopupMenu(
                  uid: widget.profile.uid,
                  name: widget.profile.name,
                  onBlock: () {},
                  onReport: () {},
                ),
                _ShareButton(
                  profile: widget.profile,
                ),
              ],
            ),
          ),
        Positioned(
          left: 24,
          right: 24,
          bottom: 0,
          height: 93,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StreamBuilder<PlaybackInfo>(
                stream: _player.playbackInfoStream,
                initialData: const PlaybackInfo(),
                builder: (context, snapshot) {
                  final value = snapshot.requireData;
                  final position = value.position.inMilliseconds;
                  final duration = value.duration.inMilliseconds;
                  final ratio = duration == 0 ? 0.0 : position / duration;
                  return FractionallySizedBox(
                    widthFactor: ratio < 0 ? 0 : ratio,
                    alignment: Alignment.centerLeft,
                    child: Container(
                      height: 13,
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(3)),
                        color: Color.fromRGBO(0xD9, 0xD9, 0xD9, 1.0),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AutoSizeText(
                          widget.profile.name,
                          maxFontSize: 26,
                          style: Theming.of(context).text.body,
                        ),
                        Text(
                          widget.profile.location,
                          style: Theming.of(context).text.body.copyWith(
                              fontSize: 16, fontWeight: FontWeight.w300),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (widget.endTime == null)
                        _ShareButton(
                          profile: widget.profile,
                        )
                      else
                        CountdownTimer(
                          endTime: widget.endTime!,
                          onDone: () {},
                          style: Theming.of(context).text.body.copyWith(
                              fontSize: 20, fontWeight: FontWeight.w300),
                        ),
                      Text(
                        topicLabel(widget.profile.topic),
                        style: Theming.of(context).text.body.copyWith(
                            fontSize: 20, fontWeight: FontWeight.w400),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ShareButton extends StatelessWidget {
  final Profile profile;
  const _ShareButton({
    Key? key,
    required this.profile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Button(
      onPressed: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (context) {
            return Theming(
              child: SharePage(
                profile: profile,
                location: profile.location,
              ),
            );
          },
        );
      },
      child: const Padding(
        padding: EdgeInsets.all(8.0),
        child: Icon(
          Icons.reply,
          color: Colors.white,
          size: 32,
          textDirection: TextDirection.rtl,
        ),
      ),
    );
  }
}
