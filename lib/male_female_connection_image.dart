import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class MaleFemaleConnectionImage extends StatelessWidget {
  const MaleFemaleConnectionImage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          'assets/images/connection_male.png',
          fit: BoxFit.fitHeight,
        ),
        Image.asset(
          'assets/images/connection_female.png',
          fit: BoxFit.fitHeight,
        ),
      ],
    );
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
