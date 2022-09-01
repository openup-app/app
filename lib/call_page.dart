import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:openup/api/call_manager.dart';
import 'package:openup/api/signaling/phone.dart';
import 'package:openup/api/users/profile.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/theming.dart';

class CallPage extends StatefulWidget {
  const CallPage({Key? key}) : super(key: key);

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  @override
  void initState() {
    super.initState();
    GetIt.instance.get<CallManager>().callPageActive = true;
  }

  @override
  void dispose() {
    GetIt.instance.get<CallManager>().callPageActive = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Call'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            StreamBuilder<CallState>(
              initialData: const CallState.none(),
              stream: GetIt.instance.get<CallManager>().callState,
              builder: (context, snapshot) {
                final callState = snapshot.requireData;
                return callState.when(
                  none: () {
                    return Center(
                      child: Text('Call state none'),
                    );
                  },
                  initializing: (outgoing) {
                    return Center(
                      child: Text(
                          'Initialising, ${outgoing ? 'outgoing' : 'incoming'}'),
                    );
                  },
                  engaged: () {
                    return Center(
                      child: Text('Engaged'),
                    );
                  },
                  active: (call) {
                    return Center(
                      child: StreamBuilder<PhoneConnectionState>(
                        stream: call.phone.connectionStateStream,
                        initialData: PhoneConnectionState.none,
                        builder: (context, snapshot) {
                          final state = snapshot.requireData;
                          return Text('call ${call.rid}, $state');
                        },
                      ),
                    );
                  },
                  ended: () {
                    return Center(
                      child: Text('call ended'),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _RingingDisplay extends StatelessWidget {
  final SimpleProfile profile;
  const _RingingDisplay({
    Key? key,
    required this.profile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Container(
            width: 200,
            height: 200,
            clipBehavior: Clip.hardEdge,
            decoration: const BoxDecoration(shape: BoxShape.circle),
            child: Image.network(
              profile.photo,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            profile.name,
            textAlign: TextAlign.center,
            style: Theming.of(context)
                .text
                .body
                .copyWith(fontSize: 36, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 14),
          Text(
            'ringing...',
            textAlign: TextAlign.center,
            style: Theming.of(context)
                .text
                .body
                .copyWith(fontSize: 24, fontWeight: FontWeight.w300),
          ),
        ],
      ),
    );
  }
}

class _CallControls extends StatelessWidget {
  final bool speakerphoneEnabled;
  final bool micEnabled;
  final bool videoEnabled;
  final VoidCallback? onToggleSpeakerphone;
  final VoidCallback? onToggleMic;
  final VoidCallback? onToggleVideo;
  final VoidCallback onHangUp;
  final Brightness brightness;

  const _CallControls({
    Key? key,
    required this.speakerphoneEnabled,
    required this.micEnabled,
    required this.videoEnabled,
    required this.onToggleSpeakerphone,
    required this.onToggleMic,
    required this.onToggleVideo,
    required this.onHangUp,
    this.brightness = Brightness.dark,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _BarButton(
          onPressed: onToggleSpeakerphone,
          icon: const Icon(Icons.volume_up),
          brightness: brightness,
          selected: false,
        ),
        _BarButton(
          onPressed: onToggleVideo,
          icon: const Icon(Icons.videocam),
          brightness: brightness,
          selected: false,
        ),
        _BarButton(
          onPressed: onToggleMic,
          icon: const Icon(Icons.mic),
          brightness: brightness,
          selected: false,
        ),
        _BarButton(
          icon: const Icon(Icons.call_end),
          color: const Color.fromRGBO(0xFF, 0x00, 0x00, 1.0),
          selected: false,
          onPressed: onHangUp,
        ),
      ],
    );
  }
}

class _BarButton extends StatelessWidget {
  final Widget icon;
  final Brightness brightness;
  final Color? color;
  final bool selected;
  final VoidCallback? onPressed;
  const _BarButton({
    Key? key,
    required this.icon,
    this.brightness = Brightness.dark,
    this.color,
    required this.selected,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Button(
      onPressed: onPressed,
      child: Container(
        width: 80,
        height: 58,
        clipBehavior: Clip.hardEdge,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9),
          color: color ??
              (brightness == Brightness.dark
                  ? (selected
                      ? const Color.fromRGBO(0x32, 0x32, 0x32, 1.0)
                      : const Color.fromRGBO(0x16, 0x16, 0x16, 1.0))
                  : (selected
                      ? const Color.fromRGBO(0x16, 0x16, 0x16, 1.0)
                      : Colors.white)),
        ),
        child: icon,
      ),
    );
  }
}
