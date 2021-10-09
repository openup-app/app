import 'package:flutter/material.dart';

class PublicProfileScreen extends StatelessWidget {
  const PublicProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Public Profile'),
          TextButton(
            onPressed: () =>
                Navigator.of(context).pushNamed('public-profile-edit'),
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }
}
