import 'dart:math';

/// Produces readable, locally unique order numbers such as `MS-20481`.
abstract interface class OrderNumberGenerator {
  String next();
}

class RandomOrderNumberGenerator implements OrderNumberGenerator {
  RandomOrderNumberGenerator({Random? random, DateTime Function()? now})
    : _random = random ?? Random.secure(),
      _now = now ?? DateTime.now;

  final Random _random;
  final DateTime Function() _now;
  String? _last;

  @override
  String next() {
    for (var attempt = 0; attempt < 32; attempt++) {
      final candidate = 'MS-${10000 + _random.nextInt(90000)}';
      if (candidate != _last) {
        _last = candidate;
        return candidate;
      }
    }

    // Extremely unlikely fallback: derive from the clock instead of repeating
    // the previous number.
    final candidate = 'MS-${10000 + _now().millisecondsSinceEpoch % 90000}';
    _last = candidate;
    return candidate;
  }
}
