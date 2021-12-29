import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openup/api/users/users_api.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/theming.dart';

class ProfileButton extends ConsumerWidget {
  final Color color;
  const ProfileButton({
    Key? key,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            child: StreamBuilder<int>(
              stream: ref.read(usersApiProvider).unreadChatMessageSumStream,
              initialData: 0,
              builder: (context, snapshot) {
                final sum = snapshot.requireData;
                if (sum == 0) {
                  return const SizedBox.shrink();
                }
                return Container(
                  width: 16,
                  height: 16,
                  alignment: Alignment.center,
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
                  child: Text(
                    sum.toString(),
                    textAlign: TextAlign.center,
                    style: Theming.of(context).text.caption,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
