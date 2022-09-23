import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:lottie/lottie.dart';

class MaleFemaleConnectionImageApart extends StatelessWidget {
  const MaleFemaleConnectionImageApart({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Hero(
        tag: 'male_female_connection',
        child: SizedBox(
          height: 180,
          child: Lottie.asset('assets/images/friends.json'),
        ),
      ),
    );
  }
}
