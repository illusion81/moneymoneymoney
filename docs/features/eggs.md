# Eggs — Lootbox Hatching

## What it does

Eggs are the collectable reward loop: the player spends coins on an egg and
hatches it into one of the 25 animal sprites already shipped in
`ActorCatalog`. The four egg shell colours from `EggSprites` double as rarity
tiers, so a rarer shell yields rarer animals.

The core is deliberately free of persistence and of stored outcomes. An egg's
result is a pure, seeded function of its variant and a seed, so the same seed
always produces the same animal and the result can be recomputed on demand
instead of being written somewhere.

## The rarity model

Each `EggVariant` maps to one `EggTier`, carries a coin price, and publishes a
set of relative drop weights over the tiers.

| Shell | Tier | Price | Common | Uncommon | Rare | Legendary |
| --- | --- | --- | --- | --- | --- | --- |
| Cream | Common | 5 | 70 | 25 | 5 | 0 |
| Brown | Uncommon | 12 | 30 | 45 | 22 | 3 |
| Purple | Rare | 25 | 5 | 25 | 45 | 25 |
| Grey | Legendary | 40 | 0 | 15 | 45 | 40 |

Weights are relative, not percentages. The 25 animals are partitioned into the
four tiers (10 common, 7 uncommon, 5 rare, 3 legendary), so the weight table is
guaranteed to reference real animals and to never be empty. The partitions
cover all 25 ids in `SpriteAssets.animalIds`, so every animal is reachable.

## Egg lifecycle

An `Egg` is an immutable value with a four-state lifecycle. The state machine
returns a new `Egg` on every move and rejects illegal transitions with a
`StateError`:

| From | To | Meaning |
| --- | --- | --- |
| `locked` | `ready` | Purchased (unlocked) |
| `ready` | `hatching` | Hatch started |
| `hatching` | `hatched` | Animal revealed |
| `hatched` | — | Terminal |

Hatching a locked egg, or hatching an already-hatched egg, throws.

## The hatching screen

`EggScreen` is the single public widget. It shows the four eggs with prices, a
live coin balance, and a buy button per egg (disabled when the balance is too
low). Buying spends coins, then runs a three-beat sequence:

1. **Waiting** — the shell plays `rock` (cream/brown) or `bounce`
   (purple/grey) on a loop for about 1.4 seconds.
2. **Hatching** — the shell plays the one-shot `hatch` clip, which holds its
   last frame instead of looping.
3. **Revealed** — the hatched animal sprite and its tier label, plus a
   "Hatch another" button.

The wait and hatch phases are driven by one `AnimationController`; the hatch
clip is always sampled with `loop: false` so it can never wrap.

## Public API

- `EggTier` — `common`, `uncommon`, `rare`, `legendary`, each with a `label`.
- `EggVariantRarity` (extension on `EggVariant`) — `tier`, `label`,
  `priceCoins`, `weights`.
- `EggCatalog` — `animalsOfTier(EggTier)`, `tierOf(String)`, `allAnimalIds`.
- `EggRoller.roll(EggVariant, int seed) -> String` — the deterministic roll.
- `EggState` and `Egg` — `Egg.locked(variant, seed)`, `animalId`, `animalTier`,
  `priceCoins`, `canTransitionTo`, `to`, `startHatching`, `reveal`.
- `EggScreen({required Wallet wallet})` — the screen, documented to be routed
  via `Navigator.push` with `MaterialPageRoute(builder: (_) => EggScreen(wallet: wallet))`.

## Where it plugs in

- Reads `Wallet` from `lib/collect/models/` for pricing and spending; the
  screen keeps its own session-local copy and does not modify the collect
  models.
- Renders shells with `EggSprites` and the shared `SpriteCache` /
  `SpriteActorPainter` pipeline (always `FilterQuality.none`, no antialiasing),
  and reveals `ActorCatalog` animals via `SpriteAssets.animal(id)`.
- Navigation is intentionally **not** wired here. The screen is a public
  widget; the orchestrator owns routing.

## Deliberately left out

- **Persistence.** Eggs and the balance live for the session only, matching the
  rest of the economy.
- **Ownership / duplicate handling.** Eggs always hatch a fresh animal; there
  is no "already owned" refund path.
- **Stored results.** The hatched animal is recomputed from the seed rather
  than stored, so there is no save/load to reconcile.
- **Skins or tree integration.** The hatched animal is shown and named, but
  nothing yet equips it anywhere.
