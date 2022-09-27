import 'package:flutter/material.dart';

class OpenupDialog extends StatelessWidget {
  final Widget title;
  final List<Widget> actions;
  const OpenupDialog({
    Key? key,
    required this.title,
    this.actions = const [],
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
      child: Center(
        child: Container(
          width: 321,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(20)),
            color: Colors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 79),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: title,
              ),
              const SizedBox(height: 42),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: actions,
              ),
              const SizedBox(height: 58),
            ],
          ),
        ),
      ),
    );
  }
}
