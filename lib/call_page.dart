import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/call_manager.dart';
import 'package:openup/api/signaling/phone.dart';
import 'package:openup/api/users/profile.dart';
import 'package:openup/main.dart';
import 'package:openup/widgets/back_button.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/theming.dart';

class CallPage extends StatefulWidget {
  const CallPage({Key? key}) : super(key: key);

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  ActiveCall? _activeCall;
  late final StreamSubscription _callStateSubscription;
  SimpleProfile? _endedProfile;
  bool _ended = true;
  Timer? _popSoonTimer;
  bool _gettingLocation = false;
  String _location = '';

  @override
  void initState() {
    super.initState();
    final callManager = GetIt.instance.get<CallManager>();
    callManager.callPageActive = true;
    _callStateSubscription = callManager.callState.listen((event) {
      debugPrint('[Calling] CallState event: ${event.runtimeType}');
      event.when(
        none: () {},
        initializing: (profile, __, ___) {
          if (!_gettingLocation) {
            _createLocationFuture(profile.uid);
          }
        },
        engaged: (_, __) {
          _popSoon();
        },
        active: (activeCall) {
          setState(() {
            if (!_gettingLocation) {
              _createLocationFuture(activeCall.profile.uid);
            }
            _activeCall = activeCall;
          });
        },
        ended: (profile) {
          setState(() {
            _ended = true;
            _endedProfile = profile;
          });
          _popSoon();
        },
      );
    });
  }

  void _createLocationFuture(String uid) async {
    if (!_gettingLocation) {
      setState(() => _gettingLocation = true);
      final api = GetIt.instance.get<Api>();
      final result = await api.getProfile(uid);
      if (!mounted) {
        return;
      }
      result.fold((l) {}, (r) {
        setState(() => _location = r.location);
      });
    }
  }

  @override
  void dispose() {
    _popSoonTimer?.cancel();
    _callStateSubscription.cancel();
    GetIt.instance.get<CallManager>().callPageActive = false;
    super.dispose();
  }

  void _popSoon() {
    _popSoonTimer ??= Timer(const Duration(seconds: 3), () {
      rootNavigatorKey.currentState?.pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final callManager = GetIt.instance.get<CallManager>();
    return StreamBuilder<CallState>(
      initialData: const CallState.none(),
      stream: callManager.callState,
      builder: (context, snapshot) {
        final callState = snapshot.requireData;
        return callState.when(
          none: () {
            final endedProfile = _endedProfile;
            if (_ended && endedProfile != null) {
              return _UnconnectedDisplay(
                profile: endedProfile,
                location: _location,
                label: 'call ended',
                speakerphoneEnabled: false,
                micEnabled: true,
                videoEnabled: false,
                onToggleSpeakerphone: null,
                onToggleMic: null,
                onToggleVideo: null,
                onHangUp: _onHangUp,
              );
            }
            return Container(
              color: Colors.black,
            );
          },
          initializing: (profile, outgoing, video) {
            if (outgoing) {
              return _UnconnectedDisplay(
                profile: profile,
                location: _location,
                label: 'ringing...',
                speakerphoneEnabled: false,
                micEnabled: true,
                videoEnabled: video,
                onToggleSpeakerphone: _onToggleSpeakerphone,
                onToggleMic: _onToggleMic,
                onToggleVideo: _onToggleVideo,
                onHangUp: _onHangUp,
              );
            }
            return _UnconnectedDisplay(
              profile: profile,
              location: _location,
              label: 'connecting...',
              speakerphoneEnabled: false,
              micEnabled: true,
              videoEnabled: video,
              onToggleSpeakerphone: null,
              onToggleMic: null,
              onToggleVideo: null,
              onHangUp: _onHangUp,
            );
          },
          engaged: (profile, video) {
            return _UnconnectedDisplay(
              profile: profile,
              location: _location,
              label: '${profile.name} is in another call',
              speakerphoneEnabled: false,
              micEnabled: true,
              videoEnabled: video,
              onToggleSpeakerphone: null,
              onToggleMic: null,
              onToggleVideo: null,
              onHangUp: _onHangUp,
            );
          },
          active: (call) {
            return StreamBuilder<PhoneConnectionState>(
              stream: call.phone.connectionStateStream,
              initialData: PhoneConnectionState.none,
              builder: (context, value) {
                final state = value.requireData;
                switch (state) {
                  case PhoneConnectionState.none:
                  case PhoneConnectionState.missing:
                  case PhoneConnectionState.waiting:
                  case PhoneConnectionState.declined:
                  case PhoneConnectionState.complete:
                    return _UnconnectedDisplay(
                      profile: call.profile,
                      location: _location,
                      label: _stateToMessage(state),
                      speakerphoneEnabled: false,
                      micEnabled: true,
                      videoEnabled: call.controller.video,
                      onToggleSpeakerphone: _onToggleSpeakerphone,
                      onToggleMic: _onToggleMic,
                      onToggleVideo: _onToggleVideo,
                      onHangUp: _onHangUp,
                    );
                  case PhoneConnectionState.connecting:
                  case PhoneConnectionState.connected:
                    return ValueListenableBuilder<PhoneValue>(
                      valueListenable: _activeCall!.controller,
                      builder: (context, value, child) {
                        return _CallDisplay(
                          activeCall: _activeCall!,
                          speakerphoneEnabled: value.speakerphone,
                          micEnabled: !value.mute,
                          videoEnabled: value.video,
                          onToggleSpeakerphone: _onToggleSpeakerphone,
                          onToggleMic: _onToggleMic,
                          onToggleVideo: _onToggleVideo,
                          onHangUp: _onHangUp,
                        );
                      },
                    );
                }
              },
            );
          },
          ended: (profile) {
            return _UnconnectedDisplay(
              profile: profile,
              location: _location,
              label: 'call ended',
              speakerphoneEnabled: false,
              micEnabled: true,
              videoEnabled: false,
              onToggleSpeakerphone: null,
              onToggleMic: null,
              onToggleVideo: null,
              onHangUp: _onHangUp,
            );
          },
        );
      },
    );
  }

  void _onToggleSpeakerphone() {
    final phone = _activeCall?.phone;
    final value = _activeCall?.controller.value;
    if (phone != null && value != null) {
      phone.speakerphone = !value.speakerphone;
    }
  }

  void _onToggleMic() {
    final phone = _activeCall?.phone;
    final value = _activeCall?.controller.value;
    if (phone != null && value != null) {
      phone.mute = !value.mute;
    }
  }

  void _onToggleVideo() {
    final phone = _activeCall?.phone;
    final value = _activeCall?.controller.value;
    if (phone != null && value != null) {
      phone.videoEnabled = !value.video;
    }
  }

  void _onHangUp() {
    rootNavigatorKey.currentState?.pop();
    GetIt.instance.get<CallManager>().hangUp();
  }

  String _stateToMessage(PhoneConnectionState state) {
    switch (state) {
      case PhoneConnectionState.none:
        return '';
      case PhoneConnectionState.missing:
        return 'the call has already ended';
      case PhoneConnectionState.waiting:
        return 'ringing...';
      case PhoneConnectionState.declined:
        return 'declined';
      case PhoneConnectionState.complete:
        return 'call complete';
      case PhoneConnectionState.connecting:
        return 'connecting';
      case PhoneConnectionState.connected:
        return 'connected';
    }
  }
}

class _UnconnectedDisplay extends StatelessWidget {
  final SimpleProfile profile;
  final String location;
  final String label;
  final bool speakerphoneEnabled;
  final bool micEnabled;
  final bool videoEnabled;
  final VoidCallback? onToggleSpeakerphone;
  final VoidCallback? onToggleMic;
  final VoidCallback? onToggleVideo;
  final VoidCallback onHangUp;

  const _UnconnectedDisplay({
    Key? key,
    required this.profile,
    required this.location,
    required this.label,
    required this.speakerphoneEnabled,
    required this.micEnabled,
    required this.videoEnabled,
    required this.onToggleSpeakerphone,
    required this.onToggleMic,
    required this.onToggleVideo,
    required this.onHangUp,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: const BackIconButton(),
        centerTitle: true,
        title: Column(
          children: [
            Text(
              profile.name,
              style: Theming.of(context)
                  .text
                  .body
                  .copyWith(fontSize: 24, fontWeight: FontWeight.w600),
            ),
            Text(
              location,
              style: Theming.of(context)
                  .text
                  .body
                  .copyWith(fontSize: 16, fontWeight: FontWeight.w300),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          const Spacer(),
          Container(
            width: 200,
            height: 200,
            clipBehavior: Clip.hardEdge,
            decoration: const BoxDecoration(shape: BoxShape.circle),
            child: ProfileImage(
              profile.photo,
              blur: profile.blurPhotos,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            profile.name,
            textAlign: TextAlign.center,
            style: Theming.of(context)
                .text
                .body
                .copyWith(fontSize: 36, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 14),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theming.of(context)
                .text
                .body
                .copyWith(fontSize: 24, fontWeight: FontWeight.w300),
          ),
          const Spacer(),
          _CallControls(
            speakerphoneEnabled: speakerphoneEnabled,
            micEnabled: micEnabled,
            videoEnabled: videoEnabled,
            onToggleSpeakerphone: onToggleSpeakerphone,
            onToggleMic: onToggleMic,
            onToggleVideo: onToggleVideo,
            onHangUp: onHangUp,
            brightness: Brightness.dark,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: MediaQuery.of(context).padding.bottom,
          ),
        ],
      ),
    );
  }
}

class _CallDisplay extends StatefulWidget {
  final ActiveCall activeCall;
  final bool speakerphoneEnabled;
  final bool micEnabled;
  final bool videoEnabled;
  final VoidCallback? onToggleSpeakerphone;
  final VoidCallback? onToggleMic;
  final VoidCallback? onToggleVideo;
  final VoidCallback onHangUp;

  const _CallDisplay({
    Key? key,
    required this.activeCall,
    required this.speakerphoneEnabled,
    required this.micEnabled,
    required this.videoEnabled,
    required this.onToggleSpeakerphone,
    required this.onToggleMic,
    required this.onToggleVideo,
    required this.onHangUp,
  }) : super(key: key);

  @override
  State<_CallDisplay> createState() => __CallDisplayState();
}

class __CallDisplayState extends State<_CallDisplay> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.black,
        title: Column(
          children: [
            Text(
              widget.activeCall.profile.name,
              style: Theming.of(context)
                  .text
                  .body
                  .copyWith(fontSize: 24, fontWeight: FontWeight.w600),
            ),
            Text(
              'Fort Worth, Texas',
              style: Theming.of(context)
                  .text
                  .body
                  .copyWith(fontSize: 16, fontWeight: FontWeight.w300),
            ),
          ],
        ),
        leading: const BackIconButton(),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 4),
          Center(
            child: SizedBox(
              height: 36,
              child: StreamBuilder<PhoneConnectionState>(
                initialData: PhoneConnectionState.none,
                stream: widget.activeCall.phone.connectionStateStream,
                builder: (context, snapshot) {
                  final state = snapshot.requireData;
                  if (state == PhoneConnectionState.connecting) {
                    return Text(
                      'connecting...',
                      style: Theming.of(context)
                          .text
                          .body
                          .copyWith(fontSize: 24, fontWeight: FontWeight.w300),
                    );
                  } else if (state == PhoneConnectionState.connected) {
                    return CountUpTimer(
                      start: widget.activeCall.controller.startTime,
                      style: Theming.of(context)
                          .text
                          .body
                          .copyWith(fontSize: 24, fontWeight: FontWeight.w300),
                    );
                  } else {
                    return const SizedBox.shrink();
                  }
                },
              ),
            ),
          ),
          Expanded(
            child: Container(
              clipBehavior: Clip.hardEdge,
              margin: const EdgeInsets.symmetric(vertical: 20),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(51)),
              ),
              child: ProfileImage(
                widget.activeCall.profile.photo,
                blur: widget.activeCall.profile.blurPhotos,
              ),
            ),
          ),
          _CallControls(
            speakerphoneEnabled: widget.speakerphoneEnabled,
            micEnabled: widget.micEnabled,
            videoEnabled: widget.videoEnabled,
            onToggleSpeakerphone: widget.onToggleSpeakerphone,
            onToggleMic: widget.onToggleMic,
            onToggleVideo: widget.onToggleVideo,
            onHangUp: widget.onHangUp,
            brightness: Brightness.dark,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: MediaQuery.of(context).padding.bottom,
          ),
        ],
      ),
    );
  }
}

class _CallControls extends StatelessWidget {
  final bool speakerphoneEnabled;
  final bool micEnabled;
  final bool videoEnabled;
  final VoidCallback? onToggleSpeakerphone;
  final VoidCallback? onToggleMic;
  final VoidCallback? onToggleVideo;
  final VoidCallback onHangUp;
  final Brightness brightness;

  const _CallControls({
    Key? key,
    required this.speakerphoneEnabled,
    required this.micEnabled,
    required this.videoEnabled,
    required this.onToggleSpeakerphone,
    required this.onToggleMic,
    required this.onToggleVideo,
    required this.onHangUp,
    this.brightness = Brightness.dark,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _BarButton(
          onPressed: onToggleSpeakerphone,
          icon: speakerphoneEnabled
              ? const Icon(Icons.volume_up, size: 36)
              : const Icon(Icons.volume_off, size: 36),
          brightness: brightness,
          selected: speakerphoneEnabled,
        ),
        _BarButton(
          onPressed: onToggleVideo,
          icon: videoEnabled
              ? const Icon(Icons.videocam, size: 36)
              : const Icon(Icons.videocam_off, size: 36),
          brightness: brightness,
          selected: videoEnabled,
        ),
        _BarButton(
          onPressed: onToggleMic,
          icon: micEnabled
              ? const Icon(Icons.mic, size: 36)
              : const Icon(Icons.mic_off, size: 36),
          brightness: brightness,
          selected: micEnabled,
        ),
        _BarButton(
          icon: const Icon(Icons.call_end, size: 36),
          color: const Color.fromRGBO(0xFF, 0x00, 0x00, 1.0),
          selected: false,
          brightness: Brightness.dark,
          onPressed: onHangUp,
        ),
      ],
    );
  }
}

class _BarButton extends StatelessWidget {
  final Widget icon;
  final Brightness brightness;
  final Color? color;
  final bool selected;
  final VoidCallback? onPressed;
  const _BarButton({
    Key? key,
    required this.icon,
    required this.brightness,
    this.color,
    required this.selected,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Button(
      onPressed: onPressed,
      child: Container(
        width: 80,
        height: 58,
        clipBehavior: Clip.hardEdge,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9),
          color: color ??
              (brightness == Brightness.dark
                  ? (selected
                      ? const Color.fromRGBO(0x32, 0x32, 0x32, 1.0)
                      : const Color.fromRGBO(0x16, 0x16, 0x16, 1.0))
                  : (selected
                      ? Colors.white
                      : const Color.fromRGBO(0x16, 0x16, 0x16, 1.0))),
        ),
        child: IconTheme(
          data: brightness == Brightness.dark || !selected
              ? IconTheme.of(context).copyWith(color: Colors.white)
              : IconTheme.of(context).copyWith(color: Colors.black),
          child: icon,
        ),
      ),
    );
  }
}
