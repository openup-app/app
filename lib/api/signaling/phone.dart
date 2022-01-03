import 'dart:async';
import 'dart:collection';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:openup/api/signaling/signaling.dart';
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

  final SignalingChannel signalingChannel;
  final bool useVideo;
  final void Function(
    RTCVideoRenderer localRenderer,
    RTCVideoRenderer remoteRenderer,
  ) onMediaRenderers;
  final void Function(MediaStream stream) onRemoteStream;
  final void Function() onAddTimeRequest;
  final void Function(Duration duration) onAddTime;
  final void Function() onDisconnected;
  final void Function(bool muted)? onToggleMute;
  final void Function(bool enabled)? onToggleSpeakerphone;

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
    required this.signalingChannel,
    required this.useVideo,
    required this.onMediaRenderers,
    required this.onRemoteStream,
    required this.onAddTimeRequest,
    required this.onAddTime,
    required this.onDisconnected,
    this.onToggleMute,
    this.onToggleSpeakerphone,
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

  void toggleMute() {
    final track = _firstAudioTrack(_localMediaStream);
    if (track != null) {
      track.enabled = !track.enabled;
      onToggleMute?.call(!track.enabled);
    }
  }

  void toggleSpeakerphone() {
    final track = _firstAudioTrack(_localMediaStream);
    if (track != null) {
      _speakerphone = !_speakerphone;
      track.enableSpeakerphone(_speakerphone);
      onToggleSpeakerphone?.call(_speakerphone);
    }
  }

  set videoEnabled(bool value) {
    final track = _firstVideoTrack(_localMediaStream);
    if (track != null) {
      track.enabled = value;
    }
  }

  Future<void> join({required bool initiator}) async {
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
    if (!initiator) {
      await _receivedAnIceCandidate.future;
    }

    _listenForRemoteTracks(peerConnection);
    final sessionDescription = initiator
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
        signalingChannel.send(IceCandidates(_iceCandidatesToSend));
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
        hangUp: (_) {
          _connectionStateController.add(PhoneConnectionState.complete);
          onDisconnected();
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
}

enum PhoneConnectionState {
  /// Have not yet attempted to join a call.
  none,

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
