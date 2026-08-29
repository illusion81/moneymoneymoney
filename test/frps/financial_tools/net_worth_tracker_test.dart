import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/frps/financial_tools/net_worth_tracker.dart';

void main() {
  group('netWorthTracker', () {
    test('sums assets, liabilities, and net worth', () {
      final netWorth = netWorthTracker(
        {'cash': 5000, 'car': 12000},
        {'mortgage': 9000, 'card': 1500},
      );

      expect(netWorth.totalAssets, 17000);
      expect(netWorth.totalLiabilities, 10500);
      expect(netWorth.netWorth, 6500);
    });

    test('empty maps yield zero', () {
      final netWorth = netWorthTracker({}, {});
      expect(netWorth.totalAssets, 0);
      expect(netWorth.totalLiabilities, 0);
      expect(netWorth.netWorth, 0);
    });
  });
}
