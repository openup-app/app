import 'dart:async';
import 'dart:collection';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:openup/signaling/signaling.dart';

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
  final bool video;
  final void Function(
    RTCVideoRenderer localRenderer,
    RTCVideoRenderer remoteRenderer,
  ) onMediaRenderers;
  final void Function(MediaStream stream) onRemoteStream;
  final void Function() onDisconnected;
  final void Function(bool muted)? onToggleMute;

  bool _usedOnce = false;
  RTCPeerConnection? _peerConnection;
  MediaStream? _localMediaStream;
  MediaStream? _remoteMediaStream;
  RTCVideoRenderer? _localRenderer;
  RTCVideoRenderer? _remoteRenderer;

  final _receivedAnIceCandidate = Completer<void>();
  bool _hasRemoteDescription = false;
  final _iceCandidatesToIngest = Queue<IceCandidate>();

  final _iceCandidatesToSend = <IceCandidate>[];
  Timer? _iceCandidatesDebounceTimer;

  Phone({
    required this.signalingChannel,
    required this.video,
    required this.onMediaRenderers,
    required this.onRemoteStream,
    required this.onDisconnected,
    this.onToggleMute,
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
    ].whereType<Future>());
  }

  void toggleMute() {
    final mediaStream = _localMediaStream;
    if (mediaStream != null) {
      final track = mediaStream.getTracks().first;
      track.enabled = !track.enabled;
      onToggleMute?.call(!track.enabled);
    }
  }

  Future<void> call() => _call(initiator: true);

  Future<void> answer() => _call(initiator: false);

  Future<void> _call({required bool initiator}) async {
    _usedOnce = !_usedOnce ? true : throw 'Phone has already been used';

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
      if (video) ...{
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
}
