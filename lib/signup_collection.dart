import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:openup/widgets/button.dart';

class SignUpCollection extends StatefulWidget {
  const SignUpCollection({super.key});

  @override
  State<SignUpCollection> createState() => _SignUpCollectionState();
}

class _SignUpCollectionState extends State<SignUpCollection> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Collection'),
            Button(
              onPressed: () => context.goNamed('signup_friends'),
              child: Text('Next'),
            ),
          ],
        ),
      ),
    );
  }
}
