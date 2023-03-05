import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:openup/widgets/button.dart';

class SignUpFriends extends StatefulWidget {
  const SignUpFriends({super.key});

  @override
  State<SignUpFriends> createState() => _SignUpFriendsState();
}

class _SignUpFriendsState extends State<SignUpFriends> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Add friends'),
            Button(
              onPressed: () {
                context.goNamed(
                  'discover',
                  queryParams: {'welcome': 'true'},
                );
              },
              child: Text('Next'),
            ),
          ],
        ),
      ),
    );
  }
}
