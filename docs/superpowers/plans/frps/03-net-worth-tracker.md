# Task 3: netWorthTracker

**Wave:** 1 (parallel). Pure Dart. No Flutter imports. No dependencies.

**Files:**
- Create: `lib/frps/financial_tools/net_worth_tracker.dart`
- Create: `test/frps/financial_tools/net_worth_tracker_test.dart`

**Produces:**

```dart
class NetWorth {
  const NetWorth({
    required this.totalAssets,
    required this.totalLiabilities,
    required this.netWorth,
  });
  final double totalAssets;
  final double totalLiabilities;
  final double netWorth;
}

NetWorth netWorthTracker(Map<String, double> assets, Map<String, double> liabilities);
```

**Rules (spec §netWorthTracker):**
- `totalAssets` = sum of `assets` values.
- `totalLiabilities` = sum of `liabilities` values.
- `netWorth` = `totalAssets - totalLiabilities`.

- [ ] **Step 1: Write the failing test**

Create `test/frps/financial_tools/net_worth_tracker_test.dart`:

```dart
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
```

- [ ] **Step 2: Run and verify RED**

`flutter test test/frps/financial_tools/net_worth_tracker_test.dart`
Expected: FAIL — file does not exist.

- [ ] **Step 3: Implement**

Implement per the interface and rules.

- [ ] **Step 4: Run and verify GREEN**

`flutter test test/frps/financial_tools/net_worth_tracker_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/frps/financial_tools/net_worth_tracker.dart test/frps/financial_tools/net_worth_tracker_test.dart
git commit -m "feat(frps): add net worth tracker tool"
```
