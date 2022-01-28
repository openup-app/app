import 'dart:async';

import 'package:flutter/material.dart';
import 'package:openup/api/matches/matches_api.dart';
import 'package:openup/api/users/preferences.dart';
import 'package:openup/widgets/theming.dart';

import '../main.dart';

class MatchingUsersOnline extends StatefulWidget {
  final Preferences preferences;

  const MatchingUsersOnline({Key? key, required this.preferences})
      : super(key: key);

  @override
  _MatchingUsersOnlineState createState() => _MatchingUsersOnlineState();
}

class _MatchingUsersOnlineState extends State<MatchingUsersOnline> {
  late final MatchesApi _api;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _api = MatchesApi(
      host: host,
      port: socketPort,
      preferences: widget.preferences,
      onConnectionError: () {},
    );
  }

  @override
  void dispose() {
    _api.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(MatchingUsersOnline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.preferences != widget.preferences) {
      _timer?.cancel();
      _timer = Timer(const Duration(milliseconds: 300), () {
        _api.sendPreferences(widget.preferences);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _api.countStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }
        final count = snapshot.requireData;
        return Text(
          '$count',
          style: Theming.of(context).text.body.copyWith(color: Colors.black),
        );
      },
    );
  }
}
