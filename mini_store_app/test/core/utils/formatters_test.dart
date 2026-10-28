import 'package:flutter_test/flutter_test.dart';
import 'package:mini_store_app/core/utils/formatters.dart';

void main() {
  group('formatPrice', () {
    test('formats whole and decimal prices', () {
      expect(formatPrice(9.99), r'$9.99');
      expect(formatPrice(1.5), r'$1.50');
      expect(formatPrice(0), r'$0.00');
    });

    test('groups thousands', () {
      expect(formatPrice(2499.99), r'$2,499.99');
      expect(formatPrice(1234567.5), r'$1,234,567.50');
    });
  });

  test('formats ratings to one decimal place', () {
    expect(formatRating(4.567), '4.6');
    expect(formatRating(4), '4.0');
  });

  test('formats discount percentages as rounded labels', () {
    expect(formatDiscount(10.48), '-10%');
    expect(formatDiscount(0.62), '-1%');
  });
}
