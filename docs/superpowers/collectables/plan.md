# Collectables Implementation Plan — XP, Coins, Skins, Lootbox Eggs

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an in-memory reward economy — coins with a $20 beta grant, an XP curve, 20 animal skins, and three lootbox egg tiers — plus coin, XP-orb and egg viz gameobjects, all reachable and previewable from the workbench.

**Architecture:** `lib/collect/` holds pure, injectable-random services and immutable models; `lib/viz/collectables/` holds three new draw-only `VizRig`s. A skin is a `VizPalette` swapped into an existing rig at paint time, so the animals built in the viz project need no changes. `PlayerState` is owned by `MyApp` alongside the existing report and forest summary. `lib/collect/` may import `lib/viz/`; never the reverse.

**Tech Stack:** Flutter Material, Dart 3 pattern matching and records, `dart:math` `Random` (always injected), `flutter_test`. No new package dependencies.

**Spec:** `docs/superpowers/collectables/spec.md`

**Prerequisite:** every task in `docs/superpowers/viz-animals/plan.md` is complete and committed — including Task 0, which greens the test baseline and adds the `pumpApp` helper this plan's Task 8 test relies on.

## Global Constraints

- **No new package dependencies.**
- **`lib/viz/` must never import from `lib/collect/`.** The reverse is allowed. The workbench, being a screen, may read both.
- **Nothing under `lib/viz/collectables/` handles a gesture, mutates state, reads app state, navigates, or calls a service.**
- **Every `z` within a rig is unique; every pose term is periodic over `t` in `[0, 1)`.**
- **Services never construct a `Random`.** Randomness is a required parameter so tests are deterministic with `Random(seed)`.
- **No persistence.** State lives in memory for the session.
- **No real money.** The beta grant is 20 integer coins displayed as `$20.00`.
- Exact copy, verbatim: `You start with $20.00 beta credit`.
- Beta grant constant: `Wallet.betaGrantCoins = 20`.
- XP curve, verbatim: `xpForLevel(level) = 25 * level * (level - 1)`, level capped at 50.
- **`flutter analyze` must report no issues before every commit**, and `flutter test` must pass.

## Execution Roles

| Task | Executor | Why |
| --- | --- | --- |
| 1. Wallet and XP | **opencode MiMo V2.5** (`opencode run -m opencode/mimo-v2.5-free --dir /home/jostev/Projects/moneymoneymoney`) | Pure arithmetic, fully specified, zero Flutter. |
| 2. Skins and skin catalog | **Haiku** | Bulk colour data against a fixed schema. |
| 3. Eggs and hatching | **Sonnet** | Weighted rolling with rarity fallback is the trickiest logic here. |
| 4. Player state and economy | **Sonnet** | The integration seam every later task consumes. |
| 5. Coin and XP orb viz | **Haiku** | Mechanical rig work, patterned on the animals. |
| 6. Egg viz | **Sonnet** | Three-state shell rig with separating halves. |
| 7. Workbench collectables and skin picker | **Sonnet** | Touches an existing screen and its tests. |
| 8. Beta credit HUD and check-in wiring | **Haiku** | Touches `main.dart` and `home_screen.dart`. |

Opus orchestrates and runs the review gate between every task.

---

## File Structure

- `lib/collect/models/wallet.dart` — coin balance, beta grant, spend/earn.
- `lib/collect/models/xp_state.dart` — total XP, level curve, progress.
- `lib/collect/models/skin.dart` — `SkinRarity`, `Skin`.
- `lib/collect/models/egg.dart` — `EggKind`, `EggDef`, `HatchResult`.
- `lib/collect/models/player_state.dart` — wallet + XP + ownership + equipped.
- `lib/collect/catalog/skin_catalog.dart` — the 20 skins.
- `lib/collect/catalog/egg_catalog.dart` — the 3 eggs and refund table.
- `lib/collect/services/economy_service.dart` — day rewards and application.
- `lib/collect/services/egg_service.dart` — purchase and hatching.
- `lib/collect/services/skin_service.dart` — grant, equip, palette resolution.
- `lib/viz/collectables/coin_viz.dart`, `xp_orb_viz.dart`, `egg_viz.dart`.
- `lib/screens/widgets/wallet_hud.dart` — level, XP bar, coins, beta line.
- Modified: `lib/viz/viz_catalog.dart`, `lib/viz/workbench/viz_workbench_screen.dart`, `lib/main.dart`, `lib/screens/home_screen.dart`.
- Tests: `test/collect/wallet_test.dart`, `xp_state_test.dart`, `skin_catalog_test.dart`, `egg_service_test.dart`, `economy_service_test.dart`, `skin_service_test.dart`; `test/viz/coin_viz_test.dart`, `xp_orb_viz_test.dart`, `egg_viz_test.dart`; `test/viz/viz_workbench_collectables_test.dart`; `test/wallet_hud_test.dart`.

---

### Task 1: Wallet And XP Curve

**Executor:** opencode MiMo V2.5. Invoke with:

```bash
opencode run -m opencode/mimo-v2.5-free \
  --dir /home/jostev/Projects/moneymoneymoney \
  "Implement Task 1 of docs/superpowers/collectables/plan.md exactly as written. Read docs/superpowers/collectables/spec.md first. Do not modify any file outside the ones the task lists."
```

**Files:**
- Create: `lib/collect/models/wallet.dart`
- Create: `lib/collect/models/xp_state.dart`
- Test: `test/collect/wallet_test.dart`
- Test: `test/collect/xp_state_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces: `class Wallet { const Wallet({required int coins}); const Wallet.beta(); static const int betaGrantCoins = 20; final int coins; bool canAfford(int amount); Wallet earn(int amount); Wallet spend(int amount); String get creditLabel; }`
- Produces: `class XpState { const XpState({required int totalXp}); const XpState.empty(); static const int maxLevel = 50; final int totalXp; int get level; int get xpIntoLevel; int get xpForNextLevel; double get levelProgress; XpState gain(int amount); static int xpForLevel(int level); static int levelForXp(int xp); }`

- [ ] **Step 1: Write the failing wallet and XP tests**

Create `test/collect/wallet_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/collect/models/wallet.dart';

void main() {
  test('a beta wallet starts with the 20 coin grant', () {
    expect(const Wallet.beta().coins, 20);
    expect(Wallet.betaGrantCoins, 20);
  });

  test('formats the balance as currency for the beta credit line', () {
    expect(const Wallet.beta().creditLabel, r'$20.00');
    expect(const Wallet(coins: 7).creditLabel, r'$7.00');
  });

  test('earning adds coins', () {
    expect(const Wallet(coins: 5).earn(3).coins, 8);
  });

  test('spending subtracts coins', () {
    expect(const Wallet(coins: 20).spend(12).coins, 8);
  });

  test('canAfford is inclusive of the exact balance', () {
    expect(const Wallet(coins: 5).canAfford(5), isTrue);
    expect(const Wallet(coins: 5).canAfford(6), isFalse);
  });

  test('overspending throws instead of going negative', () {
    expect(() => const Wallet(coins: 5).spend(6), throwsStateError);
  });

  test('earning or spending a negative amount throws', () {
    expect(() => const Wallet(coins: 5).earn(-1), throwsArgumentError);
    expect(() => const Wallet(coins: 5).spend(-1), throwsArgumentError);
  });
}
```

Create `test/collect/xp_state_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/collect/models/xp_state.dart';

void main() {
  test('the curve matches the published thresholds', () {
    expect(XpState.xpForLevel(1), 0);
    expect(XpState.xpForLevel(2), 50);
    expect(XpState.xpForLevel(3), 150);
    expect(XpState.xpForLevel(4), 300);
    expect(XpState.xpForLevel(5), 500);
  });

  test('levelForXp agrees with the curve at every boundary', () {
    for (var level = 1; level <= 20; level++) {
      final threshold = XpState.xpForLevel(level);
      expect(XpState.levelForXp(threshold), level, reason: 'at level $level');
      if (level > 1) {
        expect(XpState.levelForXp(threshold - 1), level - 1,
            reason: 'below level $level');
      }
    }
  });

  test('the level is capped', () {
    expect(XpState(totalXp: 99999999).level, XpState.maxLevel);
    expect(XpState(totalXp: 99999999).levelProgress, 1.0);
    expect(XpState(totalXp: 99999999).xpForNextLevel, 0);
  });

  test('progress within a level is a 0..1 fraction', () {
    const state = XpState(totalXp: 100); // level 2 spans 50..150
    expect(state.level, 2);
    expect(state.xpIntoLevel, 50);
    expect(state.xpForNextLevel, 100);
    expect(state.levelProgress, closeTo(0.5, 0.0001));
  });

  test('gaining XP accumulates and never decreases', () {
    expect(const XpState.empty().gain(10).gain(5).totalXp, 15);
    expect(() => const XpState.empty().gain(-1), throwsArgumentError);
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/collect/`
Expected: FAIL — `Target of URI doesn't exist: 'package:moneymoneymoney/collect/models/wallet.dart'`.

- [ ] **Step 3: Write the wallet and XP models**

Create `lib/collect/models/wallet.dart`:

```dart
/// Soft-currency balance. Coins are whole numbers; the app never touches real
/// money. The beta grant is displayed as currency because that reads as a gift
/// rather than a score.
class Wallet {
  const Wallet({required this.coins});

  /// Every new beta player starts here.
  const Wallet.beta() : coins = betaGrantCoins;

  static const int betaGrantCoins = 20;

  final int coins;

  bool canAfford(int amount) => coins >= amount;

  Wallet earn(int amount) {
    if (amount < 0) {
      throw ArgumentError.value(amount, 'amount', 'must not be negative');
    }
    return Wallet(coins: coins + amount);
  }

  Wallet spend(int amount) {
    if (amount < 0) {
      throw ArgumentError.value(amount, 'amount', 'must not be negative');
    }
    if (!canAfford(amount)) {
      throw StateError('Cannot spend $amount coins from a balance of $coins');
    }
    return Wallet(coins: coins - amount);
  }

  /// e.g. '$20.00' — used for the beta credit line.
  String get creditLabel => '\$${coins.toStringAsFixed(2)}';
}
```

Create `lib/collect/models/xp_state.dart`:

```dart
/// Total experience. The level is always derived, never stored, so the two can
/// never disagree.
class XpState {
  const XpState({required this.totalXp});

  const XpState.empty() : totalXp = 0;

  static const int maxLevel = 50;

  final int totalXp;

  /// Cumulative XP required to reach [level].
  static int xpForLevel(int level) => 25 * level * (level - 1);

  static int levelForXp(int xp) {
    if (xp <= 0) {
      return 1;
    }
    var level = 1;
    while (level < maxLevel && xp >= xpForLevel(level + 1)) {
      level++;
    }
    return level;
  }

  int get level => levelForXp(totalXp);

  int get xpIntoLevel => totalXp - xpForLevel(level);

  /// The span of the current level, or 0 at the cap.
  int get xpForNextLevel =>
      level >= maxLevel ? 0 : xpForLevel(level + 1) - xpForLevel(level);

  double get levelProgress =>
      xpForNextLevel == 0 ? 1.0 : xpIntoLevel / xpForNextLevel;

  XpState gain(int amount) {
    if (amount < 0) {
      throw ArgumentError.value(amount, 'amount', 'must not be negative');
    }
    return XpState(totalXp: totalXp + amount);
  }
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/collect/`
Expected: PASS, 12 tests.

- [ ] **Step 5: Verify analysis is clean**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add lib/collect/models/wallet.dart lib/collect/models/xp_state.dart test/collect
git commit -m "feat(collect): add coin wallet with beta grant and XP level curve"
```

---

### Task 2: Skins And The Skin Catalog

**Files:**
- Create: `lib/collect/models/skin.dart`
- Create: `lib/collect/catalog/skin_catalog.dart`
- Test: `test/collect/skin_catalog_test.dart`

**Interfaces:**
- Consumes: `VizPalette`, `ColorSlot` from `lib/viz/rig/`; `VizCatalog` for the id cross-check in tests.
- Produces: `enum SkinRarity { common, uncommon, rare, legendary }`
- Produces: `class Skin { const Skin({required String id, required String label, required String rigId, required SkinRarity rarity, required VizPalette palette}); }`
- Produces: `class SkinCatalog { static List<Skin> get all; static Set<String> get defaultSkinIds; static List<Skin> get unlockable; static Skin byId(String id); static List<Skin> forRig(String rigId); static List<Skin> ofRarity(SkinRarity rarity); }`

- [ ] **Step 1: Write the failing skin catalog tests**

Create `test/collect/skin_catalog_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/collect/catalog/skin_catalog.dart';
import 'package:moneymoneymoney/collect/models/skin.dart';
import 'package:moneymoneymoney/viz/rig/color_slot.dart';
import 'package:moneymoneymoney/viz/viz_catalog.dart';

void main() {
  test('holds twenty skins with unique ids', () {
    expect(SkinCatalog.all.length, 20);
    final ids = SkinCatalog.all.map((s) => s.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('every skin names a rig that exists in the viz catalog', () {
    final rigIds = VizCatalog.all.map((r) => r.id).toSet();
    for (final skin in SkinCatalog.all) {
      expect(rigIds, contains(skin.rigId), reason: skin.id);
    }
  });

  test('every animal has one skin of each rarity plus a default', () {
    for (final rigId in ['fox', 'deer', 'hummingbird', 'raccoon']) {
      final skins = SkinCatalog.forRig(rigId);
      expect(skins.length, 5, reason: rigId);
      final unlockable = skins
          .where((s) => !SkinCatalog.defaultSkinIds.contains(s.id))
          .map((s) => s.rarity)
          .toSet();
      expect(unlockable, SkinRarity.values.toSet(), reason: rigId);
    }
  });

  test('the four defaults are excluded from the unlockable pool', () {
    expect(SkinCatalog.defaultSkinIds.length, 4);
    expect(SkinCatalog.unlockable.length, 16);
    for (final id in SkinCatalog.defaultSkinIds) {
      expect(SkinCatalog.unlockable.map((s) => s.id), isNot(contains(id)));
    }
  });

  test('every palette defines all six colour slots', () {
    for (final skin in SkinCatalog.all) {
      expect(skin.palette.colors.keys.toSet(), ColorSlot.values.toSet(),
          reason: skin.id);
    }
  });

  test('every palette id matches its skin id', () {
    for (final skin in SkinCatalog.all) {
      expect(skin.palette.id, skin.id);
    }
  });

  test('ofRarity buckets the unlockable pool evenly', () {
    for (final rarity in SkinRarity.values) {
      expect(SkinCatalog.ofRarity(rarity).length, 4, reason: rarity.name);
    }
  });

  test('byId throws for an unknown skin', () {
    expect(() => SkinCatalog.byId('nope'), throwsStateError);
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/collect/skin_catalog_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:moneymoneymoney/collect/models/skin.dart'`.

- [ ] **Step 3: Write the skin model**

Create `lib/collect/models/skin.dart`:

```dart
import '../../viz/rig/viz_palette.dart';

enum SkinRarity { common, uncommon, rare, legendary }

extension SkinRarityInfo on SkinRarity {
  String get label => switch (this) {
    SkinRarity.common => 'Common',
    SkinRarity.uncommon => 'Uncommon',
    SkinRarity.rare => 'Rare',
    SkinRarity.legendary => 'Legendary',
  };
}

/// A repaint of one rig. Skins carry no geometry — only a palette.
class Skin {
  const Skin({
    required this.id,
    required this.label,
    required this.rigId,
    required this.rarity,
    required this.palette,
  });

  final String id;
  final String label;

  /// The [VizRig.id] this skin repaints, e.g. 'fox'.
  final String rigId;

  final SkinRarity rarity;
  final VizPalette palette;
}
```

- [ ] **Step 4: Write the skin catalog**

Create `lib/collect/catalog/skin_catalog.dart`:

```dart
import 'dart:ui';

import '../../viz/rig/color_slot.dart';
import '../../viz/rig/viz_palette.dart';
import '../models/skin.dart';

VizPalette _palette(
  String id,
  String label, {
  required int primary,
  required int secondary,
  required int belly,
  required int accent,
  required int eye,
  required int outline,
}) => VizPalette(
  id: id,
  label: label,
  colors: {
    ColorSlot.primary: Color(primary),
    ColorSlot.secondary: Color(secondary),
    ColorSlot.belly: Color(belly),
    ColorSlot.accent: Color(accent),
    ColorSlot.eye: Color(eye),
    ColorSlot.outline: Color(outline),
  },
);

Skin _skin(
  String id,
  String label,
  String rigId,
  SkinRarity rarity, {
  required int primary,
  required int secondary,
  required int belly,
  required int accent,
  required int eye,
  required int outline,
}) => Skin(
  id: id,
  label: label,
  rigId: rigId,
  rarity: rarity,
  palette: _palette(
    id,
    label,
    primary: primary,
    secondary: secondary,
    belly: belly,
    accent: accent,
    eye: eye,
    outline: outline,
  ),
);

/// Every skin in the game. Five per animal: the default, plus one of each
/// rarity. The defaults are owned from the start and never drop from eggs.
class SkinCatalog {
  const SkinCatalog._();

  static final List<Skin> all = List<Skin>.unmodifiable(<Skin>[
    // Fox
    _skin('fox_default', 'Fox', 'fox', SkinRarity.common,
        primary: 0xffd96a2e, secondary: 0xffb04f20, belly: 0xfff5e9d8,
        accent: 0xfff2a65a, eye: 0xff2a2320, outline: 0xff2a2320),
    _skin('fox_ash', 'Ash Fox', 'fox', SkinRarity.common,
        primary: 0xff8f8478, secondary: 0xff6d635a, belly: 0xffe8e2d8,
        accent: 0xffb3a698, eye: 0xff2a2320, outline: 0xff32302c),
    _skin('fox_arctic', 'Arctic Fox', 'fox', SkinRarity.uncommon,
        primary: 0xffe9eef2, secondary: 0xffbfcbd6, belly: 0xfffbfdff,
        accent: 0xff9fb8cc, eye: 0xff2a3742, outline: 0xff6d8091),
    _skin('fox_ember', 'Ember Fox', 'fox', SkinRarity.rare,
        primary: 0xffd93b1f, secondary: 0xff8f1f0e, belly: 0xffffd9a3,
        accent: 0xffffa03c, eye: 0xff2a1410, outline: 0xff4a140a),
    _skin('fox_spirit', 'Spirit Fox', 'fox', SkinRarity.legendary,
        primary: 0xff7f6bd6, secondary: 0xff5a45ad, belly: 0xffeae4ff,
        accent: 0xff9be6ff, eye: 0xfff2f7ff, outline: 0xff33245e),
    // Deer
    _skin('deer_default', 'Deer', 'deer', SkinRarity.common,
        primary: 0xffb8814f, secondary: 0xff8f5f38, belly: 0xfff1e2cd,
        accent: 0xffd9b98a, eye: 0xff2a2320, outline: 0xff3a2d22),
    _skin('deer_fawn', 'Fawn', 'deer', SkinRarity.common,
        primary: 0xffd4a874, secondary: 0xffab8154, belly: 0xfffaf0e0,
        accent: 0xffe8cfa6, eye: 0xff2a2320, outline: 0xff4a3826),
    _skin('deer_dusk', 'Dusk Deer', 'deer', SkinRarity.uncommon,
        primary: 0xff6f6486, secondary: 0xff4e4562, belly: 0xffd9d2e6,
        accent: 0xffa596c4, eye: 0xff1e1a26, outline: 0xff2e2740),
    _skin('deer_jade', 'Jade Deer', 'deer', SkinRarity.rare,
        primary: 0xff3f8f74, secondary: 0xff2a6a55, belly: 0xffdff2e8,
        accent: 0xff8fd6bb, eye: 0xff16241f, outline: 0xff1d4437),
    _skin('deer_aurora', 'Aurora Deer', 'deer', SkinRarity.legendary,
        primary: 0xff2fa4a0, secondary: 0xff1f6f8f, belly: 0xffe4fbff,
        accent: 0xffb56fd6, eye: 0xfff2feff, outline: 0xff173c4d),
    // Hummingbird
    _skin('hummingbird_default', 'Hummingbird', 'hummingbird',
        SkinRarity.common,
        primary: 0xff2f9e7a, secondary: 0xff1f7a5e, belly: 0xfff3efe3,
        accent: 0xffd94f5c, eye: 0xff20201e, outline: 0xff2a2320),
    _skin('hummingbird_sage', 'Sage Hummer', 'hummingbird', SkinRarity.common,
        primary: 0xff8fa682, secondary: 0xff6d8462, belly: 0xfff2f3e8,
        accent: 0xffc4a86f, eye: 0xff20201e, outline: 0xff37402f),
    _skin('hummingbird_ruby', 'Ruby Hummer', 'hummingbird',
        SkinRarity.uncommon,
        primary: 0xffb52a45, secondary: 0xff8a1a31, belly: 0xfffbe8ec,
        accent: 0xffff7a92, eye: 0xff2a1017, outline: 0xff4d0f1e),
    _skin('hummingbird_emerald', 'Emerald Hummer', 'hummingbird',
        SkinRarity.rare,
        primary: 0xff139c5e, secondary: 0xff0b6f43, belly: 0xffe3fbee,
        accent: 0xffffd24a, eye: 0xff0f2419, outline: 0xff0a4a2d),
    _skin('hummingbird_prism', 'Prism Hummer', 'hummingbird',
        SkinRarity.legendary,
        primary: 0xff4fb8ff, secondary: 0xffb56fd6, belly: 0xfffff4ff,
        accent: 0xffffd166, eye: 0xff1a1030, outline: 0xff3a2a6b),
    // Raccoon
    _skin('raccoon_default', 'Raccoon', 'raccoon', SkinRarity.common,
        primary: 0xff8d8f96, secondary: 0xff6d6f77, belly: 0xffe6e3da,
        accent: 0xffb9bcc4, eye: 0xfff2efe6, outline: 0xff2f3136),
    _skin('raccoon_dusk', 'Dusk Bandit', 'raccoon', SkinRarity.common,
        primary: 0xff6c6f7d, secondary: 0xff51535e, belly: 0xffd6d4cc,
        accent: 0xff9294a1, eye: 0xffeeece2, outline: 0xff26272c),
    _skin('raccoon_frost', 'Frost Bandit', 'raccoon', SkinRarity.uncommon,
        primary: 0xffc8d6e0, secondary: 0xff9fb1bf, belly: 0xfff7fbff,
        accent: 0xffe1ecf5, eye: 0xff2a3742, outline: 0xff44586a),
    _skin('raccoon_gilded', 'Gilded Bandit', 'raccoon', SkinRarity.rare,
        primary: 0xffc9a13c, secondary: 0xff9c7c2e, belly: 0xfffdf1cf,
        accent: 0xffe8c96a, eye: 0xff2a2214, outline: 0xff5c4715),
    _skin('raccoon_shadow', 'Shadow Bandit', 'raccoon', SkinRarity.legendary,
        primary: 0xff3a3d48, secondary: 0xff24262e, belly: 0xff6b7080,
        accent: 0xff7c5cff, eye: 0xffc9b8ff, outline: 0xff141519),
  ]);

  static const Set<String> defaultSkinIds = {
    'fox_default',
    'deer_default',
    'hummingbird_default',
    'raccoon_default',
  };

  static List<Skin> get unlockable =>
      all.where((s) => !defaultSkinIds.contains(s.id)).toList();

  static Skin byId(String id) => all.firstWhere((s) => s.id == id);

  static List<Skin> forRig(String rigId) =>
      all.where((s) => s.rigId == rigId).toList();

  /// Buckets the *unlockable* pool — defaults never drop from eggs.
  static List<Skin> ofRarity(SkinRarity rarity) =>
      unlockable.where((s) => s.rarity == rarity).toList();
}
```

- [ ] **Step 5: Run the tests to verify they pass**

Run: `flutter test test/collect/`
Expected: PASS.

Note: the `'every animal has one skin of each rarity plus a default'` test
requires each animal's five skins to cover all four rarities among the four
non-default entries, which the data above satisfies.

- [ ] **Step 6: Verify analysis is clean**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 7: Commit**

```bash
git add lib/collect/models/skin.dart lib/collect/catalog/skin_catalog.dart test/collect/skin_catalog_test.dart
git commit -m "feat(collect): add skin model and the twenty-skin catalog"
```

---

### Task 3: Eggs And Hatching

**Files:**
- Create: `lib/collect/models/egg.dart`
- Create: `lib/collect/catalog/egg_catalog.dart`
- Create: `lib/collect/services/egg_service.dart`
- Test: `test/collect/egg_service_test.dart`

**Interfaces:**
- Consumes: `Skin`, `SkinRarity`, `SkinCatalog`.
- Produces: `enum EggKind { common, rare, golden }`
- Produces: `class EggDef { const EggDef({required EggKind kind, required String label, required int priceCoins, required Map<SkinRarity, int> weights}); }`
- Produces: `class HatchResult { const HatchResult({required Skin skin, required bool duplicate, required int coinsRefunded}); }`
- Produces: `class EggCatalog { static List<EggDef> get all; static EggDef byKind(EggKind kind); static int duplicateRefund(SkinRarity rarity); }`
- Produces: `class EggService { const EggService(); HatchResult hatch({required EggKind kind, required Set<String> ownedSkinIds, required Random random}); }`

- [ ] **Step 1: Write the failing egg tests**

Create `test/collect/egg_service_test.dart`:

```dart
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/collect/catalog/egg_catalog.dart';
import 'package:moneymoneymoney/collect/catalog/skin_catalog.dart';
import 'package:moneymoneymoney/collect/models/egg.dart';
import 'package:moneymoneymoney/collect/models/skin.dart';
import 'package:moneymoneymoney/collect/services/egg_service.dart';

void main() {
  const service = EggService();

  test('the catalog publishes the three tiers at the spec prices', () {
    expect(EggCatalog.all.length, 3);
    expect(EggCatalog.byKind(EggKind.common).priceCoins, 5);
    expect(EggCatalog.byKind(EggKind.rare).priceCoins, 12);
    expect(EggCatalog.byKind(EggKind.golden).priceCoins, 25);
  });

  test('every egg has a positive total weight', () {
    for (final egg in EggCatalog.all) {
      expect(egg.weights.values.fold(0, (a, b) => a + b), greaterThan(0));
    }
  });

  test('the common egg can never drop a legendary', () {
    expect(EggCatalog.byKind(EggKind.common).weights[SkinRarity.legendary], 0);
  });

  test('the golden egg can never drop a common', () {
    expect(EggCatalog.byKind(EggKind.golden).weights[SkinRarity.common], 0);
  });

  test('duplicate refunds scale with rarity', () {
    expect(EggCatalog.duplicateRefund(SkinRarity.common), 2);
    expect(EggCatalog.duplicateRefund(SkinRarity.uncommon), 4);
    expect(EggCatalog.duplicateRefund(SkinRarity.rare), 8);
    expect(EggCatalog.duplicateRefund(SkinRarity.legendary), 15);
  });

  test('hatching is reproducible for a fixed seed', () {
    final a = service.hatch(
      kind: EggKind.rare,
      ownedSkinIds: SkinCatalog.defaultSkinIds,
      random: Random(1234),
    );
    final b = service.hatch(
      kind: EggKind.rare,
      ownedSkinIds: SkinCatalog.defaultSkinIds,
      random: Random(1234),
    );
    expect(a.skin.id, b.skin.id);
  });

  test('a fresh player never gets a duplicate', () {
    for (var seed = 0; seed < 50; seed++) {
      final result = service.hatch(
        kind: EggKind.common,
        ownedSkinIds: SkinCatalog.defaultSkinIds,
        random: Random(seed),
      );
      expect(result.duplicate, isFalse, reason: 'seed $seed');
      expect(result.coinsRefunded, 0);
      expect(SkinCatalog.defaultSkinIds, isNot(contains(result.skin.id)));
    }
  });

  test('an exhausted pool returns a duplicate with the rarity refund', () {
    final everything = SkinCatalog.all.map((s) => s.id).toSet();
    final result = service.hatch(
      kind: EggKind.golden,
      ownedSkinIds: everything,
      random: Random(7),
    );
    expect(result.duplicate, isTrue);
    expect(result.coinsRefunded, EggCatalog.duplicateRefund(result.skin.rarity));
  });

  test('a rarity with nothing left steps down instead of failing', () {
    // Own every legendary and rare, so a golden egg must fall to uncommon.
    final owned = {
      ...SkinCatalog.defaultSkinIds,
      ...SkinCatalog.ofRarity(SkinRarity.legendary).map((s) => s.id),
      ...SkinCatalog.ofRarity(SkinRarity.rare).map((s) => s.id),
    };
    for (var seed = 0; seed < 30; seed++) {
      final result = service.hatch(
        kind: EggKind.golden,
        ownedSkinIds: owned,
        random: Random(seed),
      );
      expect(result.duplicate, isFalse, reason: 'seed $seed');
      expect(result.skin.rarity, SkinRarity.uncommon, reason: 'seed $seed');
    }
  });

  test('drops respect the egg weights over many rolls', () {
    var commons = 0;
    for (var seed = 0; seed < 400; seed++) {
      final result = service.hatch(
        kind: EggKind.common,
        ownedSkinIds: SkinCatalog.defaultSkinIds,
        random: Random(seed),
      );
      if (result.skin.rarity == SkinRarity.common) {
        commons++;
      }
    }
    // Weighted 70/100 for commons; allow wide slack for sampling noise.
    expect(commons, greaterThan(220));
    expect(commons, lessThan(340));
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/collect/egg_service_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:moneymoneymoney/collect/models/egg.dart'`.

- [ ] **Step 3: Write the egg model and catalog**

Create `lib/collect/models/egg.dart`:

```dart
import 'skin.dart';

enum EggKind { common, rare, golden }

/// One lootbox tier: a price and a set of relative rarity weights.
class EggDef {
  const EggDef({
    required this.kind,
    required this.label,
    required this.priceCoins,
    required this.weights,
  });

  final EggKind kind;
  final String label;
  final int priceCoins;

  /// Relative weights, not percentages.
  final Map<SkinRarity, int> weights;
}

class HatchResult {
  const HatchResult({
    required this.skin,
    required this.duplicate,
    required this.coinsRefunded,
  });

  final Skin skin;

  /// True when the player already owned [skin]; no new skin is granted.
  final bool duplicate;

  /// Coins handed back in place of a duplicate skin; 0 otherwise.
  final int coinsRefunded;
}
```

Create `lib/collect/catalog/egg_catalog.dart`:

```dart
import '../models/egg.dart';
import '../models/skin.dart';

class EggCatalog {
  const EggCatalog._();

  static final List<EggDef> all = List<EggDef>.unmodifiable(<EggDef>[
    const EggDef(
      kind: EggKind.common,
      label: 'Common Egg',
      priceCoins: 5,
      weights: {
        SkinRarity.common: 70,
        SkinRarity.uncommon: 25,
        SkinRarity.rare: 5,
        SkinRarity.legendary: 0,
      },
    ),
    const EggDef(
      kind: EggKind.rare,
      label: 'Rare Egg',
      priceCoins: 12,
      weights: {
        SkinRarity.common: 30,
        SkinRarity.uncommon: 45,
        SkinRarity.rare: 22,
        SkinRarity.legendary: 3,
      },
    ),
    const EggDef(
      kind: EggKind.golden,
      label: 'Golden Egg',
      priceCoins: 25,
      weights: {
        SkinRarity.common: 0,
        SkinRarity.uncommon: 40,
        SkinRarity.rare: 45,
        SkinRarity.legendary: 15,
      },
    ),
  ]);

  static EggDef byKind(EggKind kind) => all.firstWhere((e) => e.kind == kind);

  static int duplicateRefund(SkinRarity rarity) => switch (rarity) {
    SkinRarity.common => 2,
    SkinRarity.uncommon => 4,
    SkinRarity.rare => 8,
    SkinRarity.legendary => 15,
  };
}
```

- [ ] **Step 4: Write the egg service**

Create `lib/collect/services/egg_service.dart`:

```dart
import 'dart:math';

import '../catalog/egg_catalog.dart';
import '../catalog/skin_catalog.dart';
import '../models/egg.dart';
import '../models/skin.dart';

/// Opens lootbox eggs. Randomness is always injected so hatching is
/// reproducible under test.
class EggService {
  const EggService();

  HatchResult hatch({
    required EggKind kind,
    required Set<String> ownedSkinIds,
    required Random random,
  }) {
    final egg = EggCatalog.byKind(kind);
    final rolled = _rollRarity(egg, random);

    // Step down through the rarities looking for something unowned.
    for (var index = rolled.index; index >= 0; index--) {
      final rarity = SkinRarity.values[index];
      final available = SkinCatalog.ofRarity(
        rarity,
      ).where((s) => !ownedSkinIds.contains(s.id)).toList();
      if (available.isNotEmpty) {
        return HatchResult(
          skin: available[random.nextInt(available.length)],
          duplicate: false,
          coinsRefunded: 0,
        );
      }
    }

    // Everything at or below the rolled rarity is owned: return a duplicate.
    final pool = SkinCatalog.ofRarity(rolled).isEmpty
        ? SkinCatalog.unlockable
        : SkinCatalog.ofRarity(rolled);
    final skin = pool[random.nextInt(pool.length)];
    return HatchResult(
      skin: skin,
      duplicate: true,
      coinsRefunded: EggCatalog.duplicateRefund(skin.rarity),
    );
  }

  SkinRarity _rollRarity(EggDef egg, Random random) {
    final total = egg.weights.values.fold(0, (sum, w) => sum + w);
    var roll = random.nextInt(total);
    for (final rarity in SkinRarity.values) {
      final weight = egg.weights[rarity] ?? 0;
      if (roll < weight) {
        return rarity;
      }
      roll -= weight;
    }
    return SkinRarity.common;
  }
}
```

- [ ] **Step 5: Run the tests to verify they pass**

Run: `flutter test test/collect/`
Expected: PASS.

If the `'drops respect the egg weights over many rolls'` bounds fail, do not
widen them without checking `_rollRarity` first — a bug there shows up exactly
as a skewed count.

- [ ] **Step 6: Verify analysis is clean**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 7: Commit**

```bash
git add lib/collect/models/egg.dart lib/collect/catalog/egg_catalog.dart lib/collect/services/egg_service.dart test/collect/egg_service_test.dart
git commit -m "feat(collect): add lootbox eggs with weighted drops and duplicate refunds"
```

---

### Task 4: Player State, Economy And Skin Services

**Files:**
- Create: `lib/collect/models/player_state.dart`
- Create: `lib/collect/services/economy_service.dart`
- Create: `lib/collect/services/skin_service.dart`
- Test: `test/collect/economy_service_test.dart`
- Test: `test/collect/skin_service_test.dart`

**Interfaces:**
- Consumes: `Wallet`, `XpState`, `Skin`, `SkinCatalog`, `HatchResult`, `EggCatalog`, `ForestDay`, `TreeStatus` (from `lib/models/forest_day.dart`), `VizRig`, `VizPalette`.
- Produces: `class PlayerState { const PlayerState({required Wallet wallet, required XpState xp, required Set<String> ownedSkinIds, required Map<String, String> equippedSkinIds, required bool betaGrantClaimed}); factory PlayerState.beta(); PlayerState copyWith({Wallet? wallet, XpState? xp, Set<String>? ownedSkinIds, Map<String, String>? equippedSkinIds, bool? betaGrantClaimed}); }`
- Produces: `class EconomyRules` with `static const int xpHealthyDay = 10, xpWitheredDay = 2, xpStreakBonusPerDay = 2, xpStreakBonusCap = 20, coinsHealthyDay = 3, coinsBudgetGuardianBonus = 2;` and `static const double budgetGuardianThreshold = 0.8;`
- Produces: `class DayReward { const DayReward({required int xp, required int coins, required int streakBonusXp, required int budgetGuardianBonusCoins}); }`
- Produces: `class EconomyService { const EconomyService(); DayReward rewardFor({required ForestDay day, required int streak}); PlayerState apply(PlayerState state, DayReward reward); }`
- Produces: `class SkinService { const SkinService(); PlayerState applyHatch(PlayerState state, HatchResult result); PlayerState equip(PlayerState state, Skin skin); VizPalette paletteFor(PlayerState state, VizRig rig); }`

- [ ] **Step 1: Write the failing economy and skin service tests**

Create `test/collect/economy_service_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/collect/models/player_state.dart';
import 'package:moneymoneymoney/collect/services/economy_service.dart';
import 'package:moneymoneymoney/models/forest_day.dart';

void main() {
  const service = EconomyService();

  ForestDay day({
    required TreeStatus status,
    double spending = 50,
    double dailyBudget = 100,
  }) => ForestDay(
    date: DateTime(2026, 8, 29),
    status: status,
    treeLevel: status == TreeStatus.healthy ? 1 : 0,
    spending: spending,
    dailyBudget: dailyBudget,
    actionCompleted: status == TreeStatus.healthy,
    message: 'test',
  );

  test('a beta player starts with 20 coins, no XP, and four skins', () {
    final player = PlayerState.beta();
    expect(player.wallet.coins, 20);
    expect(player.xp.totalXp, 0);
    expect(player.ownedSkinIds.length, 4);
    expect(player.equippedSkinIds['fox'], 'fox_default');
    expect(player.betaGrantClaimed, isTrue);
  });

  test('a healthy day at streak 1 awards 10 XP and 3 coins', () {
    final reward = service.rewardFor(
      day: day(status: TreeStatus.healthy, spending: 95),
      streak: 1,
    );
    expect(reward.xp, 10);
    expect(reward.coins, 3);
    expect(reward.streakBonusXp, 0);
    expect(reward.budgetGuardianBonusCoins, 0);
  });

  test('a withered day awards 2 XP and no coins', () {
    final reward = service.rewardFor(
      day: day(status: TreeStatus.withered, spending: 300),
      streak: 0,
    );
    expect(reward.xp, 2);
    expect(reward.coins, 0);
    expect(reward.streakBonusXp, 0);
  });

  test('the streak bonus scales at 2 XP per day and caps at 20', () {
    expect(
      service.rewardFor(day: day(status: TreeStatus.healthy, spending: 95),
          streak: 4).streakBonusXp,
      6,
    );
    expect(
      service.rewardFor(day: day(status: TreeStatus.healthy, spending: 95),
          streak: 40).streakBonusXp,
      20,
    );
  });

  test('Budget Guardian pays below 80 percent of budget but not at it', () {
    expect(
      service.rewardFor(
        day: day(status: TreeStatus.healthy, spending: 79, dailyBudget: 100),
        streak: 1,
      ).budgetGuardianBonusCoins,
      2,
    );
    expect(
      service.rewardFor(
        day: day(status: TreeStatus.healthy, spending: 80, dailyBudget: 100),
        streak: 1,
      ).budgetGuardianBonusCoins,
      0,
    );
  });

  test('Budget Guardian never pays on a zero budget', () {
    expect(
      service.rewardFor(
        day: day(status: TreeStatus.healthy, spending: 0, dailyBudget: 0),
        streak: 1,
      ).budgetGuardianBonusCoins,
      0,
    );
  });

  test('applying a reward moves the wallet and XP together', () {
    final player = service.apply(
      PlayerState.beta(),
      service.rewardFor(
        day: day(status: TreeStatus.healthy, spending: 10, dailyBudget: 100),
        streak: 3,
      ),
    );
    // 10 base + 4 streak bonus XP; 3 base + 2 guardian coins.
    expect(player.xp.totalXp, 14);
    expect(player.wallet.coins, 25);
  });
}
```

Create `test/collect/skin_service_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/collect/catalog/egg_catalog.dart';
import 'package:moneymoneymoney/collect/catalog/skin_catalog.dart';
import 'package:moneymoneymoney/collect/models/egg.dart';
import 'package:moneymoneymoney/collect/models/player_state.dart';
import 'package:moneymoneymoney/collect/models/skin.dart';
import 'package:moneymoneymoney/collect/services/skin_service.dart';
import 'package:moneymoneymoney/viz/animals/fox.dart';

void main() {
  const service = SkinService();

  test('a new skin is added to the owned set', () {
    final skin = SkinCatalog.byId('fox_ember');
    final player = service.applyHatch(
      PlayerState.beta(),
      HatchResult(skin: skin, duplicate: false, coinsRefunded: 0),
    );
    expect(player.ownedSkinIds, contains('fox_ember'));
    expect(player.wallet.coins, 20);
  });

  test('a duplicate pays coins instead of granting the skin', () {
    final skin = SkinCatalog.byId('fox_ember');
    final player = service.applyHatch(
      PlayerState.beta(),
      HatchResult(
        skin: skin,
        duplicate: true,
        coinsRefunded: EggCatalog.duplicateRefund(SkinRarity.rare),
      ),
    );
    expect(player.ownedSkinIds, isNot(contains('fox_ember')));
    expect(player.wallet.coins, 28);
  });

  test('equipping an owned skin replaces the one for that rig', () {
    final skin = SkinCatalog.byId('fox_arctic');
    var player = service.applyHatch(
      PlayerState.beta(),
      HatchResult(skin: skin, duplicate: false, coinsRefunded: 0),
    );
    player = service.equip(player, skin);
    expect(player.equippedSkinIds['fox'], 'fox_arctic');
    expect(player.equippedSkinIds['deer'], 'deer_default');
  });

  test('equipping an unowned skin throws', () {
    expect(
      () => service.equip(PlayerState.beta(), SkinCatalog.byId('fox_spirit')),
      throwsStateError,
    );
  });

  test('paletteFor returns the equipped skin palette', () {
    final skin = SkinCatalog.byId('fox_arctic');
    var player = service.applyHatch(
      PlayerState.beta(),
      HatchResult(skin: skin, duplicate: false, coinsRefunded: 0),
    );
    player = service.equip(player, skin);
    expect(service.paletteFor(player, Fox()).id, 'fox_arctic');
  });

  test('the default skin is equipped from the start', () {
    expect(
      service.paletteFor(PlayerState.beta(), Fox()).id,
      'fox_default',
    );
  });

  test('paletteFor falls back to the rig default when nothing is equipped', () {
    final bare = PlayerState.beta().copyWith(equippedSkinIds: const {});
    expect(service.paletteFor(bare, Fox()).id, 'fox_default');
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/collect/`
Expected: FAIL — `Target of URI doesn't exist: 'package:moneymoneymoney/collect/models/player_state.dart'`.

- [ ] **Step 3: Write the player state**

Create `lib/collect/models/player_state.dart`:

```dart
import '../catalog/skin_catalog.dart';
import 'wallet.dart';
import 'xp_state.dart';

/// Everything the reward economy knows about one player. Immutable; held in
/// memory by MyApp for the session.
class PlayerState {
  const PlayerState({
    required this.wallet,
    required this.xp,
    required this.ownedSkinIds,
    required this.equippedSkinIds,
    required this.betaGrantClaimed,
  });

  /// A fresh beta player: the 20 coin grant, no XP, the four default skins
  /// owned and equipped.
  factory PlayerState.beta() => PlayerState(
    wallet: const Wallet.beta(),
    xp: const XpState.empty(),
    ownedSkinIds: Set<String>.unmodifiable(SkinCatalog.defaultSkinIds),
    equippedSkinIds: Map<String, String>.unmodifiable({
      for (final id in SkinCatalog.defaultSkinIds)
        SkinCatalog.byId(id).rigId: id,
    }),
    betaGrantClaimed: true,
  );

  final Wallet wallet;
  final XpState xp;
  final Set<String> ownedSkinIds;

  /// rigId -> skinId.
  final Map<String, String> equippedSkinIds;

  final bool betaGrantClaimed;

  PlayerState copyWith({
    Wallet? wallet,
    XpState? xp,
    Set<String>? ownedSkinIds,
    Map<String, String>? equippedSkinIds,
    bool? betaGrantClaimed,
  }) => PlayerState(
    wallet: wallet ?? this.wallet,
    xp: xp ?? this.xp,
    ownedSkinIds: ownedSkinIds ?? this.ownedSkinIds,
    equippedSkinIds: equippedSkinIds ?? this.equippedSkinIds,
    betaGrantClaimed: betaGrantClaimed ?? this.betaGrantClaimed,
  );
}
```

- [ ] **Step 4: Write the economy service**

Create `lib/collect/services/economy_service.dart`:

```dart
import 'dart:math' as math;

import '../../models/forest_day.dart';
import '../models/player_state.dart';

/// Every tunable number in the reward economy, in one place.
class EconomyRules {
  const EconomyRules._();

  static const int xpHealthyDay = 10;
  static const int xpWitheredDay = 2;
  static const int xpStreakBonusPerDay = 2;
  static const int xpStreakBonusCap = 20;
  static const int coinsHealthyDay = 3;
  static const int coinsBudgetGuardianBonus = 2;
  static const double budgetGuardianThreshold = 0.8;
}

/// What one check-in earned, broken out so the UI can explain it.
class DayReward {
  const DayReward({
    required this.xp,
    required this.coins,
    required this.streakBonusXp,
    required this.budgetGuardianBonusCoins,
  });

  /// Total XP, including [streakBonusXp].
  final int xp;

  /// Total coins, including [budgetGuardianBonusCoins].
  final int coins;

  final int streakBonusXp;
  final int budgetGuardianBonusCoins;
}

/// Turns a ForestEngine day into XP and coins. ForestEngine is not modified;
/// this only reads its output.
class EconomyService {
  const EconomyService();

  DayReward rewardFor({required ForestDay day, required int streak}) {
    if (day.status != TreeStatus.healthy) {
      return const DayReward(
        xp: EconomyRules.xpWitheredDay,
        coins: 0,
        streakBonusXp: 0,
        budgetGuardianBonusCoins: 0,
      );
    }

    final streakBonus = math.min(
      EconomyRules.xpStreakBonusCap,
      EconomyRules.xpStreakBonusPerDay * math.max(0, streak - 1),
    );
    final guardian =
        day.dailyBudget > 0 &&
            day.spending < EconomyRules.budgetGuardianThreshold * day.dailyBudget
        ? EconomyRules.coinsBudgetGuardianBonus
        : 0;

    return DayReward(
      xp: EconomyRules.xpHealthyDay + streakBonus,
      coins: EconomyRules.coinsHealthyDay + guardian,
      streakBonusXp: streakBonus,
      budgetGuardianBonusCoins: guardian,
    );
  }

  PlayerState apply(PlayerState state, DayReward reward) => state.copyWith(
    wallet: state.wallet.earn(reward.coins),
    xp: state.xp.gain(reward.xp),
  );
}
```

- [ ] **Step 5: Write the skin service**

Create `lib/collect/services/skin_service.dart`:

```dart
import '../../viz/rig/viz_palette.dart';
import '../../viz/rig/viz_rig.dart';
import '../catalog/skin_catalog.dart';
import '../models/egg.dart';
import '../models/player_state.dart';
import '../models/skin.dart';

/// Ownership, equipping, and resolving which palette a rig should be drawn
/// with. This is the only place lib/collect reaches into lib/viz.
class SkinService {
  const SkinService();

  /// Grants the hatched skin, or pays the duplicate refund instead.
  PlayerState applyHatch(PlayerState state, HatchResult result) {
    if (result.duplicate) {
      return state.copyWith(
        wallet: state.wallet.earn(result.coinsRefunded),
      );
    }
    return state.copyWith(
      ownedSkinIds: Set<String>.unmodifiable({
        ...state.ownedSkinIds,
        result.skin.id,
      }),
    );
  }

  PlayerState equip(PlayerState state, Skin skin) {
    if (!state.ownedSkinIds.contains(skin.id)) {
      throw StateError('Cannot equip unowned skin ${skin.id}');
    }
    return state.copyWith(
      equippedSkinIds: Map<String, String>.unmodifiable({
        ...state.equippedSkinIds,
        skin.rigId: skin.id,
      }),
    );
  }

  /// The palette [rig] should be drawn with, falling back to the rig's own
  /// default when nothing is equipped for it.
  VizPalette paletteFor(PlayerState state, VizRig rig) {
    final skinId = state.equippedSkinIds[rig.id];
    if (skinId == null) {
      return rig.defaultPalette;
    }
    return SkinCatalog.byId(skinId).palette;
  }
}
```

- [ ] **Step 6: Run the tests to verify they pass**

Run: `flutter test test/collect/`
Expected: PASS.

- [ ] **Step 7: Verify analysis is clean**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 8: Commit**

```bash
git add lib/collect/models/player_state.dart lib/collect/services test/collect
git commit -m "feat(collect): add player state, day rewards and skin ownership"
```

---

### Task 5: Coin And XP Orb Viz Objects

**Files:**
- Create: `lib/viz/collectables/coin_viz.dart`
- Create: `lib/viz/collectables/xp_orb_viz.dart`
- Modify: `lib/viz/viz_catalog.dart`
- Test: `test/viz/coin_viz_test.dart`
- Test: `test/viz/xp_orb_viz_test.dart`

**Interfaces:**
- Consumes: `VizRig`, `RigPart`, `PartPose`, `Pose`, `ColorSlot`, `VizPalette`, `VizClip`, `ovalPath`, `capsulePath`, `trianglePath`.
- Produces: `class CoinViz extends VizRig` with `id == 'coin'`, canvas `Size(120, 120)`, part ids `disc`, `inner`, `glyph`, `shine`.
- Produces: `class XpOrbViz extends VizRig` with `id == 'xp_orb'`, canvas `Size(120, 120)`, part ids `halo`, `core`, `mote0`, `mote1`, `mote2`.
- Produces: `const VizPalette coinDefaultPalette`, `const VizPalette xpOrbDefaultPalette`.

**Art notes:** the coin spins by driving `disc.scaleX` with a cosine, which
passes through zero and reads as edge-on. Its children inherit that squash for
free. The XP orb's motes orbit on offsets, not rotations.

- [ ] **Step 1: Write the failing collectable viz tests**

Create `test/viz/coin_viz_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/viz/collectables/coin_viz.dart';
import 'package:moneymoneymoney/viz/rig/viz_clip.dart';
import 'package:moneymoneymoney/viz/rig/viz_rig.dart';
import 'package:moneymoneymoney/viz/viz_catalog.dart';

void main() {
  final coin = CoinViz();

  test('declares a stable identity and all three clips', () {
    expect(coin.id, 'coin');
    expect(coin.displayName, 'Coin');
    expect(coin.supportedClips, VizClip.values.toSet());
  });

  test('every part has a unique z and a resolvable parent', () {
    final zs = coin.parts.map((p) => p.z).toList();
    expect(zs.toSet().length, zs.length);
    final ids = coin.parts.map((p) => p.id).toSet();
    for (final part in coin.parts) {
      if (part.parent != null) {
        expect(ids, contains(part.parent), reason: part.id);
      }
    }
  });

  test('the face detail rides on the disc', () {
    final byId = {for (final p in coin.parts) p.id: p};
    expect(byId['inner']!.parent, 'disc');
    expect(byId['glyph']!.parent, 'disc');
  });

  test('every clip loops', () {
    for (final clip in coin.supportedClips) {
      final start = coin.poseAt(clip, 0);
      final end = coin.poseAt(clip, 0.9999);
      for (final id in start.keys) {
        expect(end[id]!.scaleX, closeTo(start[id]!.scaleX, 0.02),
            reason: '$clip / $id');
        expect(end[id]!.offset.dy, closeTo(start[id]!.offset.dy, 0.05),
            reason: '$clip / $id');
      }
    }
  });

  test('the spin drives the disc through edge-on', () {
    var minScale = 1.0;
    for (var i = 0; i < 200; i++) {
      final scale = coin.poseAt(VizClip.walk, i / 200)['disc']!.scaleX.abs();
      minScale = scale < minScale ? scale : minScale;
    }
    expect(minScale, lessThan(0.1));
  });

  test('is registered in the catalog', () {
    expect(VizCatalog.byId('coin'), isA<VizRig>());
  });
}
```

Create `test/viz/xp_orb_viz_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/viz/collectables/xp_orb_viz.dart';
import 'package:moneymoneymoney/viz/rig/viz_clip.dart';
import 'package:moneymoneymoney/viz/rig/viz_rig.dart';
import 'package:moneymoneymoney/viz/viz_catalog.dart';

void main() {
  final orb = XpOrbViz();

  test('declares a stable identity and all three clips', () {
    expect(orb.id, 'xp_orb');
    expect(orb.displayName, 'XP Orb');
    expect(orb.supportedClips, VizClip.values.toSet());
  });

  test('every part has a unique z and a resolvable parent', () {
    final zs = orb.parts.map((p) => p.z).toList();
    expect(zs.toSet().length, zs.length);
    final ids = orb.parts.map((p) => p.id).toSet();
    for (final part in orb.parts) {
      if (part.parent != null) {
        expect(ids, contains(part.parent), reason: part.id);
      }
    }
  });

  test('has three motes', () {
    expect(orb.parts.where((p) => p.id.startsWith('mote')).length, 3);
  });

  test('every clip loops', () {
    for (final clip in orb.supportedClips) {
      final start = orb.poseAt(clip, 0);
      final end = orb.poseAt(clip, 0.9999);
      for (final id in start.keys) {
        expect(end[id]!.offset.dx, closeTo(start[id]!.offset.dx, 0.05),
            reason: '$clip / $id');
        expect(end[id]!.offset.dy, closeTo(start[id]!.offset.dy, 0.05),
            reason: '$clip / $id');
      }
    }
  });

  test('the motes orbit on offsets and stay evenly spread', () {
    final pose = orb.poseAt(VizClip.walk, 0.1);
    final offsets = [
      pose['mote0']!.offset,
      pose['mote1']!.offset,
      pose['mote2']!.offset,
    ];
    expect(offsets.toSet().length, 3);
    for (final offset in offsets) {
      expect(offset.distance, closeTo(offsets.first.distance, 0.001));
    }
  });

  test('is registered in the catalog', () {
    expect(VizCatalog.byId('xp_orb'), isA<VizRig>());
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/viz/coin_viz_test.dart test/viz/xp_orb_viz_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:moneymoneymoney/viz/collectables/coin_viz.dart'`.

- [ ] **Step 3: Write the coin gameobject**

Create `lib/viz/collectables/coin_viz.dart`:

```dart
import 'dart:math' as math;
import 'dart:ui';

import '../rig/color_slot.dart';
import '../rig/shapes.dart';
import '../rig/viz_clip.dart';
import '../rig/viz_palette.dart';
import '../rig/viz_rig.dart';

const VizPalette coinDefaultPalette = VizPalette(
  id: 'coin_default',
  label: 'Coin',
  colors: {
    ColorSlot.primary: Color(0xffe0b33c),
    ColorSlot.secondary: Color(0xffb98d21),
    ColorSlot.belly: Color(0xfffff2c4),
    ColorSlot.accent: Color(0xfff2d778),
    ColorSlot.eye: Color(0xff6b4f0f),
    ColorSlot.outline: Color(0xff8a6913),
  },
);

/// A spinning coin. Design space 120x120.
///
/// Clip reinterpretation: breathe = idle bob, walk = slow spin,
/// run = fast spin.
class CoinViz extends VizRig {
  @override
  String get id => 'coin';

  @override
  String get displayName => 'Coin';

  @override
  Size get canvasSize => const Size(120, 120);

  @override
  VizPalette get defaultPalette => coinDefaultPalette;

  @override
  Set<VizClip> get supportedClips => VizClip.values.toSet();

  @override
  List<RigPart> get parts => [
    RigPart(
      id: 'disc',
      path: ovalPath(0, 0, 38, 38),
      slot: ColorSlot.primary,
      pivot: const Offset(60, 60),
      z: 0,
    ),
    RigPart(
      id: 'inner',
      parent: 'disc',
      path: ovalPath(0, 0, 29, 29),
      slot: ColorSlot.accent,
      pivot: Offset.zero,
      z: 1,
    ),
    RigPart(
      id: 'glyph',
      parent: 'disc',
      path: capsulePath(0, 0, 9, 40),
      slot: ColorSlot.outline,
      pivot: Offset.zero,
      z: 2,
    ),
    RigPart(
      id: 'shine',
      parent: 'disc',
      path: ovalPath(0, 0, 7, 15),
      slot: ColorSlot.belly,
      pivot: const Offset(-16, -12),
      z: 3,
    ),
  ];

  @override
  Pose poseAt(VizClip clip, double t) => switch (clip) {
    VizClip.breathe => _bob(t),
    VizClip.walk => _spin(t, turns: 1),
    VizClip.run => _spin(t, turns: 3),
  };

  Pose _bob(double t) {
    final theta = 2 * math.pi * t;
    return {
      'disc': PartPose(
        offset: Offset(0, -4 * math.sin(theta)),
        scaleX: 1 + 0.02 * math.sin(theta),
        scaleY: 1 - 0.02 * math.sin(theta),
      ),
      // The highlight travels across the face.
      'shine': PartPose(
        offset: Offset(10 * math.sin(theta), 4 * math.cos(theta)),
      ),
    };
  }

  /// [turns] must be an integer so the spin closes its loop.
  Pose _spin(double t, {required int turns}) {
    final theta = 2 * math.pi * turns * t;
    return {
      // Squashing the disc through zero reads as the coin turning edge-on;
      // every child inherits it.
      'disc': PartPose(scaleX: math.cos(theta)),
      'shine': PartPose(offset: Offset(0, 4 * math.sin(2 * theta))),
    };
  }
}
```

- [ ] **Step 4: Write the XP orb gameobject**

Create `lib/viz/collectables/xp_orb_viz.dart`:

```dart
import 'dart:math' as math;
import 'dart:ui';

import '../rig/color_slot.dart';
import '../rig/shapes.dart';
import '../rig/viz_clip.dart';
import '../rig/viz_palette.dart';
import '../rig/viz_rig.dart';

const VizPalette xpOrbDefaultPalette = VizPalette(
  id: 'xp_orb_default',
  label: 'XP Orb',
  colors: {
    ColorSlot.primary: Color(0x4d4fb8ff),
    ColorSlot.secondary: Color(0xff2f7d9e),
    ColorSlot.belly: Color(0xffe4f7ff),
    ColorSlot.accent: Color(0xff4fb8ff),
    ColorSlot.eye: Color(0xffffffff),
    ColorSlot.outline: Color(0xff1c4a63),
  },
);

const int _moteCount = 3;

/// A glowing experience orb with orbiting motes. Design space 120x120.
///
/// Clip reinterpretation: breathe = slow pulse, walk = orbit,
/// run = fast orbit.
class XpOrbViz extends VizRig {
  @override
  String get id => 'xp_orb';

  @override
  String get displayName => 'XP Orb';

  @override
  Size get canvasSize => const Size(120, 120);

  @override
  VizPalette get defaultPalette => xpOrbDefaultPalette;

  @override
  Set<VizClip> get supportedClips => VizClip.values.toSet();

  @override
  List<RigPart> get parts => [
    RigPart(
      id: 'halo',
      path: ovalPath(0, 0, 40, 40),
      slot: ColorSlot.primary,
      pivot: const Offset(60, 60),
      z: 0,
    ),
    RigPart(
      id: 'core',
      path: ovalPath(0, 0, 22, 22),
      slot: ColorSlot.accent,
      pivot: const Offset(60, 60),
      z: 1,
    ),
    for (var i = 0; i < _moteCount; i++)
      RigPart(
        id: 'mote$i',
        path: ovalPath(0, 0, 5, 5),
        slot: ColorSlot.belly,
        pivot: const Offset(60, 60),
        z: 2 + i,
      ),
  ];

  @override
  Pose poseAt(VizClip clip, double t) => switch (clip) {
    VizClip.breathe => _orbit(t, turns: 1, radius: 30, pulse: 0.10),
    VizClip.walk => _orbit(t, turns: 2, radius: 34, pulse: 0.06),
    VizClip.run => _orbit(t, turns: 4, radius: 38, pulse: 0.04),
  };

  /// [turns] must be an integer so the orbit closes its loop.
  Pose _orbit(
    double t, {
    required int turns,
    required double radius,
    required double pulse,
  }) {
    final theta = 2 * math.pi * t;
    final spin = 2 * math.pi * turns * t;
    final pose = <String, PartPose>{
      'halo': PartPose(
        scaleX: 1 + pulse * math.sin(theta),
        scaleY: 1 + pulse * math.sin(theta),
      ),
      'core': PartPose(
        scaleX: 1 + pulse * 0.6 * math.sin(theta + 0.8),
        scaleY: 1 + pulse * 0.6 * math.sin(theta + 0.8),
      ),
    };
    for (var i = 0; i < _moteCount; i++) {
      final phase = spin + i * 2 * math.pi / _moteCount;
      pose['mote$i'] = PartPose(
        offset: Offset(radius * math.cos(phase), radius * math.sin(phase)),
      );
    }
    return pose;
  }
}
```

- [ ] **Step 5: Register both in the catalog**

In `lib/viz/viz_catalog.dart`, add:

```dart
import 'collectables/coin_viz.dart';
import 'collectables/xp_orb_viz.dart';
```

and extend the list to:

```dart
  static List<VizRig> get all => List<VizRig>.unmodifiable(<VizRig>[
    Fox(),
    Deer(),
    Hummingbird(),
    Raccoon(),
    ...TreeCatalog.stages,
    CoinViz(),
    XpOrbViz(),
  ]);
```

- [ ] **Step 6: Run the tests to verify they pass**

Run: `flutter test`
Expected: PASS. Note that `test/collect/skin_catalog_test.dart`'s
`'every skin names a rig that exists in the viz catalog'` still passes, because
skins reference only the four animal rigs.

- [ ] **Step 7: Verify analysis is clean**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 8: Look at it**

Run the app and check the Coin and XP Orb subjects. At 0.25x the coin should
read as turning, not as a shrinking ellipse.

- [ ] **Step 9: Commit**

```bash
git add lib/viz/collectables lib/viz/viz_catalog.dart test/viz/coin_viz_test.dart test/viz/xp_orb_viz_test.dart
git commit -m "feat(viz): add coin and XP orb collectable gameobjects"
```

---

### Task 6: Egg Viz Object

**Files:**
- Create: `lib/viz/collectables/egg_viz.dart`
- Modify: `lib/viz/viz_catalog.dart`
- Test: `test/viz/egg_viz_test.dart`

**Interfaces:**
- Consumes: `VizRig`, `RigPart`, `PartPose`, `Pose`, `ColorSlot`, `VizPalette`, `VizClip`, `ovalPath`, `curvedPath`.
- Produces: `class EggViz extends VizRig` with `id == 'egg'`, canvas `Size(120, 140)`, part ids `glow`, `shellBottom`, `speckle0`, `speckle1`, `speckle2`, `shellTop`.
- Produces: `const VizPalette eggDefaultPalette`.

**Art notes:** the shell is split into a bottom and a top half sharing a seam at
y = 70 in design space. `breathe` wobbles the whole egg, `walk` shakes it, and
`run` is the crack: the top half lifts and tilts away from the seam and returns,
with the glow swelling through the gap. This is a loop, not a one-shot reveal —
a scripted reveal is explicitly out of scope.

- [ ] **Step 1: Write the failing egg viz tests**

Create `test/viz/egg_viz_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/viz/collectables/egg_viz.dart';
import 'package:moneymoneymoney/viz/rig/viz_clip.dart';
import 'package:moneymoneymoney/viz/rig/viz_rig.dart';
import 'package:moneymoneymoney/viz/viz_catalog.dart';

void main() {
  final egg = EggViz();

  test('declares a stable identity and all three clips', () {
    expect(egg.id, 'egg');
    expect(egg.displayName, 'Egg');
    expect(egg.supportedClips, VizClip.values.toSet());
  });

  test('every part has a unique z and a resolvable parent', () {
    final zs = egg.parts.map((p) => p.z).toList();
    expect(zs.toSet().length, zs.length);
    final ids = egg.parts.map((p) => p.id).toSet();
    for (final part in egg.parts) {
      if (part.parent != null) {
        expect(ids, contains(part.parent), reason: part.id);
      }
    }
  });

  test('the speckles ride on the bottom shell', () {
    final byId = {for (final p in egg.parts) p.id: p};
    for (final id in ['speckle0', 'speckle1', 'speckle2']) {
      expect(byId[id]!.parent, 'shellBottom');
    }
  });

  test('the glow draws behind both shell halves', () {
    final byId = {for (final p in egg.parts) p.id: p};
    expect(byId['glow']!.z, lessThan(byId['shellBottom']!.z));
    expect(byId['glow']!.z, lessThan(byId['shellTop']!.z));
  });

  test('every clip loops', () {
    for (final clip in egg.supportedClips) {
      final start = egg.poseAt(clip, 0);
      final end = egg.poseAt(clip, 0.9999);
      for (final id in start.keys) {
        expect(end[id]!.rotation, closeTo(start[id]!.rotation, 0.02),
            reason: '$clip / $id');
        expect(end[id]!.offset.dy, closeTo(start[id]!.offset.dy, 0.05),
            reason: '$clip / $id');
      }
    }
  });

  test('the idle wobble is gentler than the shake', () {
    double peak(VizClip clip) {
      var best = 0.0;
      for (var i = 0; i < 200; i++) {
        final r = egg.poseAt(clip, i / 200)['shellBottom']!.rotation.abs();
        best = r > best ? r : best;
      }
      return best;
    }

    expect(peak(VizClip.breathe), lessThan(peak(VizClip.walk)));
  });

  test('only the crack separates the top shell from the seam', () {
    double lift(VizClip clip) {
      var best = 0.0;
      for (var i = 0; i < 200; i++) {
        final dy = egg.poseAt(clip, i / 200)['shellTop']!.offset.dy.abs();
        best = dy > best ? dy : best;
      }
      return best;
    }

    expect(lift(VizClip.run), greaterThan(4));
    expect(lift(VizClip.breathe), lessThan(2));
  });

  test('is registered in the catalog', () {
    expect(VizCatalog.byId('egg'), isA<VizRig>());
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/viz/egg_viz_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:moneymoneymoney/viz/collectables/egg_viz.dart'`.

- [ ] **Step 3: Write the egg gameobject**

Create `lib/viz/collectables/egg_viz.dart`:

```dart
import 'dart:math' as math;
import 'dart:ui';

import '../rig/color_slot.dart';
import '../rig/shapes.dart';
import '../rig/viz_clip.dart';
import '../rig/viz_palette.dart';
import '../rig/viz_rig.dart';

const VizPalette eggDefaultPalette = VizPalette(
  id: 'egg_default',
  label: 'Egg',
  colors: {
    ColorSlot.primary: Color(0xffefe3cd),
    ColorSlot.secondary: Color(0xffd8c6a8),
    ColorSlot.belly: Color(0xfffff8ec),
    ColorSlot.accent: Color(0xffc79a33),
    ColorSlot.eye: Color(0xffffffff),
    ColorSlot.outline: Color(0xff8d7a58),
  },
);

/// A lootbox egg split at a seam. Design space 120x140, seam at y = 70.
///
/// Clip reinterpretation: breathe = idle wobble, walk = shake,
/// run = crack. All three loop; a one-shot hatch reveal is out of scope.
class EggViz extends VizRig {
  @override
  String get id => 'egg';

  @override
  String get displayName => 'Egg';

  @override
  Size get canvasSize => const Size(120, 140);

  @override
  VizPalette get defaultPalette => eggDefaultPalette;

  @override
  Set<VizClip> get supportedClips => VizClip.values.toSet();

  @override
  List<RigPart> get parts => [
    RigPart(
      id: 'glow',
      path: ovalPath(0, 0, 30, 30),
      slot: ColorSlot.accent,
      pivot: const Offset(60, 70),
      z: 0,
    ),
    RigPart(
      id: 'shellBottom',
      // Lower half: a rounded bowl sitting under the seam.
      path: curvedPath(const Offset(-34, 0), [
        (const Offset(-34, 30), const Offset(-18, 48), const Offset(0, 48)),
        (const Offset(18, 48), const Offset(34, 30), const Offset(34, 0)),
      ]),
      slot: ColorSlot.primary,
      pivot: const Offset(60, 70),
      z: 1,
    ),
    RigPart(
      id: 'speckle0',
      parent: 'shellBottom',
      path: ovalPath(0, 0, 5, 4),
      slot: ColorSlot.secondary,
      pivot: const Offset(-14, 18),
      z: 2,
    ),
    RigPart(
      id: 'speckle1',
      parent: 'shellBottom',
      path: ovalPath(0, 0, 4, 3.4),
      slot: ColorSlot.secondary,
      pivot: const Offset(12, 26),
      z: 3,
    ),
    RigPart(
      id: 'speckle2',
      parent: 'shellBottom',
      path: ovalPath(0, 0, 3.4, 3),
      slot: ColorSlot.secondary,
      pivot: const Offset(0, 10),
      z: 4,
    ),
    RigPart(
      id: 'shellTop',
      // Upper half: a taller dome above the seam.
      path: curvedPath(const Offset(-34, 0), [
        (const Offset(-34, -34), const Offset(-16, -60), const Offset(0, -60)),
        (const Offset(16, -60), const Offset(34, -34), const Offset(34, 0)),
      ]),
      slot: ColorSlot.belly,
      pivot: const Offset(60, 70),
      z: 5,
    ),
  ];

  @override
  Pose poseAt(VizClip clip, double t) => switch (clip) {
    VizClip.breathe => _wobble(t),
    VizClip.walk => _shake(t),
    VizClip.run => _crack(t),
  };

  Pose _wobble(double t) {
    final theta = 2 * math.pi * t;
    final tilt = 0.05 * math.sin(theta);
    return {
      'shellBottom': PartPose(rotation: tilt),
      'shellTop': PartPose(rotation: tilt, offset: Offset(0, math.sin(theta))),
      'glow': PartPose(
        scaleX: 1 + 0.05 * math.sin(2 * theta),
        scaleY: 1 + 0.05 * math.sin(2 * theta),
      ),
    };
  }

  Pose _shake(double t) {
    final theta = 2 * math.pi * t;
    final jitter = 0.17 * math.sin(6 * theta);
    return {
      'shellBottom': PartPose(rotation: jitter),
      'shellTop': PartPose(
        rotation: jitter * 1.15,
        offset: Offset(0, 1.5 * math.sin(3 * theta)),
      ),
      'glow': PartPose(
        scaleX: 1 + 0.12 * math.sin(3 * theta),
        scaleY: 1 + 0.12 * math.sin(3 * theta),
      ),
    };
  }

  Pose _crack(double t) {
    final theta = 2 * math.pi * t;
    // The top half lifts clear of the seam and settles back each loop.
    final lift = -14.0 * math.sin(theta).abs();
    return {
      'shellBottom': PartPose(rotation: 0.10 * math.sin(2 * theta)),
      'shellTop': PartPose(
        offset: Offset(4 * math.sin(theta).abs(), lift),
        rotation: 0.30 * math.sin(theta).abs(),
      ),
      'glow': PartPose(
        scaleX: 1 + 0.45 * math.sin(theta).abs(),
        scaleY: 1 + 0.45 * math.sin(theta).abs(),
      ),
    };
  }
}
```

- [ ] **Step 4: Register the egg in the catalog**

In `lib/viz/viz_catalog.dart`, add `import 'collectables/egg_viz.dart';` and add
`EggViz(),` to the end of the list.

- [ ] **Step 5: Run the tests to verify they pass**

Run: `flutter test`
Expected: PASS.

- [ ] **Step 6: Verify analysis is clean**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 7: Look at it**

Run the app, select Egg, and step through Breathe, Walk and Run. The seam should
stay closed in the first two and open in the third.

- [ ] **Step 8: Commit**

```bash
git add lib/viz/collectables/egg_viz.dart lib/viz/viz_catalog.dart test/viz/egg_viz_test.dart
git commit -m "feat(viz): add egg gameobject with wobble, shake and crack states"
```

---

### Task 7: Workbench Collectables And Skin Picker

**Files:**
- Modify: `lib/viz/workbench/viz_workbench_screen.dart`
- Test: `test/viz/viz_workbench_collectables_test.dart`

**Interfaces:**
- Consumes: `VizCatalog.all`, `VizStage`, `VizClip`, `SkinCatalog.forRig`, `Skin.palette`.
- Produces: widget keys `Key('viz-skin-<skinId>')` and `Key('viz-skin-default')`.
- Behaviour: the skin row is present only when `SkinCatalog.forRig(rig.id)` is non-empty — that is, for the four animals. Selecting a skin sets `VizStage.palette`; selecting Default clears it back to `null`.

- [ ] **Step 1: Write the failing workbench collectables tests**

Create `test/viz/viz_workbench_collectables_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/main.dart';
import 'package:moneymoneymoney/viz/viz_stage.dart';

void main() {
  // The catalog reaches eleven subjects in this task and the skin row adds a
  // sixth chip below, so give the workbench room rather than relying on the
  // bounded scroll regions keeping every chip hit-testable.
  Future<void> pumpWorkbench(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MyApp(vizMode: true));
  }

  testWidgets('lists the collectable subjects alongside the animals', (
    tester,
  ) async {
    await pumpWorkbench(tester);
    expect(find.byKey(const Key('viz-subject-coin')), findsOneWidget);
    expect(find.byKey(const Key('viz-subject-xp_orb')), findsOneWidget);
    expect(find.byKey(const Key('viz-subject-egg')), findsOneWidget);
  });

  testWidgets('offers a skin row for an animal subject', (tester) async {
    await pumpWorkbench(tester);
    expect(find.byKey(const Key('viz-skin-fox_ember')), findsOneWidget);
  });

  testWidgets('choosing a skin repaints the stage with its palette', (
    tester,
  ) async {
    await pumpWorkbench(tester);
    expect(tester.widget<VizStage>(find.byType(VizStage)).palette, isNull);

    await tester.tap(find.byKey(const Key('viz-skin-fox_ember')));
    await tester.pump();
    expect(
      tester.widget<VizStage>(find.byType(VizStage)).palette?.id,
      'fox_ember',
    );
  });

  testWidgets('the default chip clears the skin override', (tester) async {
    await pumpWorkbench(tester);
    await tester.tap(find.byKey(const Key('viz-skin-fox_ember')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('viz-skin-default')));
    await tester.pump();
    expect(tester.widget<VizStage>(find.byType(VizStage)).palette, isNull);
  });

  testWidgets('switching subject drops a stale skin override', (tester) async {
    await pumpWorkbench(tester);
    await tester.tap(find.byKey(const Key('viz-skin-fox_ember')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('viz-subject-coin')));
    await tester.pump();
    expect(tester.widget<VizStage>(find.byType(VizStage)).palette, isNull);
    expect(find.byKey(const Key('viz-skin-fox_ember')), findsNothing);
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/viz/viz_workbench_collectables_test.dart`
Expected: FAIL — `Expected: exactly one matching candidate / Actual: _KeyWidgetFinder … found 0 widgets` for `viz-skin-fox_ember`. The `viz-subject-coin`, `viz-subject-xp_orb` and `viz-subject-egg` tests should already pass from Tasks 5 and 6.

- [ ] **Step 3: Add the skin picker to the workbench**

In `lib/viz/workbench/viz_workbench_screen.dart`, add these imports:

```dart
import '../../collect/catalog/skin_catalog.dart';
import '../rig/viz_palette.dart';
```

Add a field beside the existing ones:

```dart
  VizPalette? _palette;
```

Replace `_selectRig` with:

```dart
  void _selectRig(VizRig rig) {
    setState(() {
      _rig = rig;
      // A skin belongs to one rig; it never carries over to another subject.
      _palette = null;
      if (!rig.supportedClips.contains(_clip)) {
        _clip = rig.supportedClips.first;
      }
    });
  }
```

Pass the palette to the stage — replace the `VizStage(...)` call with:

```dart
                    child: VizStage(
                      rig: _rig,
                      clip: _clip,
                      palette: _palette,
                      speed: _speed,
                      showPivots: _showPivots,
                    ),
```

Insert the skin row as the first entry of the bottom controls `Column`'s
`children`, directly above the clip `Wrap`:

```dart
                        if (SkinCatalog.forRig(_rig.id).isNotEmpty) ...[
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              ChoiceChip(
                                key: const Key('viz-skin-default'),
                                label: const Text('Default'),
                                selected: _palette == null,
                                onSelected: (_) =>
                                    setState(() => _palette = null),
                              ),
                              for (final skin in SkinCatalog.forRig(_rig.id))
                                ChoiceChip(
                                  key: Key('viz-skin-${skin.id}'),
                                  label: Text(skin.label),
                                  selected: _palette?.id == skin.id,
                                  onSelected: (_) =>
                                      setState(() => _palette = skin.palette),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
```

The bottom controls sit inside a `ConstrainedBox(maxHeight: 260)` wrapping a
`SingleChildScrollView`, so the extra row cannot overflow the column.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test`
Expected: PASS.

If the subject chips or the skin chips overflow their row on a narrow test
surface, the `Wrap` already handles it; do not switch to a `Row`.

- [ ] **Step 5: Verify analysis is clean**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 6: Look at it**

Run the app, pick each animal, and step through all five of its skins. Confirm
switching subject resets the skin row.

- [ ] **Step 7: Commit**

```bash
git add lib/viz/workbench/viz_workbench_screen.dart test/viz/viz_workbench_collectables_test.dart
git commit -m "feat(viz): add skin picker to the workbench for live repainting"
```

---

### Task 8: Beta Credit HUD And Check-In Wiring

**Files:**
- Create: `lib/screens/widgets/wallet_hud.dart`
- Modify: `lib/main.dart`
- Modify: `lib/screens/home_screen.dart`
- Test: `test/wallet_hud_test.dart`

**Interfaces:**
- Consumes: `PlayerState`, `Wallet.creditLabel`, `XpState.level`, `XpState.levelProgress`, `EconomyService.rewardFor`, `EconomyService.apply`, `ForestSummary.currentStreak`, `CheckInResult.day`.
- Produces: `class WalletHud extends StatelessWidget { const WalletHud({super.key, required PlayerState player}); }`
- Produces: `HomeScreen({..., required PlayerState player})` — the existing named parameters are unchanged and `player` is added.
- Behaviour: `MyApp` holds `PlayerState _player = PlayerState.beta()`; `_handleCheckIn` applies the day's reward after the forest engine runs.
- Copy, verbatim: `You start with $20.00 beta credit`, shown only while `player.wallet.coins == Wallet.betaGrantCoins && player.betaGrantClaimed`.

- [ ] **Step 1: Write the failing HUD tests**

Create `test/wallet_hud_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/collect/models/player_state.dart';
import 'package:moneymoneymoney/collect/models/wallet.dart';
import 'package:moneymoneymoney/collect/models/xp_state.dart';
import 'package:moneymoneymoney/main.dart';
import 'package:moneymoneymoney/screens/widgets/wallet_hud.dart';

void main() {
  Widget host(PlayerState player) =>
      MaterialApp(home: Scaffold(body: WalletHud(player: player)));

  // Same reason as test/widget_test.dart: the onboarding and report screens are
  // taller than the 800x600 default test surface.
  Future<void> pumpApp(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MyApp(vizMode: false));
  }

  testWidgets('shows the level, the balance and the beta credit line', (
    tester,
  ) async {
    await tester.pumpWidget(host(PlayerState.beta()));
    expect(find.text('Level 1'), findsOneWidget);
    expect(find.text('20'), findsOneWidget);
    expect(find.text(r'You start with $20.00 beta credit'), findsOneWidget);
  });

  testWidgets('drops the beta line once the balance moves', (tester) async {
    await tester.pumpWidget(
      host(PlayerState.beta().copyWith(wallet: const Wallet(coins: 23))),
    );
    expect(find.text(r'You start with $20.00 beta credit'), findsNothing);
    expect(find.text('23'), findsOneWidget);
  });

  testWidgets('reflects the derived level', (tester) async {
    await tester.pumpWidget(
      host(PlayerState.beta().copyWith(xp: const XpState(totalXp: 150))),
    );
    expect(find.text('Level 3'), findsOneWidget);
  });

  testWidgets('a successful check-in awards XP and coins on the home screen', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.enterText(find.byKey(const Key('income-field')), '6000');
    await tester.enterText(find.byKey(const Key('expenses-field')), '2500');
    await tester.enterText(find.byKey(const Key('savings-field')), '900');
    await tester.tap(find.text('Generate Report'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start Plan'));
    await tester.pumpAndSettle();

    expect(find.text('20'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('spending-field')), '10');
    await tester.tap(find.byKey(const Key('action-complete-checkbox')));
    await tester.tap(find.text('Check In'));
    await tester.pumpAndSettle();

    // Healthy day at streak 1, well under budget: +3 base +2 guardian coins.
    expect(find.text('25'), findsOneWidget);
    expect(find.text('Healthy tree'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/wallet_hud_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:moneymoneymoney/screens/widgets/wallet_hud.dart'`.

- [ ] **Step 3: Write the HUD widget**

Create `lib/screens/widgets/wallet_hud.dart`:

```dart
import 'package:flutter/material.dart';

import '../../collect/models/player_state.dart';
import '../../collect/models/wallet.dart';

/// Compact progression readout: level, XP bar, coin balance, and the beta
/// credit line until the player's balance first moves.
class WalletHud extends StatelessWidget {
  const WalletHud({super.key, required this.player});

  final PlayerState player;

  bool get _showBetaLine =>
      player.betaGrantClaimed &&
      player.wallet.coins == Wallet.betaGrantCoins;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Level ${player.xp.level}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              const Icon(Icons.monetization_on_outlined, size: 18),
              const SizedBox(width: 4),
              Text(
                '${player.wallet.coins}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: player.xp.levelProgress,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${player.xp.xpIntoLevel} / '
            '${player.xp.xpForNextLevel == 0 ? '—' : player.xp.xpForNextLevel}'
            ' XP',
            style: theme.textTheme.bodySmall,
          ),
          if (_showBetaLine) ...[
            const SizedBox(height: 6),
            Text(
              r'You start with $20.00 beta credit',
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xffc79a33),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Show the HUD on the home screen**

In `lib/screens/home_screen.dart`, add these imports below the existing ones:

```dart
import '../collect/models/player_state.dart';
import 'widgets/wallet_hud.dart';
```

Add the parameter to the constructor and the field:

```dart
  const HomeScreen({
    super.key,
    required this.report,
    required this.summary,
    required this.player,
    required this.onCheckIn,
    required this.onShowReport,
    required this.onShowAchievements,
  });

  final WealthReport report;
  final ForestSummary summary;
  final PlayerState player;
```

In `build`, insert the HUD immediately after the `_MetricRow` block — that is,
replace:

```dart
                _MetricRow(
                  streak: widget.summary.currentStreak,
                  healthy: widget.summary.healthyTreeCount,
                  withered: widget.summary.witheredTreeCount,
                ),
                const SizedBox(height: 18),
```

with:

```dart
                _MetricRow(
                  streak: widget.summary.currentStreak,
                  healthy: widget.summary.healthyTreeCount,
                  withered: widget.summary.witheredTreeCount,
                ),
                const SizedBox(height: 12),
                WalletHud(player: widget.player),
                const SizedBox(height: 18),
```

- [ ] **Step 5: Wire the economy into check-in**

In `lib/main.dart`, add these imports below the existing ones:

```dart
import 'collect/models/player_state.dart';
import 'collect/services/economy_service.dart';
```

Add the service and the state to `_MyAppState`, beside `_forestEngine`:

```dart
  final EconomyService _economyService = const EconomyService();
  PlayerState _player = PlayerState.beta();
```

Pass the player to the home screen — in `_buildCurrentView`, change the
`AppView.home` case to:

```dart
      case AppView.home:
        return HomeScreen(
          report: report,
          summary: _summary,
          player: _player,
          onCheckIn: _handleCheckIn,
          onShowReport: () => setState(() => _view = AppView.report),
          onShowAchievements: () =>
              setState(() => _view = AppView.achievements),
        );
```

Reset the player when a new profile is submitted — in
`_handleProfileSubmitted`, add inside the `setState` block:

```dart
      _player = PlayerState.beta();
```

Award the day's reward — replace the `setState` at the end of `_handleCheckIn`
with:

```dart
    final reward = _economyService.rewardFor(
      day: result.day,
      streak: result.summary.currentStreak,
    );

    setState(() {
      _summary = result.summary;
      _player = _economyService.apply(_player, reward);
    });
```

- [ ] **Step 6: Run the whole suite to verify it passes**

Run: `flutter test`
Expected: PASS, including the pre-existing `test/widget_test.dart` flow tests,
which construct `HomeScreen` only through `MyApp` and so pick up the new
parameter automatically.

- [ ] **Step 7: Verify analysis is clean**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 8: Look at it**

Temporarily set `kVizMode` to `false` in `lib/app_mode.dart`, run the app, walk
the questionnaire through to the forest screen, and confirm the HUD shows
`Level 1`, `20`, and the beta credit line, and that a healthy under-budget
check-in moves the balance to `25` and fills the XP bar. **Set `kVizMode` back
to `true` before committing.**

- [ ] **Step 9: Commit**

```bash
git add lib/screens/widgets/wallet_hud.dart lib/screens/home_screen.dart lib/main.dart test/wallet_hud_test.dart
git commit -m "feat(collect): award XP and coins on check-in and show the beta credit HUD"
```
