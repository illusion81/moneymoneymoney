# Market Icons

Replaces Material icons with the repo's real pixel-art market icons wherever a
genuine match exists, and leaves a clean structural hook for every concept that
still lacks art.

## What it does

`lib/services/item_visuals.dart` is the shared icon/colour source for the shop,
forest, and homestead screens. Before this change it only returned Material
`IconData`, so no screen could show the vendored market-sheet art. The change
adds a parallel, widget-returning path alongside the existing `IconData` one:

- `ShopItemVisual` gains an optional `marketIcon` field (`MarketIcon?`), so a
  single visual can carry both the Material fallback and the pixel-art icon.
- A new `ShopItemIcon` widget renders that visual — the pixel-art `MarketIcon`
  when one is present, the Material icon otherwise.

The `shop_screen` adopts the art in the three places a match is genuine:

| UI location | Was | Now |
|---|---|---|
| Coin balance in the shop header | `Icons.monetization_on` (gold) | `MarketIcon.coin` |
| Plus-membership lock on premium items | `Icons.lock` | `MarketIcon.lockedSkin` (padlock) |
| Shop item card leading chip | `Icon(visual.icon)` | `ShopItemIcon(visual: visual)` |

The icons are drawn unfiltered (`FilterQuality.none`, `isAntiAlias false`) and
left untinted, so the sheet's own white-fill/black-outline two-tone shows
through — recolouring a line-art icon would flatten its internal detail.

## Public API

- `ShopItemVisual` — unchanged fields `icon` (IconData) and `color` (Color),
  plus the new optional `MarketIcon? marketIcon` (defaults to null).
- `ShopItemIcon` — `StatelessWidget` with `visual` (required) and `size`
  (default 24). Renders `MarketIconImage` when `visual.marketIcon` is set,
  otherwise `Icon(visual.icon)`. The Material fallback inherits the enclosing
  `IconTheme` (e.g. a `CircleAvatar`'s `foregroundColor`), preserving existing
  tinting.
- All pre-existing functions are unchanged: `shopItemVisual`, `treeSkinIcon`,
  `groundColor`, `skyColor`.

## Where it plugs in

- `lib/services/item_visuals.dart` — adds the `marketIcon` field only; no
  existing signature changes, so the forest, homestead, and calendar screens
  that still call `shopItemVisual`, `treeSkinIcon`, `groundColor`, and
  `skyColor` compile and render exactly as before.
- `lib/ui/shop_item_icon.dart` — the new widget.
- `lib/screens/shop_screen.dart` — the three adoptions listed above.

## Coverage audit

The market sheet has 30 icons mapping to 9 semantic roles (coin, xp, streak,
achievement, wallet, receipt, lockedSkin, lootbox, vault) — all money or
progression concepts. The shop catalog is garden/forest stock (tree skins,
ground, sky, decorations), so almost none of it corresponds to market art.

**Genuinely mapped** (done):

| Concept | Role |
|---|---|
| Currency / coin balance | `coin` |
| Locked membership item | `lockedSkin` (padlock) |

**Still on Material icons** — no market-sheet match exists:

| Concept | Current Material icon |
|---|---|
| Tree skins (oak, ginkgo, cherry blossom, bonsai, crystal pine) | `eco`/`park`/`forest`/`local_florist`/`spa`/`ac_unit` |
| Ground (meadow, riverbank, autumn) | `landscape` |
| Sky (clear day, sunset, aurora) | `cloud` |
| Decorations (lantern, flower bed, bench, bird bath, beehive, cabin) | `wb_incandescent`/`local_florist`/`weekend`/`water_drop`/`hive`/`cabin` |
| Back-to-forest control | `park` |
| Debug toggles | `developer_mode`/`lock_open_outlined`/`bolt`/`bug_report_outlined` |

None of these has a genuine match in the 30-icon sheet, so none is forced. When
art for trees/ground/sky/decorations lands, it plugs in by setting
`ShopItemVisual.marketIcon` in `item_visuals.dart` and every screen that renders
through `ShopItemIcon` (and, later, its siblings) picks it up without touching
callers.

## Deliberately left out

- **Recolouring.** Icons render untinted; the sheet's two-tone is the intended
  look and a `srcATop` tint would collapse the black outline into a solid
  silhouette. The coin header no longer uses the app's gold coin accent for
  this reason.
- **Forest, homestead, and calendar screens** are owned by other lanes and are
  deliberately untouched; they keep rendering the Material fallbacks.
- **No new art** was created, and no `MarketIcon` roles were added or renamed.
