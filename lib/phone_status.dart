import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'phone_status.freezed.dart';

/// Information about the state of the WebRTC call.
@freezed
class PhoneStatus with _$PhoneStatus {
  const factory PhoneStatus.preparingMedia() = PreparingMedia;
  const factory PhoneStatus.mediaReady({
    required RTCVideoRenderer localVideo,
    required RTCVideoRenderer remoteVideo,
  }) = MediaReady;
  const factory PhoneStatus.remoteStreamReady(MediaStream stream) =
      RemoteStreamReady;
  const factory PhoneStatus.ended() = Ended;
}
