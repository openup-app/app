import 'package:flutter/material.dart';
import 'package:openup/menu_page.dart';
import 'package:openup/widgets/invite_friends.dart';

class PeoplePage extends StatelessWidget {
  const PeoplePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/people_background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: InviteFriends(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top,
                  bottom: MediaQuery.of(context).padding.bottom + 72,
                ),
              ),
            ),
            const Positioned(
              right: 32,
              bottom: 32,
              child: MenuButton(
                color: Color.fromRGBO(0xD3, 0x00, 0x00, 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
