import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:get_it/get_it.dart';
import 'package:lottie/lottie.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/call_state.dart';
import 'package:openup/api/signaling/phone.dart';
import 'package:openup/api/signaling/signaling.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/api/users/profile.dart';
import 'package:openup/api/users/rekindle.dart';
import 'package:openup/notifications/android_voip_handlers.dart'
    as android_voip;
import 'package:openup/notifications/ios_voip_handlers.dart' as ios_voip;
import 'package:openup/report_screen.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/end_call_report.dart';
import 'package:openup/widgets/image_builder.dart';
import 'package:openup/widgets/theming.dart';

import 'notifications/notifications.dart';

part 'call_screen.freezed.dart';

enum EndCallReason {
  timeUp,
  hangUp,
  report,
  remoteHangUpOrDisconnect,
}

class CallPanel extends ConsumerStatefulWidget {
  final ActiveCall activeCall;
  final void Function(EndCallReason reason) onCallEnded;
  final List<Rekindle> rekindles;

  const CallPanel({
    Key? key,
    required this.activeCall,
    required this.onCallEnded,
    required this.rekindles,
  }) : super(key: key);

  @override
  _CallPanelState createState() => _CallPanelState();
}

class _CallPanelState extends ConsumerState<CallPanel> {
  bool _hasSentTimeRequest = false;

  bool _friendRequested = false;

  String? _showReportOverlayForUid;

  @override
  void initState() {
    super.initState();

    widget.activeCall.controller.addListener(_onPhoneControllerChanged);
  }

  @override
  void dispose() {
    // Temporary to ensure hiding mini panel hangs up the call on the other end
    widget.activeCall.signalingChannel.send(const HangUp());
    reportCallEnded(widget.activeCall.rid);
    widget.activeCall.controller.removeListener(_onPhoneControllerChanged);

    super.dispose();
  }

  void _onPhoneControllerChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ImageFiltered(
          imageFilter: ImageFilter.blur(
            sigmaX: _showReportOverlayForUid == null ? 0.0 : 8.0,
            sigmaY: _showReportOverlayForUid == null ? 0.0 : 8.0,
          ),
          child: MiniVoiceCallScreenContent(
            activeCall: widget.activeCall,
            hasSentTimeRequest: _hasSentTimeRequest,
            startTime: widget.activeCall.controller.startTime,
            muted: widget.activeCall.controller.muted,
            speakerphone: widget.activeCall.controller.speakerphone,
            onTimeUp: () => widget.onCallEnded(EndCallReason.timeUp),
            onHangUp: () {
              widget.activeCall.signalingChannel.send(const HangUp());
              widget.onCallEnded(EndCallReason.hangUp);
            },
            onConnect: _connect,
            onReport: (uid) {
              widget.activeCall.signalingChannel
                  .send(HangUpReport(uidToReport: uid));
              widget.onCallEnded(EndCallReason.report);
            },
            onSendTimeRequest: _sendTimeRequest,
            onMuteChanged: (mute) => widget.activeCall.phone.mute = mute,
            onSpeakerphoneChanged: (speakerphone) =>
                widget.activeCall.phone.speakerphone = speakerphone,
          ),
        ),
        if (_showReportOverlayForUid != null)
          EndCallReport(
            backgroundGradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.fromRGBO(0xFF, 0x8E, 0x8E, 0.9),
                Color.fromRGBO(0xBD, 0x20, 0x20, 0.66),
              ],
            ),
            thumbIconColor: const Color.fromRGBO(0x9E, 0x00, 0x00, 1.0),
            onHangUp: () {
              widget.activeCall.signalingChannel
                  .send(HangUpReport(uidToReport: _showReportOverlayForUid!));
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacementNamed(
                'call-report',
                arguments: ReportScreenArguments(
                  uid: _showReportOverlayForUid!,
                ),
              );
            },
            onCancel: () {
              setState(() => _showReportOverlayForUid = null);
            },
          ),
      ],
    );
  }

  void _sendTimeRequest() {
    if (!_hasSentTimeRequest) {
      setState(() => _hasSentTimeRequest = true);
      widget.activeCall.signalingChannel.send(const AddTimeRequest());
    }
  }

  void _connect(String uid) async {
    final myUid = ref.read(userProvider).uid;
    final api = GetIt.instance.get<Api>();
    setState(() => _friendRequested = true);
    await api.addConnectionRequest(myUid, uid);
  }

  void _report(String uid) {
    setState(() => _showReportOverlayForUid = uid);
  }

  void _navigateToRekindleOrLobby() {
    Navigator.of(context).popAndPushNamed('lobby-list');
  }
}

class InitiateCall extends ConsumerStatefulWidget {
  final TopicParticipant participant;
  final void Function(EndCallReason reason) onCallEnded;

  const InitiateCall({
    Key? key,
    required this.participant,
    required this.onCallEnded,
  }) : super(key: key);

  @override
  _InitiateCallState createState() => _InitiateCallState();
}

class _InitiateCallState extends ConsumerState<InitiateCall> {
  ActiveCall? _activeCall;
  bool _callEngaged = false;
  StreamSubscription? _stateSubscription;

  @override
  void initState() {
    super.initState();
    final api = GetIt.instance.get<Api>();
    final resultFuture = api.call(
      widget.participant.uid,
      false,
      group: false,
    );
    resultFuture.then((result) {
      if (!mounted) {
        // TODO: Hang up call in this case
        return;
      }
      result.fold(
        (l) {
          if (l is ApiClientError && l.error is ClientErrorConflict) {
            setState(() => _callEngaged = true);
            _popSoon();
            return;
          }
          var message = errorToMessage(l);
          message = l.when(
            network: (_) => message,
            client: (client) => client.when(
              badRequest: () => 'Failed to get users',
              unauthorized: () => message,
              notFound: () => 'Unable to find topic participants',
              forbidden: () => message,
              conflict: () => message,
            ),
            server: (_) => message,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
            ),
          );
          Navigator.of(context).pop();
        },
        (rid) {
          final uid = ref.read(userProvider).uid;
          ActiveCall? activeCall;
          if (Platform.isAndroid) {
            activeCall = android_voip.createActiveCall(
              uid,
              rid,
              SimpleProfile(
                uid: widget.participant.uid,
                name: widget.participant.name,
                photo: widget.participant.photo,
              ),
            );
          } else if (Platform.isIOS) {
            activeCall = ios_voip.createActiveCall(
              uid,
              rid,
              SimpleProfile(
                uid: widget.participant.uid,
                name: widget.participant.name,
                photo: widget.participant.photo,
              ),
            );
          }
          activeCall?.phone.join();
          setState(() => _activeCall = activeCall);
          _stateSubscription =
              _activeCall?.phone.connectionStateStream.listen((state) {
            if (state == PhoneConnectionState.declined) {
              _popSoon();
            }
          });
        },
      );
    });
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    _activeCall?.signalingChannel.send(const HangUp());
    super.dispose();
  }

  void _popSoon() {
    Future.delayed(const Duration(seconds: 2)).whenComplete(() {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeCall = _activeCall;

    if (activeCall == null) {
      return _RingingUi(
        name: widget.participant.name,
        animate: false,
        onClose: Navigator.of(context).pop,
      );
    } else {
      return StreamBuilder<PhoneConnectionState>(
        initialData: PhoneConnectionState.none,
        stream: activeCall.phone.connectionStateStream,
        builder: (context, snapshot) {
          final state = snapshot.requireData;
          if (state == PhoneConnectionState.none ||
              state == PhoneConnectionState.waiting) {
            return _RingingUi(
              name: widget.participant.name,
              onClose: Navigator.of(context).pop,
            );
          } else if (state == PhoneConnectionState.declined) {
            return Container(
              height: 264,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.fromRGBO(0xE4, 0x23, 0x23, 1.0),
                    Color.fromRGBO(0x7D, 0x00, 0x00, 1.0),
                  ],
                ),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Lottie.asset(
                      'assets/images/call.json',
                      animate: false,
                      fit: BoxFit.contain,
                      width: 90,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Declined',
                      style: Theming.of(context).text.body.copyWith(
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),
            );
          } else if (_callEngaged) {
            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.fromRGBO(0x23, 0xE5, 0x36, 1.0),
                    Color.fromRGBO(0x0F, 0xA7, 0x1E, 1.0),
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    '${widget.participant.name} is already in a call',
                    style: Theming.of(context).text.body.copyWith(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700),
                  ),
                  Button(
                    onPressed: Navigator.of(context).pop,
                    child: Text(
                      'OK',
                      style: Theming.of(context).text.body.copyWith(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          } else {
            return CallPanel(
              activeCall: activeCall,
              onCallEnded: widget.onCallEnded,
              rekindles: const [],
            );
          }
        },
      );
    }
  }
}

class _RingingUi extends StatelessWidget {
  final String name;
  final bool animate;
  final VoidCallback onClose;

  const _RingingUi({
    Key? key,
    required this.name,
    this.animate = true,
    required this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 264,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.fromRGBO(0x23, 0xE5, 0x36, 1.0),
            Color.fromRGBO(0x0F, 0xA7, 0x1E, 1.0),
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: 12,
            right: 12,
            child: Button(
              onPressed: onClose,
              child: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 4.0,
                      offset: Offset(0.0, 4.0),
                      color: Color.fromRGBO(0x00, 0x00, 0x00, 0.25),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.close,
                  color: Color.fromRGBO(0xAE, 0xAE, 0xAE, 1.0),
                  size: 20,
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                'assets/images/call.json',
                fit: BoxFit.contain,
                animate: animate,
                width: 90,
              ),
              const SizedBox(width: 16),
              AutoSizeText(
                'Calling $name',
                minFontSize: 16,
                style: Theming.of(context).text.body.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MiniVoiceCallScreenContent extends ConsumerStatefulWidget {
  final ActiveCall activeCall;
  final bool hasSentTimeRequest;
  final DateTime startTime;
  final bool muted;
  final bool speakerphone;
  final VoidCallback onTimeUp;
  final VoidCallback onHangUp;
  final VoidCallback onSendTimeRequest;
  final void Function(String uid) onConnect;
  final void Function(String uid) onReport;
  final ValueChanged onMuteChanged;
  final ValueChanged onSpeakerphoneChanged;

  const MiniVoiceCallScreenContent({
    Key? key,
    required this.activeCall,
    required this.hasSentTimeRequest,
    required this.startTime,
    required this.muted,
    required this.speakerphone,
    required this.onTimeUp,
    required this.onHangUp,
    required this.onSendTimeRequest,
    required this.onConnect,
    required this.onReport,
    required this.onMuteChanged,
    required this.onSpeakerphoneChanged,
  }) : super(key: key);

  @override
  _MiniVoiceCallScreenContentState createState() =>
      _MiniVoiceCallScreenContentState();
}

class _MiniVoiceCallScreenContentState
    extends ConsumerState<MiniVoiceCallScreenContent> {
  bool _showReportUi = false;
  StreamSubscription? _connectionStateStream;

  @override
  void initState() {
    super.initState();
    _connectionStateStream =
        widget.activeCall.phone.connectionStateStream.listen((state) {
      if (state == PhoneConnectionState.missing ||
          state == PhoneConnectionState.complete) {
        _popSoon();
      }
    });
  }

  void _popSoon() {
    Future.delayed(const Duration(seconds: 2)).whenComplete(() {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _connectionStateStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.activeCall.profile;
    final myProfile = ref.watch(userProvider).profile;

    if (_showReportUi) {
      return _ReportCallBox(
        name: profile.name,
        onReport: () => widget.onReport(profile.uid),
        onCancel: () => setState(() => _showReportUi = false),
      );
    }

    return StreamBuilder<PhoneConnectionState>(
      initialData: PhoneConnectionState.none,
      stream: widget.activeCall.phone.connectionStateStream,
      builder: (context, snapshot) {
        final state = snapshot.requireData;
        if (state == PhoneConnectionState.missing) {
          return SizedBox(
            height: 264,
            child: Center(
              child: Text(
                'The call has already ended',
                style: Theming.of(context).text.body.copyWith(
                    color: const Color.fromRGBO(0xB0, 0xB0, 0xB0, 1.0),
                    fontSize: 20,
                    fontWeight: FontWeight.w700),
              ),
            ),
          );
        } else if (state == PhoneConnectionState.complete) {
          return SizedBox(
            height: 264,
            child: Center(
              child: Text(
                'Call complete',
                style: Theming.of(context).text.body.copyWith(
                    color: const Color.fromRGBO(0xB0, 0xB0, 0xB0, 1.0),
                    fontSize: 20,
                    fontWeight: FontWeight.w700),
              ),
            ),
          );
        }
        return _InCallBox(
          profile: profile,
          myPhoto: myProfile!.photo,
          state: state,
          mute: widget.muted,
          speakerphone: widget.speakerphone,
          startTime: widget.startTime,
          onHangUp: widget.onHangUp,
          onReport: () => setState(() => _showReportUi = true),
          onConnect: widget.onConnect,
          onMuteChanged: widget.onMuteChanged,
          onSpeakerphoneChanged: widget.onSpeakerphoneChanged,
        );
      },
    );
  }
}

class _InCallBox extends StatelessWidget {
  final SimpleProfile profile;
  final String myPhoto;
  final PhoneConnectionState state;
  final bool mute;
  final bool speakerphone;
  final DateTime startTime;
  final VoidCallback onHangUp;
  final VoidCallback onReport;
  final ValueChanged<String> onConnect;
  final ValueChanged<bool> onMuteChanged;
  final ValueChanged<bool> onSpeakerphoneChanged;
  const _InCallBox({
    Key? key,
    required this.profile,
    required this.myPhoto,
    required this.state,
    required this.mute,
    required this.speakerphone,
    required this.startTime,
    required this.onHangUp,
    required this.onReport,
    required this.onConnect,
    required this.onMuteChanged,
    required this.onSpeakerphoneChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, right: 24.0),
          child: Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Button(
                onPressed: onHangUp,
                child: Text(
                  'End Call',
                  style: Theming.of(context).text.body.copyWith(
                      color: const Color.fromRGBO(0xFF, 0x00, 0x00, 1.0),
                      fontSize: 20,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: (state == PhoneConnectionState.none ||
                        state == PhoneConnectionState.waiting ||
                        state == PhoneConnectionState.connecting)
                    ? 'Connecting to '
                    : 'You are talking to ',
                style: Theming.of(context).text.body.copyWith(
                    color: const Color.fromRGBO(0xB0, 0xB0, 0xB0, 1.0),
                    fontSize: 20,
                    fontWeight: FontWeight.w700),
              ),
              TextSpan(
                text: profile.name,
                style: Theming.of(context).text.body.copyWith(
                    color: const Color.fromRGBO(0x7B, 0x79, 0x79, 1.0),
                    fontSize: 20,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        const SizedBox(height: 11),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              clipBehavior: Clip.hardEdge,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: Image.network(
                myPhoto,
                width: 69,
                height: 69,
                fit: BoxFit.cover,
                frameBuilder: fadeInFrameBuilder,
                loadingBuilder: circularProgressLoadingBuilder,
                errorBuilder: iconErrorBuilder,
              ),
            ),
            const SizedBox(width: 33),
            Column(
              children: [
                const Icon(
                  Icons.access_time_filled,
                  color: Color.fromRGBO(0x7B, 0x7B, 0x7B, 1.0),
                ),
                const SizedBox(height: 6),
                _CountUpTimer(start: startTime),
              ],
            ),
            const SizedBox(width: 33),
            Container(
              clipBehavior: Clip.hardEdge,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: Image.network(
                profile.photo,
                width: 69,
                height: 69,
                fit: BoxFit.cover,
                frameBuilder: fadeInFrameBuilder,
                loadingBuilder: circularProgressLoadingBuilder,
                errorBuilder: iconErrorBuilder,
              ),
            ),
          ],
        ),
        const SizedBox(height: 19),
        const Divider(
          color: Color.fromRGBO(0xCA, 0xCA, 0xCA, 1.0),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Button(
              onPressed: () => onConnect(profile.uid),
              child: const Padding(
                padding: EdgeInsets.all(12.0),
                child: Icon(
                  Icons.person_add,
                  color: Color.fromRGBO(0xA8, 0xA8, 0xA8, 1.0),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Button(
              onPressed: onReport,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  'R',
                  style: Theming.of(context).text.body.copyWith(
                      color: const Color.fromRGBO(0xA8, 0xA8, 0xA8, 1.0),
                      fontSize: 27,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Button(
              onPressed: () => onSpeakerphoneChanged(!speakerphone),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Icon(
                  Icons.volume_up,
                  color: speakerphone
                      ? const Color.fromRGBO(0x19, 0xC6, 0x2A, 1.0)
                      : const Color.fromRGBO(0xA8, 0xA8, 0xA8, 1.0),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Button(
              onPressed: () => onMuteChanged(!mute),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Icon(
                  mute ? Icons.mic_off : Icons.mic,
                  color: const Color.fromRGBO(0xA8, 0xA8, 0xA8, 1.0),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _CountUpTimer extends StatefulWidget {
  final DateTime start;
  const _CountUpTimer({
    Key? key,
    required this.start,
  }) : super(key: key);

  @override
  State<_CountUpTimer> createState() => __CountUpTimerState();
}

class __CountUpTimerState extends State<_CountUpTimer> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    super.dispose();
    _timer?.cancel();
  }

  String _formatDuration(Duration d) {
    if (d.inHours > 1) {
      return '${(d.inHours % 24).toString().padLeft(2, '0')}:${(d.inMinutes % 60).toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
    }
    return '${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final time = DateTime.now().difference(widget.start);
    return Text(
      _formatDuration(time),
      style: Theming.of(context).text.body.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: const Color.fromRGBO(0x7B, 0x7B, 0x7B, 1.0)),
    );
  }
}

class _LeaveCallBox extends StatelessWidget {
  const _LeaveCallBox({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 12, top: 16),
            child: Button(
              onPressed: () {},
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(
                  Icons.arrow_back,
                  color: Color.fromRGBO(0xB0, 0xB0, 0xB0, 1.0),
                  size: 32,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(
                  text:
                      'Leaving this call will prevent you from making or taking any calls for',
                  style: Theming.of(context).text.body.copyWith(
                        color: const Color.fromRGBO(0x66, 0x64, 0x64, 1.0),
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                TextSpan(
                  text: ' 5 minutes.\n',
                  style: Theming.of(context).text.body.copyWith(
                        color: const Color.fromRGBO(0xF5, 0x5A, 0x5A, 1.0),
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                TextSpan(
                  text: 'Do you wish to proceed?',
                  style: Theming.of(context).text.body.copyWith(
                        color: const Color.fromRGBO(0x66, 0x64, 0x64, 1.0),
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 31),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Button(
            onPressed: () {},
            child: Text(
              'Leave',
              style: Theming.of(context).text.body.copyWith(
                  color: const Color.fromRGBO(0xFF, 0x00, 0x00, 1.0),
                  fontSize: 20,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReportCallBox extends StatelessWidget {
  final String name;
  final VoidCallback onCancel;
  final VoidCallback onReport;
  const _ReportCallBox({
    Key? key,
    required this.name,
    required this.onReport,
    required this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        onCancel();
        return Future.value(false);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 12, top: 16),
              child: Button(
                onPressed: onCancel,
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(
                    Icons.arrow_back,
                    color: Color.fromRGBO(0xB0, 0xB0, 0xB0, 1.0),
                    size: 32,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'End call and',
                    style: Theming.of(context).text.body.copyWith(
                          color: const Color.fromRGBO(0x66, 0x64, 0x64, 1.0),
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  TextSpan(
                    text: ' report.\n',
                    style: Theming.of(context).text.body.copyWith(
                          color: const Color.fromRGBO(0xF5, 0x5A, 0x5A, 1.0),
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  TextSpan(
                    text: name,
                    style: Theming.of(context).text.body.copyWith(
                          color: const Color.fromRGBO(0x66, 0x64, 0x64, 1.0),
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 31),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Button(
                  onPressed: onCancel,
                  child: Text(
                    'No',
                    style: Theming.of(context).text.body.copyWith(
                        color: const Color.fromRGBO(0x82, 0x81, 0x81, 1.0),
                        fontSize: 20,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Button(
                  onPressed: onReport,
                  child: Text(
                    'Yes',
                    style: Theming.of(context).text.body.copyWith(
                        color: const Color.fromRGBO(0xFF, 0x00, 0x00, 1.0),
                        fontSize: 20,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class AddFriendBox extends StatelessWidget {
  final String name;
  final VoidCallback onDoNotAddFriend;
  final VoidCallback onAddFriend;
  const AddFriendBox({
    Key? key,
    required this.name,
    required this.onDoNotAddFriend,
    required this.onAddFriend,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Would you like to add\n$name as your friend?',
            textAlign: TextAlign.center,
            style: Theming.of(context).text.body.copyWith(
                  color: const Color.fromRGBO(0x66, 0x64, 0x64, 1.0),
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
        const SizedBox(height: 31),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Button(
                onPressed: onDoNotAddFriend,
                child: Text(
                  'No',
                  style: Theming.of(context).text.body.copyWith(
                      color: const Color.fromRGBO(0x82, 0x81, 0x81, 1.0),
                      fontSize: 20,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Button(
                onPressed: onAddFriend,
                child: Text(
                  'Yes',
                  style: Theming.of(context).text.body.copyWith(
                      color: const Color.fromRGBO(0xFF, 0x00, 0x00, 1.0),
                      fontSize: 20,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _CountdownTimer extends StatefulWidget {
  final DateTime endTime;
  final VoidCallback onTimeUp;
  final TextStyle? style;
  const _CountdownTimer({
    Key? key,
    required this.endTime,
    required this.onTimeUp,
    this.style,
  }) : super(key: key);

  @override
  State<_CountdownTimer> createState() => __CountdownTimerState();
}

class __CountdownTimerState extends State<_CountdownTimer> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _restart();
  }

  @override
  void didUpdateWidget(covariant _CountdownTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.endTime != widget.endTime) {
      _restart();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _restart() {
    _update();
    _startPeriodicTimer();
  }

  void _startPeriodicTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _update(),
    );
  }

  void _update() {
    final remaining = widget.endTime.difference(DateTime.now());
    SchedulerBinding.instance?.scheduleFrameCallback((timeStamp) {
      if (remaining.isNegative) {
        setState(() {
          _remaining = Duration.zero;
          _timer?.cancel();
          widget.onTimeUp();
        });
      } else {
        setState(() => _remaining = remaining);
      }
    });
  }

  String _formatDuration(Duration d) {
    if (d.inHours > 1) {
      return '${(d.inHours % 24).toString().padLeft(2, '0')}:${(d.inMinutes % 60).toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
    }
    return '${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _formatDuration(_remaining),
      style: widget.style ??
          Theming.of(context).text.body.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w300,
              color: const Color.fromRGBO(0x7B, 0x7B, 0x7B, 1.0)),
    );
  }
}

String connectionStateText(
  PhoneConnectionState connectionState,
) {
  switch (connectionState) {
    case PhoneConnectionState.none:
      return '';

    case PhoneConnectionState.missing:
      return 'The call has already ended';

    case PhoneConnectionState.waiting:
      return 'Waiting for your match';

    case PhoneConnectionState.declined:
      return 'Your match did not join';

    case PhoneConnectionState.connecting:
      return 'Connecting';

    case PhoneConnectionState.connected:
      return 'Connected';

    case PhoneConnectionState.complete:
      return 'Disconnected';
  }
}

@freezed
class CallData with _$CallData {
  const factory CallData({
    required Phone phone,
    required UserConnection userConnection,
  }) = _CallData;
}

@freezed
class UserConnection with _$UserConnection {
  const factory UserConnection({
    required SimpleProfile profile,
    required Rekindle? rekindle,
    required RTCVideoRenderer? localVideoRenderer,
    required RTCVideoRenderer? videoRenderer,
    required PhoneConnectionState connectionState,
    required bool readyForGroupCall,
  }) = _UserConnection;
}

class CallPageArguments {
  final String rid;
  final List<SimpleProfile> profiles;
  final List<Rekindle> rekindles;
  final bool serious;
  final bool groupLobby;

  CallPageArguments({
    required this.rid,
    required this.profiles,
    required this.rekindles,
    required this.serious,
    this.groupLobby = false,
  });
}
