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
        left: 30,
        top: 17,
        bottom: 4,
      ),
      child: DefaultTextStyle.merge(
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Color.fromRGBO(0xAA, 0xAA, 0xAA, 1.0),
        ),
        child: title,
      ),
    );
  }
}
