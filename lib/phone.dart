import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:openup/phone_status.dart';
import 'package:openup/signaling/signaling.dart';

/// WebRTC calling service. The signaling server must already have a room ready
/// for the parties to make a call.
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
  final String _uid;

  bool _idle = true;
  RTCPeerConnection? _peerConnection;
  MediaStream? _localMediaStream;
  MediaStream? _remoteMediaStream;

  final _readyForCall = Completer<void>();
  var _hasRemoteDescription = Completer<void>();
  var _hasIceCandidate = Completer<void>();

  Phone({
    required SignalingChannel signalingChannel,
    required String uid,
  })  : _signalingChannel = signalingChannel,
        _uid = uid;

  Future<void> get ready => _readyForCall.future;

  Stream<PhoneStatus> get status => _statusController.stream;

  Future<void> dispose() async {
    await hangUp();
    _signalSubscription?.cancel();
  }

  Future<void> hangUp() => _disconnect();

  Future<void> _disconnect() async {
    await _peerConnection?.close();
    await Future.wait([
      ...?_localMediaStream?.getTracks().map((track) => track.stop()),
      ...?_remoteMediaStream?.getTracks().map((track) => track.stop()),
      _localMediaStream?.dispose(),
      _remoteMediaStream?.dispose(),
    ].whereType<Future>());
    _statusController.add(const Ended());
    _idle = true;
  }

  Future<void> call() async {
    _idle = _idle ? false : throw 'Call in progress';

    final mediaStream = await _setupMedia();
    _localMediaStream = mediaStream;

    final peerConnection = await createPeerConnection(_configuration);
    _peerConnection = peerConnection;

    _signalingChannel.send(BeginSignaling(uid: _uid));
    _handleSignals(peerConnection, _signalingChannel);

    peerConnection.onAddStream = (stream) {
      _statusController.add(RemoteStreamReady(stream));
      _remoteMediaStream = stream;
    };

    await _addLocalMedia(peerConnection, mediaStream);
    _listenAndSendIceCandidates(peerConnection);
    _readyForCall.complete();

    _listenForRemoteTracks(peerConnection);
    _setLocalDescriptionOffer(peerConnection);
    final sessionDescription = await _setLocalDescriptionOffer(peerConnection);
    _sendSessionDescription(_signalingChannel, sessionDescription);
  }

  Future<void> answer() async {
    _idle = _idle ? false : throw 'Call in progress';

    final mediaStream = await _setupMedia();
    _localMediaStream = mediaStream;

    final peerConnection = await createPeerConnection(_configuration);
    _peerConnection = peerConnection;

    _signalingChannel.send(BeginSignaling(uid: _uid));
    _handleSignals(peerConnection, _signalingChannel);

    peerConnection.onAddStream = (stream) {
      _statusController.add(RemoteStreamReady(stream));
      _remoteMediaStream = stream;
    };

    await _addLocalMedia(peerConnection, mediaStream);
    _listenAndSendIceCandidates(peerConnection);
    _readyForCall.complete();

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
          uid: _uid,
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
        uid: _uid,
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
        beginSignaling: (_) {},
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
