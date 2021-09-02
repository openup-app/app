import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:openup/phone_status.dart';
import 'package:openup/signaling/signaling.dart';

/// WebRTC calling service.
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

  final SignalingChannel _signalingChannel;
  StreamSubscription<Signal>? _signalSubscription;

  final _statusController = StreamController<PhoneStatus>.broadcast();
  bool _idle = true;
  RTCPeerConnection? _peerConnection;
  MediaStream? _localMediaStream;
  MediaStream? _remoteMediaStream;

  final _readyForCall = Completer<void>();
  var _hasRemoteDescription = Completer<void>();
  var _hasIceCandidate = Completer<void>();

  Phone({
    required SignalingChannel signalingChannel,
    required String nickname,
  }) : _signalingChannel = signalingChannel {
    _signalingChannel.send(RegisterClient(nickname: nickname));

    _setup();
  }

  Future<void> get ready => _readyForCall.future;

  Stream<PhoneStatus> get status => _statusController.stream;

  void _setup() async {
    final mediaStream = await _setupMedia();
    _localMediaStream = mediaStream;

    final peerConnection = await createPeerConnection(_configuration);
    _peerConnection = peerConnection;

    peerConnection.onAddStream = (stream) {
      _statusController.add(RemoteStreamReady(stream));
      _remoteMediaStream = stream;
    };

    await _addLocalMedia(peerConnection, mediaStream);

    _listenAndSendIceCandidates(peerConnection);

    _signalSubscription = _handleSignals(peerConnection, _signalingChannel);
    _readyForCall.complete();
  }

  Future<void> dispose() async {
    await _peerConnection?.close();
    _signalingChannel.send(const EndCall());
    await hangUp();
    await Future.wait([
      _signalSubscription?.cancel(),
      ...?_localMediaStream?.getTracks().map((track) => track.stop()),
      ...?_remoteMediaStream?.getTracks().map((track) => track.stop()),
      _localMediaStream?.dispose(),
      _remoteMediaStream?.dispose(),
    ].whereType<Future>());
  }

  Future<void> hangUp() async {
    _idle = true;
    _statusController.add(const Ended());
  }

  Future<void> call(String nickname) async {
    _idle = _idle ? false : throw 'Call in progress';

    final peerConnection = _peerConnection;
    if (peerConnection == null) {
      return;
    }

    _signalingChannel.send(StartCall(nickname: nickname));

    _listenForRemoteTracks(peerConnection);
    _setLocalDescriptionOffer(peerConnection);
    final sessionDescription = await _setLocalDescriptionOffer(peerConnection);
    _sendSessionDescription(_signalingChannel, sessionDescription);
  }

  Future<void> answer() async {
    _idle = _idle ? false : throw 'Call in progress';

    final peerConnection = _peerConnection;
    if (peerConnection == null) {
      return;
    }

    _hasIceCandidate = Completer<void>();
    _hasRemoteDescription = Completer<void>();

    await _hasRemoteDescription.future;
    await _hasIceCandidate.future;

    _listenForRemoteTracks(peerConnection);
    final sessionDescription = await _setLocalDescriptionAnswer(peerConnection);
    _sendSessionDescription(_signalingChannel, sessionDescription);
  }

  Future<MediaStream> _setupMedia() async {
    _statusController.add(const PreparingMedia());

    final localRenderer = RTCVideoRenderer();
    final remoteRenderer = RTCVideoRenderer();
    await localRenderer.initialize();
    await remoteRenderer.initialize();

    final mediaStream = await navigator.mediaDevices.getUserMedia({
      'video': true,
      'audio': true,
    });

    _statusController.add(
      MediaReady(
        localVideo: localRenderer..srcObject = mediaStream,
        remoteVideo: remoteRenderer
          ..srcObject = await createLocalMediaStream('key'),
      ),
    );

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

  void _listenAndSendIceCandidates(RTCPeerConnection peerConnection) {
    peerConnection.onIceCandidate = (candidate) {
      _signalingChannel.send(
        IceCandidate(
          candidate: candidate.candidate,
          sdpMid: candidate.sdpMid,
          sdpMLineIndex: candidate.sdpMlineIndex,
        ),
      );
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

  StreamSubscription<Signal> _handleSignals(
    RTCPeerConnection peerConnection,
    SignalingChannel signalingChannel,
  ) {
    return signalingChannel.signals.listen((signal) {
      signal.map(
        registerClient: (_) {},
        startCall: (_) {},
        answerCall: (_) => answer(),
        endCall: (_) {},
        sessionDescription: (sessionDescription) {
          if (!_hasRemoteDescription.isCompleted) {
            _hasRemoteDescription.complete();
          }
          peerConnection.setRemoteDescription(
            RTCSessionDescription(
              sessionDescription.sdp,
              sessionDescription.type,
            ),
          );
        },
        iceCandidate: (iceCandidate) {
          if (!_hasIceCandidate.isCompleted) {
            _hasIceCandidate.complete();
          }
          peerConnection.addCandidate(
            RTCIceCandidate(
              iceCandidate.candidate,
              iceCandidate.sdpMid,
              iceCandidate.sdpMLineIndex,
            ),
          );
        },
      );
    });
  }
}
