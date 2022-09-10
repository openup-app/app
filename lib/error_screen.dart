import 'package:flutter/material.dart';
import 'package:openup/initial_loading_screen.dart';
import 'package:openup/widgets/theming.dart';

class ErrorScreen extends StatelessWidget {
  final bool needsOnboarding;
  const ErrorScreen({
    Key? key,
    this.needsOnboarding = false,
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
              'Could not connect to server',
              style: Theming.of(context)
                  .text
                  .subheading
                  .copyWith(color: Colors.black),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamed(
                  '/',
                  arguments: InitialLoadingScreenArguments(
                    needsOnboarding: needsOnboarding,
                  ),
                );
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
