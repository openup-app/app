import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:get_it/get_it.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/call_state.dart';
import 'package:openup/api/signaling/phone.dart';
import 'package:openup/api/signaling/signaling.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/api/users/profile.dart';
import 'package:openup/api/users/rekindle.dart';
import 'package:openup/lobby_list_page.dart';
import 'package:openup/report_screen.dart';
import 'package:openup/widgets/end_call_report.dart';

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

  StreamSubscription? _connectionStateSubscription;
  var _connectionState = PhoneConnectionState.waiting;

  String? _showReportOverlayForUid;

  @override
  void initState() {
    super.initState();
    _connectionStateSubscription =
        widget.activeCall.phone.connectionStateStream.listen((state) {
      setState(() => _connectionState = state);
    });

    widget.activeCall.controller.addListener(_onPhoneControllerChanged);
  }

  @override
  void dispose() {
    // Temporary to ensure hiding mini panel hangs up the call on the other end
    widget.activeCall.signalingChannel.send(const HangUp());
    reportCallEnded(widget.activeCall.rid);
    _connectionStateSubscription?.cancel();
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
            users: [
              UserConnection(
                connectionState: _connectionState,
                rekindle: null,
                localVideoRenderer: null,
                videoRenderer: null,
                profile: widget.activeCall.profile,
                readyForGroupCall: false,
              ),
            ],
            isInitiator: false,
            hasSentTimeRequest: _hasSentTimeRequest,
            endTime: widget.rekindles.isEmpty
                ? null
                : widget.activeCall.controller.endTime,
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
