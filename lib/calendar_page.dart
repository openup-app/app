import 'package:flutter/material.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/scaffold.dart';

class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: OpenupAppBar(
        body: OpenupAppBarBody(
          leading: Button(
            onPressed: Navigator.of(context).pop,
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Cancel'),
            ),
          ),
          center: const Text('Calendar'),
        ),
      ),
      body: FlutterLogo(),
    );
  }
}
