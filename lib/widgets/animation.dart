import 'package:flutter/material.dart';
import 'package:openup/util/noise.dart';
import 'package:openup/widgets/common.dart';

const _seed = 585384;

typedef WiggleGenerator = double Function({
  required double frequency,
  required double amplitude,
  Duration? delay,
});

class WiggleBuilder extends StatefulWidget {
  final bool enabled;

  final int? seed;
  final Widget Function(
    BuildContext context,
    Widget? child,
    WiggleGenerator wiggle,
  ) builder;
  final Widget? child;

  const WiggleBuilder({
    super.key,
    this.enabled = true,
    this.seed,
    required this.builder,
    this.child,
  });

  @override
  State<WiggleBuilder> createState() => _WiggleBuilderState();
}

class _WiggleBuilderState extends State<WiggleBuilder> {
  late DateTime _start;
  late PerlinNoise _noise;

  @override
  void initState() {
    super.initState();
    _start = DateTime.now();
    _noise = PerlinNoise(seed: widget.seed ?? _seed);
  }

  @override
  void didUpdateWidget(covariant WiggleBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.seed != widget.seed) {
      _noise = PerlinNoise(seed: widget.seed ?? _seed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TickerBuilder(
      enabled: widget.enabled,
      builder: (context) {
        final now = DateTime.now();
        final elapsed = now.difference(_start);
        final t = elapsed.inMilliseconds / 1000;
        int seedModifier = 0;
        return widget.builder(
          context,
          widget.child,
          ({
            required double frequency,
            required double amplitude,
            Duration? delay,
          }) {
            return _noise.at(
              t - (delay?.inMilliseconds ?? 0) / 1000,
              frequency: frequency,
              amplitude: amplitude,
              seed: seedModifier++,
            );
          },
        );
      },
    );
  }
}
