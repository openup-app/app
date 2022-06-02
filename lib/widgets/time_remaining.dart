import 'dart:async';

import 'package:flutter/widgets.dart';

class TimeRemaining extends StatefulWidget {
  final DateTime endTime;
  final VoidCallback onTimeUp;
  final Widget Function(BuildContext context, String remaining) builder;
  const TimeRemaining({
    Key? key,
    required this.endTime,
    required this.onTimeUp,
    required this.builder,
  }) : super(key: key);

  @override
  State<TimeRemaining> createState() => _TimeRemainingState();
}

class _TimeRemainingState extends State<TimeRemaining> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();

    const interval = Duration(seconds: 1);
    _timer = Timer.periodic(
      interval,
      (_) {
        setState(() {});
        if (DateTime.now().isAfter(widget.endTime)) {
          _timer.cancel();
          widget.onTimeUp();
        }
      },
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.endTime.difference(DateTime.now());
    return widget.builder(
      context,
      _formatDuration(remaining),
    );
  }

  String _formatDuration(Duration duration) {
    return '${_padded(duration.inMinutes)}:${_padded(duration.inSeconds.remainder(60))}';
  }

  String _padded(int value) => value.toString().padLeft(2, '0');
}
