# Collectables Design — XP, Coins, Skins, Lootbox Eggs

## Goal

Give the Wealth Forest a progression and reward economy: daily check-ins award
XP and coins, coins buy lootbox eggs, eggs hatch animal skins, and skins repaint
the creatures built in the viz project. Beta users start with $20 of credit.

## Scope

Depends on the viz project (`docs/superpowers/viz-animals/spec.md`) being
complete: skins are `VizPalette` swaps on the rigs built there, and the coin,
XP orb and egg visuals are `VizRig` gameobjects shown through the same
workbench.

In scope:

- A coin wallet with a beta grant.
- An XP curve and levels.
- 20 animal skins (4 owned by default, 16 unlockable).
- Three lootbox egg tiers with weighted drop tables and duplicate protection.
- Viz gameobjects for the coin, the XP orb, and the egg.
- Workbench support for choosing and previewing every collectable asset.
- Wallet/XP HUD on the forest home screen.

Out of scope:

- Persistence. State lives in memory for the session, exactly like the existing
  report and forest state.
- Real money, payments, IAP, receipts, or any server. The "$20 credit" is a
  label on 20 soft coins.
- One-shot hatch cinematics. The egg viz object exposes three *looping* states;
  a scripted reveal sequence is a future extension.

## Direction of Dependency

`lib/collect/` may import from `lib/viz/`. `lib/viz/` must never import from
`lib/collect/`. A skin is data that happens to be a `VizPalette`; the rigs stay
ignorant of the economy.

The one exception is the workbench, which is a screen and may read both.

## Beta Credit

Every new player starts with `Wallet.betaGrantCoins = 20` coins and
`betaGrantClaimed = true`. Coins are integers. The UI presents the balance as
currency — `$20.00` — because that reads as a grant rather than a score, but
nothing in the app touches real money.

## XP And Levels

XP is a monotonic total; the level is derived from it, never stored separately.

- `xpForLevel(level) = 25 * level * (level - 1)` — the cumulative XP needed to
  *reach* that level. Level 1 = 0, level 2 = 50, level 3 = 150, level 4 = 300,
  level 5 = 500.
- Level is capped at 50. At the cap, progress reads as full.

## Daily Rewards

Computed from a `ForestDay` and the current streak. `ForestEngine` is not
modified — the economy reads its output.

| Condition | XP | Coins |
| --- | --- | --- |
| Healthy day | 10 | 3 |
| Withered day | 2 | 0 |
| Streak bonus (healthy only) | `min(20, 2 * (streak - 1))` | — |
| Budget Guardian (healthy, `dailyBudget > 0`, `spending < 0.8 * dailyBudget`) | — | +2 |

## Skins

A skin is `(id, label, rigId, rarity, palette)`. Five per animal: the default
plus one of each rarity.

| Animal | default | common | uncommon | rare | legendary |
| --- | --- | --- | --- | --- | --- |
| Fox | `fox_default` | `fox_ash` | `fox_arctic` | `fox_ember` | `fox_spirit` |
| Deer | `deer_default` | `deer_fawn` | `deer_dusk` | `deer_jade` | `deer_aurora` |
| Hummingbird | `hummingbird_default` | `hummingbird_sage` | `hummingbird_ruby` | `hummingbird_emerald` | `hummingbird_prism` |
| Raccoon | `raccoon_default` | `raccoon_dusk` | `raccoon_frost` | `raccoon_gilded` | `raccoon_shadow` |

The four defaults are owned and equipped from the start and are excluded from
the egg drop pool. The other sixteen are the pool.

## Lootbox Eggs

Three tiers, bought with coins, hatched into exactly one skin.

| Egg | Price | common | uncommon | rare | legendary |
| --- | --- | --- | --- | --- | --- |
| Common Egg | 5 | 70 | 25 | 5 | 0 |
| Rare Egg | 12 | 30 | 45 | 22 | 3 |
| Golden Egg | 25 | 0 | 40 | 45 | 15 |

Numbers are relative weights, not percentages.

Hatch algorithm:

1. Roll a rarity from the egg's weights.
2. If no skin of that rarity is unowned, step down one rarity and retry; if
   every rarity is exhausted, roll from the full pool and return a duplicate.
3. Pick uniformly among the skins of the chosen rarity.
4. If the result is already owned, it is a **duplicate**: no new skin is
   granted, and coins are refunded instead — common 2, uncommon 4, rare 8,
   legendary 15.

Randomness is injected as a `Random` parameter, so `Random(seed)` makes every
test deterministic. The service never constructs its own `Random`.

## Collectable Viz Objects

Three new `VizRig` gameobjects, living under `lib/viz/collectables/`, obeying
the same no-interaction rule as the animals. They reuse the three shared clips:

| Object | `breathe` | `walk` | `run` |
| --- | --- | --- | --- |
| Coin | Idle bob with a travelling shine | Slow edge-on spin | Fast spin |
| XP orb | Slow pulse | Orbiting mote | Fast orbit |
| Egg | Idle wobble | Shake (about to hatch) | Crack — shell halves separate and rejoin |

## Workbench Additions

The workbench subject list gains the collectable gameobjects, and — when the
selected subject is an animal — a **skin picker** row that repaints the live
stage with any skin in the catalog, owned or not. That is what "choosable assets
for editing" means here: every visual asset in the game is reachable and
previewable from the main screen while it is being refined.

## Home Screen HUD

The forest home screen (reachable with `kVizMode = false`) gains a compact HUD:
level, an XP progress bar, the coin balance, and — until the player's first
spend — the line `You start with $20.00 beta credit`.

## Testing Requirements

Unit tests:

- The wallet seeds 20 coins, refuses to overspend, and formats `$20.00`.
- `xpForLevel` and `levelForXp` agree at and around every boundary.
- A healthy day awards 10 XP and 3 coins; a withered day awards 2 XP and none.
- The streak bonus scales and caps at 20.
- The Budget Guardian bonus fires below 80 percent of budget and not at or
  above it, and never when the daily budget is 0.
- Every skin id is unique and names a rig that exists in the viz catalog.
- Every egg's weights sum above zero and reference only real rarities.
- Hatching with a fixed seed is reproducible.
- Hatching a fully-owned pool returns a duplicate with the right refund.
- Equipping a skin the player does not own is rejected.

Widget tests:

- The workbench lists the coin, XP orb, and egg subjects.
- Choosing a skin repaints the stage with that skin's palette.
- The home screen HUD shows the level, the coin balance, and the beta credit
  line.

## Future Extension Points

- Persistence of `PlayerState`.
- A scripted one-shot hatch reveal.
- Skins for the tree.
- Pity timers and duplicate-to-currency conversion rates tuned from telemetry.
