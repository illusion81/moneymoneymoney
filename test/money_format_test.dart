import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/services/money_format.dart';

void main() {
  group('formatMoney', () {
    test('shows cents below 1000', () {
      expect(formatMoney(12.5), r'$12.50');
      expect(formatMoney(0), r'$0.00');
      expect(formatMoney(999.99), r'$999.99');
    });

    test('drops cents at 1000 and above, where they are noise', () {
      expect(formatMoney(1000), r'$1000');
      expect(formatMoney(2543.67), r'$2544');
    });

    test('uses magnitude, not sign, to decide precision', () {
      expect(formatMoney(-12.5), r'$-12.50');
      expect(formatMoney(-2543.67), r'$-2544');
    });
  });
}
