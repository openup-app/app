import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class MaleFemaleConnectionImage extends StatelessWidget {
  final Color? color;
  const MaleFemaleConnectionImage({
    Key? key,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Image.asset('assets/images/friends.gif');
  }
}

class MaleFemaleConnectionImageApart extends StatelessWidget {
  const MaleFemaleConnectionImageApart({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image.asset(
            'assets/images/connection_female.png',
            fit: BoxFit.fitHeight,
          ),
          Image.asset(
            'assets/images/connection_male.png',
            fit: BoxFit.fitHeight,
          ),
        ],
      ),
    );
  }
}
