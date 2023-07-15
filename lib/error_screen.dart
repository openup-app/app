import 'package:flutter/material.dart';
import 'package:openup/widgets/restart_app.dart';

class ErrorScreen extends StatelessWidget {
  const ErrorScreen({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: Colors.black,
                    fontSize: 22,
                  ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => RestartApp.restartApp(context),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
