import 'package:flutter/material.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/theming.dart';

class ProfileButton extends StatelessWidget {
  final Color color;
  const ProfileButton({
    Key? key,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Button(
      onPressed: () => Scaffold.of(context).openEndDrawer(),
      child: Stack(
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Theming.of(context).shadow,
                    offset: const Offset(0.0, 4.0),
                    blurRadius: 4.0,
                  ),
                ],
                color: color,
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                'assets/images/profile.png',
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Theming.of(context).shadow,
                    offset: const Offset(0.0, 4.0),
                    blurRadius: 2.0,
                  ),
                ],
                shape: BoxShape.circle,
                color: Theming.of(context).alertRed,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
