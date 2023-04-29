import 'package:flutter/material.dart';

class SectionTitle extends StatelessWidget {
  final Widget title;

  const SectionTitle({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 17,
        top: 17,
        bottom: 4,
      ),
      child: DefaultTextStyle(
        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: const Color.fromRGBO(0x85, 0x85, 0x8A, 1.0)),
        child: title,
      ),
    );
  }
}
