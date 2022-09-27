import 'package:flutter/material.dart';
import 'package:openup/widgets/button.dart';

class TabView extends StatefulWidget {
  final bool firstSelected;
  final String firstLabel;
  final String secondLabel;
  final void Function(bool first) onSelected;

  const TabView({
    Key? key,
    required this.firstSelected,
    required this.firstLabel,
    required this.secondLabel,
    required this.onSelected,
  }) : super(key: key);

  @override
  State<TabView> createState() => _TabViewState();
}

class _TabViewState extends State<TabView> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedPadding(
            padding: widget.firstSelected
                ? const EdgeInsets.only(right: 108)
                : const EdgeInsets.only(left: 108),
            duration: const Duration(milliseconds: 150),
            curve: Curves.bounceOut,
            child: Container(
              width: 108,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(15)),
              ),
            ),
          ),
          Container(
            width: 108,
            height: 48,
            margin: const EdgeInsets.only(right: 108),
            child: Button(
              onPressed: () => widget.onSelected(true),
              child: Center(
                child: Text(
                  widget.firstLabel,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w300,
                        color:
                            widget.firstSelected ? Colors.black : Colors.white,
                      ),
                ),
              ),
            ),
          ),
          Container(
            width: 108,
            height: 48,
            margin: const EdgeInsets.only(left: 108),
            child: Button(
              onPressed: () => widget.onSelected(false),
              child: Center(
                child: Text(
                  widget.secondLabel,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w300,
                        color:
                            !widget.firstSelected ? Colors.black : Colors.white,
                      ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
