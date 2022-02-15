import 'package:flutter/material.dart';
import 'package:openup/widgets/theming.dart';

class NotificationBanner extends StatelessWidget {
  final String contents;

  const NotificationBanner({
    Key? key,
    required this.contents,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          bottomLeft: Radius.circular(24),
        ),
        color: Theming.of(context).notificationRed,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 24,
          horizontal: 8,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.warning),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                contents,
                style: Theming.of(context).text.caption,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
