import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:openup/api/signaling/signaling.dart';
import 'package:openup/api/signaling/socket_io_signaling_channel.dart';
import 'package:openup/api/users/profile.dart';
import 'package:openup/api/users/rekindle.dart';
import 'package:openup/rekindle_screen.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/api/signaling/phone.dart';
import 'package:openup/widgets/slide_control.dart';
import 'package:openup/widgets/theming.dart';
import 'package:openup/widgets/time_remaining.dart';

class VoiceCallScreen extends StatefulWidget {
  final String uid;
  final String host;
  final int socketPort;
  final bool initiator;
  final List<PublicProfile> profiles;
  final List<Rekindle> rekindles;

  const VoiceCallScreen({
    Key? key,
    required this.uid,
    required this.host,
    required this.socketPort,
    required this.initiator,
    required this.profiles,
    required this.rekindles,
  }) : super(key: key);

  @override
  State<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen> {
  late final SignalingChannel _signalingChannel;
  late final Phone _phone;

  RTCVideoRenderer? _remoteRenderer;
  bool _muted = false;
  bool _speakerphone = false;

  bool _hasSentTimeRequest = false;
  late DateTime _endTime;

  @override
  void initState() {
    _signalingChannel = SocketIoSignalingChannel(
      host: widget.host,
      port: widget.socketPort,
      uid: widget.uid,
    );
    _phone = Phone(
      useVideo: false,
      signalingChannel: _signalingChannel,
      onMediaRenderers: (_, remoteRenderer) {
        setState(() {
          _remoteRenderer = remoteRenderer;
        });
      },
      onRemoteStream: (stream) {
        setState(() => _remoteRenderer?.srcObject = stream);
      },
      onAddTimeRequest: () {
        setState(() => _hasSentTimeRequest = false);
      },
      onAddTime: _addTime,
      onDisconnected: _navigateToRekindle,
      onToggleMute: (muted) => setState(() => _muted = muted),
      onToggleSpeakerphone: (enabled) =>
          setState(() => _speakerphone = enabled),
    );

    if (widget.initiator) {
      _phone.call();
    } else {
      _phone.answer();
    }

    _endTime = DateTime.now().add(const Duration(seconds: 90));

    super.initState();
  }

  @override
  void dispose() {
    _signalingChannel.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profiles.first;
    final photo = profile.photo;
    return Stack(
      alignment: Alignment.center,
      fit: StackFit.expand,
      children: [
        ImageFiltered(
          imageFilter: ImageFilter.blur(
            sigmaX: 8.0,
            sigmaY: 8.0,
          ),
          child: photo != null
              ? Image.network(
                  photo,
                  fit: BoxFit.cover,
                )
              : Image.asset(
                  'assets/images/profile.png',
                  fit: BoxFit.fitHeight,
                ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(0xAA, 0x02, 0x4A, 0x5A),
                Color.fromARGB(0xAA, 0x9C, 0xED, 0xFF),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 40),
              SafeArea(
                top: true,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(
                      Radius.circular(48),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theming.of(context).shadow,
                        offset: const Offset(0.0, 4.0),
                        blurRadius: 2,
                      ),
                    ],
                    color: const Color.fromARGB(0xAA, 0x01, 0x55, 0x67),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              _ButtonWithText(
                                icon: const Icon(Icons.alarm_add),
                                label: 'add time',
                                onPressed: _hasSentTimeRequest
                                    ? null
                                    : _sendTimeRequest,
                              ),
                              const SizedBox(width: 30),
                            ],
                          ),
                          Text(
                            profile.name,
                            style: Theming.of(context).text.headline,
                          ),
                          TimeRemaining(
                            endTime: _endTime,
                            onTimeUp: _navigateToRekindle,
                            builder: (context, remaining) {
                              return Text(
                                remaining,
                                style: Theming.of(context).text.body,
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _ButtonWithText(
                            icon: const Icon(Icons.person_add),
                            label: 'Connect',
                            onPressed: () {},
                          ),
                          _ButtonWithText(
                            icon: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Image.asset('assets/images/report.png'),
                            ),
                            label: 'Report',
                            onPressed: () {},
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _ButtonWithText(
                            icon: _muted
                                ? const Icon(Icons.mic_off)
                                : const Icon(Icons.mic),
                            label: 'Mute',
                            onPressed: _phone.toggleMute,
                          ),
                          _ButtonWithText(
                            icon: Icon(
                              Icons.volume_up,
                              color: _speakerphone
                                  ? const Color.fromARGB(0xFF, 0x00, 0xFF, 0x19)
                                  : null,
                            ),
                            label: 'Speaker',
                            onPressed: _phone.toggleSpeakerphone,
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              SlideControl(
                thumbContents: Icon(
                  Icons.call_end,
                  color: Theming.of(context).friendBlue4,
                  size: 40,
                ),
                trackContents: const Text('slide to end call'),
                trackColor: const Color.fromARGB(0xFF, 0x01, 0x55, 0x67),
                onSlideComplete: () {
                  _signalingChannel.send(const HangUp());
                  _navigateToRekindle();
                },
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ],
    );
  }

  void _sendTimeRequest() {
    if (!_hasSentTimeRequest) {
      setState(() => _hasSentTimeRequest = true);
      _signalingChannel.send(const AddTimeRequest());
    }
  }

  void _addTime(Duration duration) {
    setState(() {
      _endTime = _endTime.add(duration);
      _hasSentTimeRequest = false;
    });
  }

  void _navigateToRekindle() {
    if (widget.rekindles.isEmpty) {
      Navigator.pop(context);
    } else {
      Navigator.of(context).pushReplacementNamed(
        'precached-rekindle',
        arguments: PrecachedRekindleScreenArguments(
          rekindles: widget.rekindles,
          title: 'meet people',
        ),
      );
    }
  }
}

class _ButtonWithText extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback? onPressed;

  const _ButtonWithText({
    Key? key,
    required this.icon,
    required this.label,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Button(
      onPressed: onPressed,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 48,
              maxHeight: 48,
            ),
            child: IconTheme(
              data: IconTheme.of(context).copyWith(size: 48),
              child: icon,
            ),
          ),
          const SizedBox(height: 10),
          Text(label, style: Theming.of(context).text.button),
        ],
      ),
    );
  }
}
