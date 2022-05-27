import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/profile_photo.dart';
import 'package:openup/widgets/theming.dart';

class ProfileButton extends ConsumerWidget {
  const ProfileButton({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Hero(
      tag: 'profile_button',
      child: Button(
        onPressed: () => Scaffold.of(context).openEndDrawer(),
        child: Stack(
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: Container(
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Theming.of(context).shadow,
                      offset: const Offset(0.0, 4.0),
                      blurRadius: 4.0,
                    ),
                  ],
                  shape: BoxShape.circle,
                ),
                child: Consumer(
                  builder: (context, ref, child) {
                    final gallery =
                        ref.watch(userProvider).profile?.gallery ?? [];
                    final photo = ref.watch(userProvider).profile?.photo ?? '';
                    if (gallery.isEmpty) {
                      return const DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(40)),
                          color: Color.fromRGBO(0xC4, 0xC4, 0xC4, 0.5),
                        ),
                        child: Icon(
                          Icons.add,
                          size: 48,
                        ),
                      );
                    }
                    return ProfilePhoto(
                      url: photo,
                      fit: BoxFit.cover,
                    );
                  },
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: Consumer(
                builder: (context, ref, _) {
                  final unreadMessageCount = ref
                      .watch(userProvider.select((p) => p.unreadMessageCount));
                  final sum =
                      unreadMessageCount.values.fold<int>(0, (p, e) => p + e);
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
      ),
    );
  }
}
