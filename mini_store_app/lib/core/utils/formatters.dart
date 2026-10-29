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

const List<String> _months = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// Compact, locale-independent date for order history receipts.
String formatOrderDate(DateTime value) {
  final local = value.toLocal();
  final month = _months[local.month - 1];
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${local.day} $month ${local.year}, $hour:$minute';
}
