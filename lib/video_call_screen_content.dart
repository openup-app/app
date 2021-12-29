import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:openup/api/users/profile.dart';
import 'package:openup/api/users/rekindle.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/theming.dart';
import 'package:openup/widgets/time_remaining.dart';

/// Video call display and controls.
///
/// Setting [endTime] to `null` will disable the timer UI and will not
/// trigger [onTimeUp].
class VideoCallScreenContent extends StatefulWidget {
  final List<PublicProfile> profiles;
  final List<Rekindle> rekindles;
  final RTCVideoRenderer? localRenderer;
  final RTCVideoRenderer? remoteRenderer;
  final bool hasSentTimeRequest;
  final DateTime? endTime;
  final bool muted;
  final VoidCallback onTimeUp;
  final VoidCallback onHangUp;
  final void Function(String uid) onConnect;
  final void Function(String uid) onReport;
  final VoidCallback onSendTimeRequest;
  final VoidCallback onToggleMute;

  const VideoCallScreenContent({
    Key? key,
    required this.profiles,
    required this.rekindles,
    required this.localRenderer,
    required this.remoteRenderer,
    required this.hasSentTimeRequest,
    required this.endTime,
    required this.muted,
    required this.onTimeUp,
    required this.onHangUp,
    required this.onConnect,
    required this.onReport,
    required this.onSendTimeRequest,
    required this.onToggleMute,
  }) : super(key: key);

  @override
  State<VideoCallScreenContent> createState() => _VideoCallScreenContentState();
}

class _VideoCallScreenContentState extends State<VideoCallScreenContent> {
  bool _showingControls = true;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (widget.remoteRenderer != null)
          Positioned.fill(
            child: GestureDetector(
              onTap: () => setState(() => _showingControls = !_showingControls),
              child: RTCVideoView(
                widget.remoteRenderer!,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
              ),
            ),
          ),
        AnimatedPositioned(
          left: _showingControls ? 16.0 : -(56.0 + 16.0),
          top: MediaQuery.of(context).padding.top + 32.0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
          child: _CallControlButton(
            onPressed: () => widget.onReport(widget.profiles.first.uid),
            scrimColor: const Color.fromARGB(0xFF, 0xFF, 0x00, 0x00),
            size: 56,
            child: Center(
              child: Text(
                'R',
                style: Theming.of(context).text.body.copyWith(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),
        ),
        if (widget.endTime != null)
          Align(
            alignment: Alignment.topCenter,
            child: SafeArea(
              top: true,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Button(
                  onPressed: widget.hasSentTimeRequest
                      ? null
                      : widget.onSendTimeRequest,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.alarm_add),
                      TimeRemaining(
                        endTime: widget.endTime!,
                        onTimeUp: widget.onTimeUp,
                        builder: (context, remaining) {
                          return Text(
                            remaining,
                            style: Theming.of(context).text.body.copyWith(
                              fontWeight: FontWeight.normal,
                              shadows: [
                                Shadow(color: Theming.of(context).shadow)
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        AnimatedPositioned(
          left: 0.0,
          right: 0.0,
          bottom: _showingControls
              ? MediaQuery.of(context).padding.bottom + 16.0
              : -(60.0 + 16),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (widget.localRenderer != null)
                Container(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    alignment: Alignment.bottomRight,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.all(
                        Radius.circular(32),
                      ),
                    ),
                    clipBehavior: Clip.hardEdge,
                    constraints: const BoxConstraints(
                      maxWidth: 100,
                      maxHeight: 200,
                    ),
                    child: Opacity(
                      opacity: 0.5,
                      child: RTCVideoView(
                        widget.localRenderer!,
                        mirror: true,
                        objectFit:
                            RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _CallControlButton(
                      onPressed: widget.onToggleMute,
                      size: 56,
                      child: widget.muted
                          ? const Icon(Icons.mic_off)
                          : const Icon(Icons.mic),
                    ),
                    _CallControlButton(
                      onPressed: widget.onHangUp,
                      scrimColor: const Color.fromARGB(0xFF, 0xFF, 0x00, 0x00),
                      gradientColor:
                          const Color.fromARGB(0xFF, 0xFF, 0x88, 0x88),
                      size: 66,
                      child: const Icon(
                        Icons.call_end,
                        size: 40,
                      ),
                    ),
                    _CallControlButton(
                      onPressed: widget.rekindles
                              .map((r) => r.uid)
                              .contains(widget.profiles.first.uid)
                          ? () => widget.onConnect(widget.profiles.first.uid)
                          : null,
                      size: 56,
                      child: const Icon(Icons.person_add),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ],
    );
  }
}

class _CallControlButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color scrimColor;
  final Color? gradientColor;
  final double size;
  final Widget child;

  const _CallControlButton({
    Key? key,
    this.onPressed,
    this.scrimColor = Colors.white,
    this.gradientColor,
    required this.size,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Button(
      onPressed: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Theming.of(context).shadow,
              offset: const Offset(0.0, 4.0),
              blurRadius: 1.0,
            ),
          ],
          gradient: gradientColor == null
              ? null
              : RadialGradient(
                  colors: [
                    scrimColor,
                    gradientColor!,
                  ],
                  stops: const [0.7, 1.0],
                ),
          color: scrimColor.withOpacity(0.4),
        ),
        child: IconTheme(
          data: IconTheme.of(context).copyWith(
            color: Colors.white,
            size: 32,
          ),
          child: child,
        ),
      ),
    );
  }
}
