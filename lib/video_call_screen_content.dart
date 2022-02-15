import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:openup/api/signaling/phone.dart';
import 'package:openup/call_screen.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/theming.dart';
import 'package:openup/widgets/time_remaining.dart';

/// Video call display and controls.
///
/// Setting [endTime] to `null` will disable the timer UI and will not
/// trigger [onTimeUp].
class VideoCallScreenContent extends StatefulWidget {
  final RTCVideoRenderer? localRenderer;
  final List<UserConnection> users;
  final bool hasSentTimeRequest;
  final DateTime? endTime;
  final bool muted;
  final bool isGroupLobby;
  final bool readyForGroupCall;
  final VoidCallback onTimeUp;
  final VoidCallback onHangUp;
  final void Function(String uid) onConnect;
  final void Function(String uid) onReport;
  final VoidCallback onSendTimeRequest;
  final VoidCallback onToggleMute;
  final void Function() onSendReadyForGroupCall;

  const VideoCallScreenContent({
    Key? key,
    required this.localRenderer,
    required this.users,
    required this.hasSentTimeRequest,
    required this.endTime,
    required this.muted,
    required this.isGroupLobby,
    required this.readyForGroupCall,
    required this.onTimeUp,
    required this.onHangUp,
    required this.onConnect,
    required this.onReport,
    required this.onSendTimeRequest,
    required this.onToggleMute,
    required this.onSendReadyForGroupCall,
  }) : super(key: key);

  @override
  State<VideoCallScreenContent> createState() => _VideoCallScreenContentState();
}

class _VideoCallScreenContentState extends State<VideoCallScreenContent> {
  bool _showingControls = true;

  @override
  Widget build(BuildContext context) {
    final groupCall = widget.users.length > 1;
    final tempFirstUser = widget.users.first;
    final waitingForMe = !widget.readyForGroupCall;
    final waitingForFriend =
        !waitingForMe && !widget.users.first.readyForGroupCall;
    final matching = !(waitingForMe && waitingForFriend);
    return Stack(
      children: [
        if (!groupCall) ...[
          if (widget.users.first.videoRenderer != null)
            Positioned.fill(
              child: GestureDetector(
                onTap: () =>
                    setState(() => _showingControls = !_showingControls),
                child: RTCVideoView(
                  widget.users.first.videoRenderer!,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                ),
              ),
            ),
        ] else ...[
          for (var i = 0; i < 2; i++)
            if (widget.users[i].videoRenderer != null)
              Align(
                alignment: [
                  Alignment.topLeft,
                  Alignment.topRight,
                  Alignment.bottomLeft
                ][i],
                child: Container(
                  padding: const EdgeInsets.all(8),
                  color: [Colors.blue, Colors.orange, Colors.pink][i],
                  child: FractionallySizedBox(
                    widthFactor: 0.5,
                    heightFactor: 0.5,
                    child: RTCVideoView(
                      widget.users[i].videoRenderer!,
                      objectFit:
                          RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    ),
                  ),
                ),
              ),
          Align(
            alignment: Alignment.bottomRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 0.5,
              child: RTCVideoView(
                widget.localRenderer!,
                mirror: true,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
              ),
            ),
          ),
        ],
        if (widget.isGroupLobby)
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 36.0),
              child: Button(
                onPressed: waitingForMe ? widget.onSendReadyForGroupCall : null,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(24)),
                    color: Theme.of(context)
                        .colorScheme
                        .secondary
                        .withOpacity(1.0),
                    boxShadow: [
                      BoxShadow(
                        color: Theming.of(context).shadow,
                        offset: const Offset(0.0, 4.0),
                        blurRadius: 1.0,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (waitingForMe)
                        const Icon(Icons.done)
                      else if (waitingForFriend)
                        const Icon(Icons.close)
                      else if (matching)
                        const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                      const SizedBox(width: 8),
                      if (waitingForMe)
                        const Text('I am ready')
                      else if (waitingForFriend)
                        const Text('Friend is not ready')
                      else if (matching)
                        const Text('Finding a match...'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        AnimatedPositioned(
          left: _showingControls ? 16.0 : -(56.0 + 16.0),
          top: MediaQuery.of(context).padding.top + 32.0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
          child: _CallControlButton(
            onPressed: () => widget.onReport(tempFirstUser.profile.uid),
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
              if (!groupCall && widget.localRenderer != null)
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
                    if (tempFirstUser.rekindle != null)
                      _CallControlButton(
                        onPressed: () =>
                            widget.onConnect(tempFirstUser.profile.uid),
                        size: 56,
                        child: const Icon(Icons.person_add),
                      )
                    else
                      const SizedBox(width: 56),
                  ],
                ),
              )
            ],
          ),
        ),
        Center(
          child: Builder(
            builder: (context) {
              final style = Theming.of(context).text.headline;
              final text = connectionStateText(
                connectionState: tempFirstUser.connectionState,
                name: tempFirstUser.profile.name,
              );
              if (tempFirstUser.connectionState == PhoneConnectionState.none) {
                return const SizedBox.shrink();
              } else {
                return AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  opacity: tempFirstUser.connectionState ==
                          PhoneConnectionState.connected
                      ? 0.0
                      : 1.0,
                  child: Text(
                    text,
                    style: style,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                );
              }
            },
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
