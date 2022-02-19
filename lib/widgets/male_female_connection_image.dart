import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

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
                height: 210,
                left: -115,
                bottom: -25,
                child: Image.asset('assets/images/friends.gif'),
              ),
              Positioned(
                height: 210,
                right: -132,
                bottom: -25,
                child: Image.asset('assets/images/friends.gif'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
