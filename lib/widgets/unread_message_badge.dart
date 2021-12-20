import 'dart:math';

import 'package:flutter/material.dart';
import 'package:openup/widgets/theming.dart';

class UnreadMessageBadge extends StatelessWidget {
  final int count;
  const UnreadMessageBadge({
    Key? key,
    required this.count,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color.fromRGBO(0xDC, 0x35, 0x35, 1.0),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            blurRadius: 4,
            spreadRadius: 2,
            offset: const Offset(0, 2),
            color: Theming.of(context).shadow,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        min(count, 9).toString(),
        textAlign: TextAlign.center,
        maxLines: 1,
        style: Theming.of(context).text.bodySecondary.copyWith(fontSize: 16),
      ),
    );
  }
}
