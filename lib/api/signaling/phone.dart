import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:openup/api/signaling/signaling.dart';
import 'package:openup/api/users/profile.dart';
import 'package:openup/api/users/rekindle.dart';
import 'package:rxdart/rxdart.dart';

/// WebRTC calling service, can only be used to [call()] or [answer()] once per
/// instance. The signaling server must already have a room ready for the
/// parties to make a call.
class Phone {
  static const _configuration = {
    'iceServers': [
      {
        'urls': [
          'stun:stun1.l.google.com:19302',
          'stun:stun2.l.google.com:19302',
        ]
      }
    ]
  };

  final PhoneController? controller;
  final SignalingChannel signalingChannel;
  final String uid;
  final String partnerUid;
  final bool useVideo;
  final void Function(
    RTCVideoRenderer localRenderer,
    RTCVideoRenderer remoteRenderer,
  ) onMediaRenderers;
  final void Function(MediaStream stream) onRemoteStream;
  final void Function() onAddTimeRequest;
  final void Function(Duration duration) onAddTime;
  final void Function() onDisconnected;
  final void Function(bool muted)? onMuteChanged;
  final void Function(bool enabled)? onToggleSpeakerphone;
  final void Function(Map<String, bool> states) onGroupCallLobbyStates;
  final void Function(
    String rid,
    List<SimpleProfile> profiles,
    List<Rekindle> rekindles,
  ) onJoinGroupCall;

  bool _usedOnce = false;
  RTCPeerConnection? _peerConnection;
  MediaStream? _localMediaStream;
  MediaStream? _remoteMediaStream;
  RTCVideoRenderer? _localRenderer;
  RTCVideoRenderer? _remoteRenderer;
  bool _speakerphone = false;

  final _receivedAnIceCandidate = Completer<void>();
  bool _hasRemoteDescription = false;
  final _iceCandidatesToIngest = Queue<IceCandidate>();

  final _iceCandidatesToSend = <IceCandidate>[];
  Timer? _iceCandidatesDebounceTimer;

  final _connectionStateController =
      BehaviorSubject<PhoneConnectionState>.seeded(PhoneConnectionState.none);

  Phone({
    this.controller,
    required this.signalingChannel,
    required this.uid,
    required this.partnerUid,
    required this.useVideo,
    required this.onMediaRenderers,
    required this.onRemoteStream,
    required this.onAddTimeRequest,
    required this.onAddTime,
    required this.onDisconnected,
    this.onMuteChanged,
    this.onToggleSpeakerphone,
    required this.onGroupCallLobbyStates,
    required this.onJoinGroupCall,
  });

  Future<void> dispose() async {
    _iceCandidatesDebounceTimer?.cancel();
    await _peerConnection?.close();
    await Future.wait([
      ...?_localMediaStream?.getTracks().map((track) => track.stop()),
      ...?_remoteMediaStream?.getTracks().map((track) => track.stop()),
      _localMediaStream?.dispose(),
      _remoteMediaStream?.dispose(),
      _localRenderer?.dispose(),
      _remoteRenderer?.dispose(),
      _connectionStateController.close(),
    ].whereType<Future>());
  }

  Stream<PhoneConnectionState> get connectionStateStream =>
      _connectionStateController;

  set mute(bool value) {
    final track = _firstAudioTrack(_localMediaStream);
    if (track != null && track.enabled == value) {
      track.enabled = !value;
      controller?._mute = value;
    }
  }

  set speakerphone(bool value) {
    final track = _firstAudioTrack(_localMediaStream);
    if (track != null && _speakerphone != value) {
      track.enableSpeakerphone(value);
      controller?._speakerphone = value;
    }
    _speakerphone = value;
  }

  set videoEnabled(bool value) {
    final track = _firstVideoTrack(_localMediaStream);
    if (track != null) {
      track.enabled = value;
    }
  }

  Future<void> join() async {
    _usedOnce = !_usedOnce ? true : throw 'Phone has already been used';
    _connectionStateController.add(PhoneConnectionState.waiting);

    final mediaStream = await _setupMedia();
    _localMediaStream = mediaStream;

    final peerConnection = await createPeerConnection(_configuration);
    _peerConnection = peerConnection;
    _handleCallConnectionState(peerConnection);

    _handleSignals(peerConnection, signalingChannel);

    peerConnection.onAddStream = (stream) {
      onRemoteStream(stream);
      _remoteMediaStream = stream;
    };

    await _addLocalMedia(peerConnection, mediaStream);
    _emitIceCandidates(peerConnection);
    final shouldBeFirstToCommunicate =
        _shouldBeFirstToCommunicate(uid, partnerUid);
    if (!shouldBeFirstToCommunicate) {
      await _receivedAnIceCandidate.future;
    }

    _listenForRemoteTracks(peerConnection);
    final sessionDescription = shouldBeFirstToCommunicate
        ? await _setLocalDescriptionOffer(peerConnection)
        : await _setLocalDescriptionAnswer(peerConnection);
    _sendSessionDescription(signalingChannel, sessionDescription);
  }

  Future<MediaStream> _setupMedia() async {
    final localRenderer = RTCVideoRenderer();
    final remoteRenderer = RTCVideoRenderer();
    await localRenderer.initialize();
    await remoteRenderer.initialize();

    final mediaStream = await navigator.mediaDevices.getUserMedia({
      if (useVideo) ...{
        'video': {
          'facingMode': 'user',
        },
      },
      'audio': true,
    });

    onMediaRenderers(
      localRenderer..srcObject = mediaStream,
      remoteRenderer..srcObject = await createLocalMediaStream('key'),
    );
    _localRenderer = localRenderer;
    _remoteRenderer = remoteRenderer;

    return mediaStream;
  }

  Future<void> _addLocalMedia(
    RTCPeerConnection peerConnection,
    MediaStream mediaStream,
  ) {
    return Future.wait(
      mediaStream
          .getTracks()
          .map((track) => peerConnection.addTrack(track, mediaStream)),
    );
  }

  void _emitIceCandidates(RTCPeerConnection peerConnection) {
    peerConnection.onIceCandidate = (candidate) {
      _iceCandidatesToSend.add(
        IceCandidate(
          candidate: candidate.candidate,
          sdpMid: candidate.sdpMid,
          sdpMLineIndex: candidate.sdpMlineIndex,
        ),
      );

      // Batching candidates to reduce network traffic
      _iceCandidatesDebounceTimer ??=
          Timer(const Duration(milliseconds: 300), () {
        _iceCandidatesDebounceTimer = null;
        signalingChannel.send(IceCandidates(
          recipient: partnerUid,
          iceCandidates: _iceCandidatesToSend,
        ));
        _iceCandidatesToSend.clear();
      });
    };
  }

  void _listenForRemoteTracks(RTCPeerConnection peerConnection) {
    peerConnection.onTrack = (trackEvent) {
      trackEvent.streams.first
          .getTracks()
          .forEach((track) => _remoteMediaStream?.addTrack(track));
    };
  }

  Future<RTCSessionDescription> _setLocalDescriptionOffer(
    RTCPeerConnection peerConnection,
  ) async {
    final offer = await peerConnection.createOffer();
    await peerConnection.setLocalDescription(offer);
    return offer;
  }

  Future<RTCSessionDescription> _setLocalDescriptionAnswer(
    RTCPeerConnection peerConnection,
  ) async {
    final answer = await peerConnection.createAnswer();
    peerConnection.setLocalDescription(answer);
    return answer;
  }

  void _sendSessionDescription(
    SignalingChannel signalingChannel,
    RTCSessionDescription sessionDescription,
  ) {
    signalingChannel.send(
      SessionDescription(
        recipient: partnerUid,
        sdp: sessionDescription.sdp,
        type: sessionDescription.type,
      ),
    );
  }

  void _handleCallConnectionState(RTCPeerConnection peerConnection) {
    peerConnection.onConnectionState = (state) {
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        onDisconnected();
      }
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnecting) {
        _connectionStateController.add(PhoneConnectionState.connecting);
      } else if (state ==
          RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        _connectionStateController.add(PhoneConnectionState.connected);
      }
    };
  }

  StreamSubscription<Signal> _handleSignals(
    RTCPeerConnection peerConnection,
    SignalingChannel signalingChannel,
  ) {
    return signalingChannel.signals.listen((signal) {
      signal.map(
        sessionDescription: (sessionDescription) {
          peerConnection.setRemoteDescription(
            RTCSessionDescription(
              sessionDescription.sdp,
              sessionDescription.type,
            ),
          );
          _hasRemoteDescription = true;

          while (_iceCandidatesToIngest.isNotEmpty) {
            _addIceCandidate(
                peerConnection, _iceCandidatesToIngest.removeFirst());
          }
        },
        iceCandidates: (iceCandidates) {
          if (_hasRemoteDescription) {
            // Should only add candidates after receciving remote description
            iceCandidates.iceCandidates.forEach((iceCandidate) {
              _addIceCandidate(peerConnection, iceCandidate);
            });

            if (!_receivedAnIceCandidate.isCompleted) {
              _receivedAnIceCandidate.complete();
            }
          } else {
            _iceCandidatesToIngest.addAll(iceCandidates.iceCandidates);
          }
        },
        addTimeRequest: (_) => onAddTimeRequest(),
        addTime: (addTime) => onAddTime(Duration(seconds: addTime.seconds)),
        groupCallLobbyReady: (_) {},
        groupCallLobbyReadyStates: (states) =>
            onGroupCallLobbyStates(states.readyStates),
        joinCall: (room) => onJoinGroupCall(
          room.rid,
          room.profiles,
          room.rekindles,
        ),
        hangUp: (_) {
          _connectionStateController.add(PhoneConnectionState.complete);
          onDisconnected();
        },
        hangUpReport: (_) {},
        reject: (_) {
          _connectionStateController.add(PhoneConnectionState.declined);
        },
        roomNotFound: (_) {
          _connectionStateController.add(PhoneConnectionState.missing);
        },
      );
    });
  }

  void _addIceCandidate(
    RTCPeerConnection peerConnection,
    IceCandidate iceCandidate,
  ) {
    peerConnection.addCandidate(
      RTCIceCandidate(
        iceCandidate.candidate,
        iceCandidate.sdpMid,
        iceCandidate.sdpMLineIndex,
      ),
    );
  }

  MediaStreamTrack? _firstAudioTrack(MediaStream? mediaStream) {
    try {
      return mediaStream
          ?.getTracks()
          .firstWhere((track) => track.kind == 'audio');
    } on StateError {
      return null;
    }
  }

  MediaStreamTrack? _firstVideoTrack(MediaStream? mediaStream) {
    try {
      return mediaStream
          ?.getTracks()
          .firstWhere((track) => track.kind == 'video');
    } on StateError {
      return null;
    }
  }

  bool _shouldBeFirstToCommunicate(String uid, String theirUid) =>
      uid.compareTo(theirUid) < 0;
}

enum PhoneConnectionState {
  /// Have not yet attempted to join a call.
  none,

  /// No matching call to join
  missing,

  /// Attempting to join a call but have not yet received connection signals.
  waiting,

  /// The other party has refused the call.
  declined,

  /// Connection signals have been received, the call has been accepted.
  connecting,

  /// Video/audio communication by the users can begin.
  connected,

  /// The call has been completed.
  complete
}

class PhoneController with ChangeNotifier {
  bool _muteValue = false;
  bool _speakerphoneValue = false;
  DateTime? _endTimeValue;

  PhoneController() : super();

  set _mute(bool value) {
    final old = _muteValue;
    _muteValue = value;
    if (old != value) {
      notifyListeners();
    }
  }

  set _speakerphone(bool value) {
    final old = _speakerphoneValue;
    _speakerphoneValue = value;
    if (old != value) {
      notifyListeners();
    }
  }

  set endTime(DateTime? value) {
    final old = _endTimeValue;
    _endTimeValue = value;
    if (old != value) {
      notifyListeners();
    }
  }

  bool get muted => _muteValue;

  bool get speakerphone => _speakerphoneValue;

  DateTime? get endTime => _endTimeValue;
}
