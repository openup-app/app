import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:lottie/lottie.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/call_manager.dart';
import 'package:openup/api/signaling/phone.dart';
import 'package:openup/api/signaling/signaling.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/api/users/profile.dart';
import 'package:openup/report_screen.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/image_builder.dart';
import 'package:openup/widgets/theming.dart';

class CallSystem extends ConsumerStatefulWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  const CallSystem({
    Key? key,
    required this.navigatorKey,
  }) : super(key: key);

  @override
  CallSystemState createState() => CallSystemState();
}

class CallSystemState extends ConsumerState<CallSystem> {
  bool _panelVisible = false;
  bool _initiatingCall = false;
  bool _outgoingCall = false;
  String? _ringingName;
  bool _engaged = false;
  ActiveCall? _activeCall;
  bool _requestedFriend = false;
  SimpleProfile? _showFriendRequestDisplay;
  bool _showReportCallDisplay = false;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();

    // final callInfoStream = GetIt.instance.get<CallState>().callInfoStream;
    // callInfoStream.listen(_onCallInfo);
  }

  // void _onCallInfo(CallInfo callInfo) {
  //   callInfo.map(
  //     active: (activeCall) async {
  //       _dismissTimer?.cancel();
  //       if (!_outgoingCall) {
  //         _requestedFriend = await _checkIsFriend(activeCall.profile.uid);
  //       }

  //       WidgetsBinding.instance.scheduleFrameCallback((_) {
  //         if (!mounted) {
  //           _disposeCallAndDismiss();
  //           return;
  //         }
  //         setState(() {
  //           _panelVisible = true;
  //           _activeCall = activeCall;
  //         });
  //       });
  //     },
  //     none: (_) {},
  //   );
  // }

  @override
  void dispose() {
    _disposeCall();
    super.dispose();
  }

  void _disposeCallAndDismiss() {
    if (mounted) {
      setState(() => _panelVisible = false);
    }
    _disposeCall();
  }

  void _disposeCall() {
    _activeCall?.signalingChannel.send(const HangUp());

    _dismissTimer?.cancel();
    _activeCall = null;

    _requestedFriend = false;
    _engaged = false;
    _initiatingCall = false;
    _outgoingCall = false;
    _showFriendRequestDisplay = null;
    _showReportCallDisplay = false;
  }

  void _dismissSoon() {
    _dismissTimer = Timer(
      const Duration(seconds: 2),
      _disposeCallAndDismiss,
    );
  }

  Future<bool> _checkIsFriend(String otherUid) async {
    final myUid = ref.read(userProvider).uid;
    final api = GetIt.instance.get<Api>();
    final uids = await api.getConnectionUids(myUid);
    return uids.fold(
      (l) => false,
      (r) => r.contains(otherUid),
    );
  }

  void call(BuildContext context, SimpleProfile profile) async {
    // _disposeCall();
    // setState(() {
    //   _panelVisible = true;
    //   _initiatingCall = true;
    //   _outgoingCall = true;
    //   _ringingName = profile.name;
    // });

    // final api = GetIt.instance.get<Api>();
    // final isFriend = await _checkIsFriend(profile.uid);
    // final result = await api.call(profile.uid, false, group: false);
    // print('call');
    // if (!mounted) {
    //   _disposeCallAndDismiss();
    //   return;
    // }
    // setState(() {
    //   _initiatingCall = false;
    // });
    // print('result is $result');
    // setState(() => _requestedFriend = isFriend);
    // result.fold(
    //   (l) {
    //     if (l is ApiClientError && l.error is ClientErrorConflict) {
    //       setState(() => _engaged = true);
    //     } else {
    //       var message = errorToMessage(l);
    //       message = l.when(
    //         network: (_) => message,
    //         client: (client) => client.when(
    //           badRequest: () => 'Failed to get users',
    //           unauthorized: () => message,
    //           notFound: () => 'Unable to find topic participants',
    //           forbidden: () => message,
    //           conflict: () => message,
    //         ),
    //         server: (_) => message,
    //       );
    //       ScaffoldMessenger.of(context).showSnackBar(
    //         SnackBar(
    //           content: Text(message),
    //         ),
    //       );
    //     }
    //     _dismissSoon();
    //   },
    //   (rid) {
    //     final uid = ref.read(userProvider).uid;
    //     ActiveCall? activeCall;
    //     if (Platform.isAndroid) {
    //       activeCall = android_voip.createActiveCall(uid, rid, profile);
    //     } else if (Platform.isIOS) {
    //       activeCall = ios_voip.createActiveCall(uid, rid, profile);
    //     }

    //     if (activeCall != null) {
    //       activeCall.phone.join();
    //       GetIt.instance.get<CallState>().callInfo = CallInfo.active(
    //         rid: activeCall.rid,
    //         phone: activeCall.phone,
    //         signalingChannel: activeCall.signalingChannel,
    //         profile: activeCall.profile,
    //         controller: activeCall.controller,
    //       );
    //     }
    //   },
    // );
  }

  @override
  Widget build(BuildContext context) {
    if (!_panelVisible) {
      return const SizedBox.shrink();
    }

    return _PanelMaterial(
      builder: (context) {
        if (_initiatingCall && _outgoingCall) {
          return _RingingDisplay(
            name: _ringingName ?? '',
            animate: false,
            onClose: _disposeCallAndDismiss,
          );
        }

        if (_engaged) {
          _dismissSoon();
          return _EngagedDisplay(
            name: _ringingName ?? '',
          );
        }

        final otherProfile = _showFriendRequestDisplay;
        if (otherProfile != null) {
          return _FriendRequestDisplay(
            name: otherProfile.name,
            onDoNotAddFriend: _disposeCallAndDismiss,
            onAddFriend: () {
              final api = GetIt.instance.get<Api>();
              final uid = ref.read(userProvider).uid;
              api.addConnectionRequest(uid, otherProfile.uid);
              _disposeCallAndDismiss();
            },
          );
        }

        final activeCall = _activeCall;
        if (activeCall == null) {
          _dismissSoon();
          return const _CallFailedDisplay();
        }

        return StreamBuilder<PhoneConnectionState>(
          initialData: PhoneConnectionState.none,
          stream: activeCall.phone.connectionStateStream,
          builder: (context, snapshot) {
            if (_showReportCallDisplay) {
              return _ReportCallDisplay(
                name: activeCall.profile.name,
                onCancel: () => setState(() => _showReportCallDisplay = false),
                onReport: () {
                  final uid = activeCall.profile.uid;
                  activeCall.signalingChannel.send(const HangUp());
                  _disposeCallAndDismiss();
                  widget.navigatorKey.currentState?.pushNamed(
                    'call-report',
                    arguments: ReportScreenArguments(uid: uid),
                  );
                },
              );
            }

            final state = snapshot.requireData;
            switch (state) {
              case PhoneConnectionState.none:
                return const SizedBox.shrink();
              case PhoneConnectionState.missing:
                _dismissSoon();
                return const _AlreadyEndedDisplay();
              case PhoneConnectionState.declined:
                _dismissSoon();
                return const _DeclinedDisplay();
              case PhoneConnectionState.complete:
                if (!_requestedFriend) {
                  final otherProfile = activeCall.profile;
                  Future.delayed(const Duration(seconds: 2)).whenComplete(() {
                    if (mounted) {
                      setState(() => _showFriendRequestDisplay = otherProfile);
                    }
                  });
                } else {
                  _dismissSoon();
                }
                return const _CallCompleteDisplay();
              case PhoneConnectionState.waiting:
              case PhoneConnectionState.connecting:
              case PhoneConnectionState.connected:
                if (_outgoingCall && state == PhoneConnectionState.waiting) {
                  return _RingingDisplay(
                    name: activeCall.profile.name,
                    onClose: () {
                      activeCall.signalingChannel
                          .send(HangUp(recipient: activeCall.profile.uid));
                      _disposeCallAndDismiss();
                    },
                  );
                }
                return ValueListenableBuilder<PhoneValue>(
                  valueListenable: activeCall.controller,
                  builder: (context, phoneValue, _) {
                    return _InCallDisplay(
                      profile: activeCall.profile,
                      myPhoto: ref.watch(userProvider).profile?.photo ?? '',
                      connecting: state == PhoneConnectionState.connecting,
                      canRequestFriend: !_requestedFriend,
                      mute: phoneValue.mute,
                      speakerphone: phoneValue.speakerphone,
                      startTime: phoneValue.startTime,
                      onLeaveCall: () {
                        activeCall.signalingChannel.send(const HangUp());
                        if (!_requestedFriend) {
                          _disposeCall();
                          setState(() =>
                              _showFriendRequestDisplay = activeCall.profile);
                        } else {
                          _disposeCallAndDismiss();
                        }
                      },
                      onReport: () {
                        setState(() => _showReportCallDisplay = true);
                      },
                      onConnect: (uid) {
                        GetIt.instance
                            .get<Api>()
                            .addConnectionRequest(uid, activeCall.profile.uid);
                        setState(() => _requestedFriend = true);
                      },
                      onMuteChanged: (value) => activeCall.phone.mute = value,
                      onSpeakerphoneChanged: (value) =>
                          activeCall.phone.speakerphone = value,
                    );
                  },
                );
            }
          },
        );
      },
    );
  }
}

void _onCallEnded(BuildContext context, String uid, EndCallReason reason) {
  switch (reason) {
    case EndCallReason.timeUp:
      // Panel will pop itself after timer
      break;
    case EndCallReason.hangUp:
      Navigator.of(context).pop();
      break;
    case EndCallReason.report:
      Navigator.of(context).pop();
      Navigator.of(context).pushNamed(
        'call-report',
        arguments: ReportScreenArguments(uid: uid),
      );
      break;
    case EndCallReason.remoteHangUpOrDisconnect:
      // Panel will pop itself after timer
      break;
  }
}

class _InCallDisplay extends StatelessWidget {
  final SimpleProfile profile;
  final String myPhoto;
  final bool connecting;
  final bool canRequestFriend;
  final bool mute;
  final bool speakerphone;
  final DateTime startTime;
  final VoidCallback onLeaveCall;
  final VoidCallback onReport;
  final ValueChanged<String> onConnect;
  final ValueChanged<bool> onMuteChanged;
  final ValueChanged<bool> onSpeakerphoneChanged;
  const _InCallDisplay({
    Key? key,
    required this.profile,
    required this.myPhoto,
    required this.connecting,
    required this.canRequestFriend,
    required this.mute,
    required this.speakerphone,
    required this.startTime,
    required this.onLeaveCall,
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
                onPressed: onLeaveCall,
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
                text: connecting ? 'Connecting to ' : 'You are talking to ',
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
                loadingBuilder: loadingBuilder,
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
                loadingBuilder: loadingBuilder,
                errorBuilder: iconErrorBuilder,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Divider(
          color: Color.fromRGBO(0xCA, 0xCA, 0xCA, 1.0),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Button(
              onPressed: canRequestFriend ? () => onConnect(profile.uid) : null,
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

class _RingingDisplay extends StatelessWidget {
  final String name;
  final bool animate;
  final VoidCallback onClose;

  const _RingingDisplay({
    Key? key,
    required this.name,
    this.animate = true,
    required this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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

class _DeclinedDisplay extends StatelessWidget {
  const _DeclinedDisplay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
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
  }
}

class _CallCompleteDisplay extends StatelessWidget {
  const _CallCompleteDisplay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      'Call complete',
      style: Theming.of(context).text.body.copyWith(
          color: const Color.fromRGBO(0xB0, 0xB0, 0xB0, 1.0),
          fontSize: 20,
          fontWeight: FontWeight.w700),
    );
  }
}

class _EngagedDisplay extends StatelessWidget {
  final String name;

  const _EngagedDisplay({
    Key? key,
    required this.name,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: TextAlign.center,
      overflow: TextOverflow.ellipsis,
      maxLines: 2,
      text: TextSpan(
        children: [
          TextSpan(
            text: name,
            style: Theming.of(context).text.body.copyWith(
                color: const Color.fromRGBO(0xB0, 0xB0, 0xB0, 1.0),
                fontSize: 20,
                fontWeight: FontWeight.w700),
          ),
          TextSpan(
            text: '\nis already in a call',
            style: Theming.of(context).text.body.copyWith(
                color: const Color.fromRGBO(0xB0, 0xB0, 0xB0, 1.0),
                fontSize: 20,
                fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _AlreadyEndedDisplay extends StatelessWidget {
  const _AlreadyEndedDisplay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      'The call has already ended',
      style: Theming.of(context).text.body.copyWith(
          color: const Color.fromRGBO(0xB0, 0xB0, 0xB0, 1.0),
          fontSize: 20,
          fontWeight: FontWeight.w700),
    );
  }
}

class _CallFailedDisplay extends StatelessWidget {
  const _CallFailedDisplay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      'Call failed',
      style: Theming.of(context).text.body.copyWith(
          color: const Color.fromRGBO(0xB0, 0xB0, 0xB0, 1.0),
          fontSize: 20,
          fontWeight: FontWeight.w700),
    );
  }
}

class _LeaveCallDisplay extends StatelessWidget {
  const _LeaveCallDisplay({Key? key}) : super(key: key);

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

class _ReportCallDisplay extends StatelessWidget {
  final String name;
  final VoidCallback onCancel;
  final VoidCallback onReport;
  const _ReportCallDisplay({
    Key? key,
    required this.name,
    required this.onReport,
    required this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
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
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: RichText(
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'End call and',
                  style: Theming.of(context).text.body.copyWith(
                        color: const Color.fromRGBO(0x66, 0x64, 0x64, 1.0),
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
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
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Button(
              onPressed: onCancel,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'No',
                  style: Theming.of(context).text.body.copyWith(
                      color: const Color.fromRGBO(0x82, 0x81, 0x81, 1.0),
                      fontSize: 20,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
            Button(
              onPressed: onReport,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
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
      ],
    );
  }
}

class _FriendRequestDisplay extends StatelessWidget {
  final String name;
  final VoidCallback onDoNotAddFriend;
  final VoidCallback onAddFriend;
  const _FriendRequestDisplay({
    Key? key,
    required this.name,
    required this.onDoNotAddFriend,
    required this.onAddFriend,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 62),
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
            Button(
              onPressed: onDoNotAddFriend,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'No',
                  style: Theming.of(context).text.body.copyWith(
                      color: const Color.fromRGBO(0x82, 0x81, 0x81, 1.0),
                      fontSize: 20,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
            Button(
              onPressed: onAddFriend,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
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
        const SizedBox(height: 42),
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

class _PanelMaterial extends StatelessWidget {
  final WidgetBuilder builder;

  const _PanelMaterial({
    Key? key,
    required this.builder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 256 + MediaQuery.of(context).padding.bottom,
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(41),
          topRight: Radius.circular(41),
        ),
      ),
      child: Material(
        child: Center(
          child: builder(context),
        ),
      ),
    );
  }
}

enum EndCallReason {
  timeUp,
  hangUp,
  report,
  remoteHangUpOrDisconnect,
}

class CallPageArguments {
  final String rid;
  final List<SimpleProfile> profiles;
  final bool serious;
  final bool groupLobby;

  CallPageArguments({
    required this.rid,
    required this.profiles,
    required this.serious,
    this.groupLobby = false,
  });
}
