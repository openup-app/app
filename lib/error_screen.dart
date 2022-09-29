import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:openup/initial_loading_screen.dart';

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
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: Colors.black,
                    fontSize: 22,
                  ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.goNamed(
                  'initialLoading',
                  extra: InitialLoadingScreenArguments(
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
