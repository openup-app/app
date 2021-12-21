import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:just_audio/just_audio.dart';
import 'package:openup/platform/just_audio_audio_player.dart';
import 'package:openup/platform/record_audio_recorder.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/theming.dart';

class ProfileBio extends StatefulWidget {
  final String? name;
  final DateTime? birthday;
  final String? description;
  final String? url;
  final bool editable;
  final void Function(Uint8List newBio) onRecorded;
  final void Function(String name, String description) onNameDescriptionUpdated;

  const ProfileBio({
    Key? key,
    required this.name,
    required this.birthday,
    required this.description,
    required this.url,
    required this.editable,
    required this.onRecorded,
    required this.onNameDescriptionUpdated,
  }) : super(key: key);

  @override
  ProfileBioState createState() => ProfileBioState();
}

class ProfileBioState extends State<ProfileBio> {
  final _audio = JustAudioAudioPlayer();
  final _recorder = RecordAudioRecorder();

  PlaybackInfo _playbackInfo = const PlaybackInfo();
  bool _recording = false;

  @override
  void initState() {
    super.initState();
    _audio.playbackInfoStream.listen((info) {
      if (_playbackInfo != info) {
        setState(() => _playbackInfo = info);
      }
    });
    final url = widget.url;
    if (url != null) {
      _setAudioUrl(url);
    }
  }

  @override
  void dispose() {
    _audio.dispose();
    _recorder.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ProfileBio oldWidget) {
    super.didUpdateWidget(oldWidget);
    final uri = widget.url;
    if (oldWidget.url != widget.url && uri != null) {
      _setAudioUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final playButtonState = _playbackInfo.state == PlaybackState.disabled
        ? PlayButtonState.none
        : (_playbackInfo.state == PlaybackState.loading
            ? PlayButtonState.loading
            : (_playbackInfo.state == PlaybackState.playing
                ? PlayButtonState.playing
                : PlayButtonState.paused));
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: _ProfileBioDisplay(
        name: widget.name,
        birthday: widget.birthday,
        description: widget.description,
        playButton: playButtonState,
        recording: _recording,
        editable: widget.editable,
        progress: _playbackInfo.position.inMilliseconds /
            (_playbackInfo.duration.inMilliseconds == 0
                ? 1
                : _playbackInfo.duration.inMilliseconds),
        onPlay: () => _audio.play(),
        onPause: () => _audio.pause(),
        onRecord: () async {
          if (await _recorder.start()) {
            setState(() => _recording = true);
          }
        },
        onRecordComplete: () async {
          final output = await _recorder.stop();
          setState(() => _recording = false);
          if (output != null) {
            widget.onRecorded(output);
          }
        },
        onNameDescriptionUpdated: widget.onNameDescriptionUpdated,
      ),
    );
  }

  void _setAudioUrl(String url) {
    try {
      _audio.setUrl(url);
    } on PlayerInterruptedException {
      // Nothing to do
    }
  }

  void stopAll() {
    _audio.pause();
    _recorder.stop();
    setState(() => _recording = false);
  }
}

class _ProfileBioDisplay extends ConsumerWidget {
  final String? name;
  final DateTime? birthday;
  final String? description;
  final PlayButtonState playButton;
  final bool recording;
  final bool editable;
  final double progress;
  final VoidCallback onPlay;
  final VoidCallback onPause;
  final VoidCallback onRecord;
  final VoidCallback onRecordComplete;
  final void Function(String name, String description) onNameDescriptionUpdated;

  const _ProfileBioDisplay({
    Key? key,
    required this.name,
    required this.birthday,
    required this.description,
    required this.playButton,
    required this.recording,
    required this.editable,
    required this.progress,
    required this.onPlay,
    required this.onPause,
    required this.onRecord,
    required this.onRecordComplete,
    required this.onNameDescriptionUpdated,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final age =
        DateTime.now().difference(birthday ?? DateTime.now()).inDays ~/ 365;
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Theming.of(context).shadow,
            blurRadius: 4,
            offset: const Offset(0.0, 2.0),
          ),
        ],
        gradient: LinearGradient(
          colors: [
            Colors.red.withOpacity(0.6),
            Colors.white.withOpacity(0.6),
          ],
          stops: [progress, progress],
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 24),
          Expanded(
            child: IgnorePointer(
              ignoring: !editable,
              child: Button(
                onPressed: () => _showNameDescriptionDialog(context, ref),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name == null ? '' : '$name, $age',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theming.of(context).text.headline.copyWith(
                        fontSize: 28,
                        shadows: [
                          Shadow(
                            color: Theming.of(context).shadow,
                            blurRadius: 4,
                            offset: const Offset(0.0, 2.0),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      description ?? 'My Description Here',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theming.of(context).text.bodySecondary.copyWith(
                        fontSize: 20,
                        shadows: [
                          Shadow(
                            color: Theming.of(context).shadow,
                            blurRadius: 4,
                            offset: const Offset(0.0, 2.0),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (editable)
            Button(
              onPressed: playButton == PlayButtonState.playing
                  ? null
                  : (recording ? onRecordComplete : onRecord),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(0xFF, 0xFF, 0x00, 0x00),
                  shape: recording ? BoxShape.rectangle : BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Theming.of(context).shadow,
                      blurRadius: 4,
                      offset: const Offset(0.0, 2.0),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(width: 28),
          IgnorePointer(
            ignoring: recording,
            child: Button(
              onPressed: (recording ||
                      playButton == PlayButtonState.loading ||
                      playButton == PlayButtonState.none)
                  ? null
                  : (playButton == PlayButtonState.playing ? onPause : onPlay),
              child: SizedBox(
                width: 48,
                height: 48,
                child: playButton == PlayButtonState.loading
                    ? const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(),
                      )
                    : (playButton == PlayButtonState.playing
                        ? Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: SvgPicture.asset(
                                'assets/images/pause_icon.svg'),
                          )
                        : Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child:
                                SvgPicture.asset('assets/images/play_icon.svg'),
                          )),
              ),
            ),
          ),
          const SizedBox(width: 20),
        ],
      ),
    );
  }

  void _showNameDescriptionDialog(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<_NameDescription>(
      context: context,
      builder: (context) {
        return _NameDescriptionDialogContents(
          initialName: name ?? '',
          initialDescription: description ?? '',
        );
      },
    );

    if (result != null) {
      onNameDescriptionUpdated(result.name, result.description);
    }
  }
}

enum PlayButtonState { playing, paused, loading, none }

class _NameDescriptionDialogContents extends StatefulWidget {
  final String initialName;
  final String initialDescription;

  const _NameDescriptionDialogContents({
    Key? key,
    required this.initialName,
    required this.initialDescription,
  }) : super(key: key);

  @override
  _NameDescriptionStateDialogContents createState() =>
      _NameDescriptionStateDialogContents();
}

class _NameDescriptionStateDialogContents
    extends State<_NameDescriptionDialogContents> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _descriptionController =
        TextEditingController(text: widget.initialDescription);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Update info'),
      actions: [
        TextButton(
          onPressed: Navigator.of(context).pop,
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (_formKey.currentState?.validate() == true) {
              Navigator.of(context).pop(
                _NameDescription(
                  _nameController.text.trim(),
                  _descriptionController.text.trim(),
                ),
              );
            }
          },
          child: const Text('Save'),
        ),
      ],
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.always,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.sentences,
                validator: _validateName,
                decoration: const InputDecoration(
                  label: Text('Name'),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                textCapitalization: TextCapitalization.sentences,
                validator: _validateDescription,
                decoration: const InputDecoration(
                  label: Text('Description'),
                  hintText: 'Three Words Only',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Enter a name';
    }
  }

  String? _validateDescription(String? value) {
    if (value == null) {
      return 'Enter a description';
    }

    if (value.isEmpty) {
      return 'Enter a description';
    }

    if (value.trim().split(' ').length > 3) {
      return 'Enter up to three words';
    }
  }
}

class _NameDescription {
  final String name;
  final String description;

  _NameDescription(this.name, this.description);
}
