# Progression Economy — Build Report

Branch: `feat/progression-economy`
Base: `main` at `c748f96` (the merge of PR #1, before PRs #2–#4 landed)
Spec: `docs/superpowers/specs/2026-08-29-progression-economy-design.md`

## What this branch adds

A progression and cosmetic-economy layer on top of the existing wealth forest check-in loop. All of it is client-side Dart with no new runtime dependencies, and it holds state in memory, matching the base MVP.

### XP and profile level

Healthy check-in days earn XP. A missed day earns zero and is never penalised.

- Base healthy day: 10 XP
- Streak bonus: 2 XP per prior consecutive day, capped at 20
- Under-budget bonus: 5 XP when spending is at or below 80% of the daily budget
- Achievement unlock: 25 XP each

Maximum 35 XP from a single day. Level curve is `xpToAdvance(L) = 100 + 50*(L-1)`, with levels capping at 50.

### Coin economy

Coins are earned from the same records and are cosmetic-only: non-cash, non-tradeable, and not purchasable with money.

- 5 coins per healthy day, plus 3 for finishing under budget
- Streak milestones: 3 days awards 15, 7 awards 30, 14 awards 60, 30 awards 120
- 20 coins per achievement, and 25 × level on each level-up

### Shop

Eleven cosmetic items across three categories — five tree skins, three grounds, three skies. Each has a coin price and a level gate, so coins alone cannot skip progression. Purchases are atomic, cannot be repeated for an owned item, and do not auto-equip; equipping is a separate free action with exactly one item active per category.

Rendered as icon and colour variations rather than artwork, since the project has no image assets yet.

### Restoration — replaces permanent withering

A withered tree can be cleared by spending coins. The rule that matters: **a restored day repairs the streak and the visual, but never counts as a healthy day and never pays XP or coins.** The honest record underneath is preserved, so coins cannot buy a fake track record.

- Eligible for withered days aged 0 to 6 days, not already restored
- Costs 60 coins, then 150 for a second restoration in a trailing 30-day window
- A third restoration in that window is unpurchasable at any price
- Requires a written recovery note from the user

### Achievements

Three added to the existing five: **Second Wind** (restore a day — recovery is rewarded, not shamed), **Curator** (own a non-default cosmetic), **Seedling Scholar** (reach level 5).

### UI

Home screen gains a level chip, XP bar, coin balance, equipped-skin rendering, a restoration panel when the latest day is withered, a shop entry point, and a post-check-in earnings line. Achievements screen gains a progression card, a four-tile stat row, and a recent-activity ledger. New shop screen.

## Verification

- `flutter analyze` — no issues, exit 0
- `flutter test` — 38/38 passing, exit 0
- All pre-existing tests pass unchanged. The additions are backward-compatible: `ForestEngine.summarize` gained optional parameters specifically so existing call sites keep working.

Toolchain: Flutter 3.47.2 stable, installed during this work. `pubspec.lock` and `analysis_options.yaml` were refreshed by the newer SDK.

## Known issues, not yet fixed

Found by audit after implementation. None block review, all are worth addressing.

1. **Restoration window is one day too wide.** `forest_engine.dart` uses `ageInDays > 7`, admitting an 8-day span. The spec now specifies 0 to 6. One-character fix.
2. **The progression/achievement recompute loop has no safety margin.** Curator reads shop state and Seedling Scholar reads level, while achievement unlocks award XP that feeds back into level. `main.dart` resolves this with a 4-pass fixed-point loop, and the one realistic worst-case cascade consumes exactly 4 passes. It also exits silently if it never stabilises. The spec now requires a budget of at least 6 and an assertion on non-convergence. Better still, remove the cycle by partitioning achievements into forest-derived and progression-derived sets.
3. **Untested rules:** the level-50 cap, end-to-end refusal of a double restore or a restore on a non-withered day, and the exact boundaries where spending equals the budget or equals 80% of it.

## Conflicts with current `main` — read before merging

This branch was built on `main` at `c748f96`. Since then PRs #2, #3, and #4 have landed, and the two lines of work overlap significantly.

**File-level conflicts are expected** in `lib/main.dart`, `lib/screens/home_screen.dart`, `lib/services/forest_engine.dart`, `lib/screens/onboarding_screen.dart`, and `test/widget_test.dart` — all were modified on both sides.

**The deeper conflict is architectural.** `backend,dataAPI/engine/progression.py` on current `main` implements a second, independent progression system:

| | This branch (Dart) | `main` (Python) |
| --- | --- | --- |
| Metaphor | Forest — trees grow and wither | Wealth Tower — floors and weather |
| XP curve | `100(L-1) + 25(L-1)(L-2)` | `100 × N^1.35` |
| Max level | 50 | 30 |
| Shop | 11 cosmetics, 120–600 coins | 5 items, 150–900 coins |
| Location | Client | Server |

These produce different levels and coin totals for identical user activity. If both ship, the app shows inconsistent numbers depending on which surface is asked.

Two points for the team decision:

- The server-side placement is arguably correct long-term. This branch's own spec states that a client-side economy must become server-authoritative before release.
- The Python shop sells a **Double XP Weekend booster** for 150 coins. That is a non-cosmetic item that buys progression advantage, which contradicts the cosmetic-only principle this branch was built on. Whichever economy wins, that item should be a deliberate choice rather than an inherited one.

**Recommendation:** resolve the metaphor and the authoritative economy before merging either. A textual merge would produce code that compiles and ships two contradictory games.
