/// Presentation-friendly number and price formatting.
///
/// Kept dependency-free so the same helpers work in tests and on every
/// platform without locale initialization.
String formatPrice(double price) {
  final fixed = price.toStringAsFixed(2);
  final parts = fixed.split('.');
  final whole = parts.first;
  final buffer = StringBuffer();

  for (var index = 0; index < whole.length; index++) {
    final remaining = whole.length - index;
    if (index > 0 && remaining % 3 == 0 && whole[index] != '-') {
      buffer.write(',');
    }
    buffer.write(whole[index]);
  }

  return '\$${buffer.toString()}.${parts.last}';
}

String formatRating(double rating) => rating.toStringAsFixed(1);

String formatDiscount(double percentage) => '-${percentage.round()}%';
