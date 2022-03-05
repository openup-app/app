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
          child: Stack(
            clipBehavior: Clip.hardEdge,
            fit: StackFit.loose,
            children: [
              Positioned(
                height: 250,
                left: -148,
                bottom: -44,
                child: Lottie.asset('assets/images/friends.json'),
              ),
              Positioned(
                height: 250,
                right: -170,
                bottom: -44,
                child: Lottie.asset('assets/images/friends.json'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
