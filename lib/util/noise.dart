import 'dart:math';

class PerlinNoise {
  final int _seed;

  PerlinNoise({
    required int size,
    required int seed,
  }) : _seed = seed;

  double at(
    double t, {
    required double frequency,
    required double amplitude,
    int? seed,
  }) {
    final period = 1 / frequency;
    final integral = t ~/ period;
    final local = t / period - (t / period).truncate();
    final gradientL = _gradient(integral, seed: seed);
    final gradientR = _gradient(integral + 1, seed: seed);
    final lToLocal = local;
    final rToLocal = local - 1;
    final dotL = gradientL * lToLocal;
    final dotR = gradientR * rToLocal;
    return lerp(dotL, dotR, ease(local)) * amplitude;
  }

  double _gradient(int t, {int? seed}) {
    final random = Random((seed ?? _seed) + t);
    final value = random.nextDouble() * 2 * pi;
    return cos(value);
  }

  double lerp(double a, double b, double t) => a + t * (b - a);

  double ease(double t) => -2.0 * pow(t, 3) + 3.0 * pow(t, 2);
}
