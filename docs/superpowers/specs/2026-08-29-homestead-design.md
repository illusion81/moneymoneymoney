# Homestead & Calendar Split — Design

## Summary

Two related changes to `moneymoneymoney`:

1. Extract the monthly calendar grid out of the Forest screen into its own
   top-level tab, `Calendar`.
2. Add a new `Home` tab: a "homestead" yard where the player freely places
   decorations bought with coins in the shop. Introduces a new shop category
   (`decoration`), a shared item-icon system, and a small placement data
   model.

Coins, XP, and the shop's purchase flow already exist (`ProgressionEngine`,
`ShopService`) and are unchanged by this work.

## Navigation

Bottom nav becomes four tabs: **Forest / Calendar / Home / Awards**. `Report`
and `Shop` remain app-bar icon entry points (unchanged), not tabs.

`AppView.home` is renamed to `AppView.forest` (it currently means "the Forest
screen", which collides with the new Home/homestead concept). Two values are
added: `AppView.calendar`, `AppView.homestead`.

The Forest screen (`lib/screens/home_screen.dart`, class `HomeScreen`) keeps
the tree-status card, streak metrics, restoration panel, and daily check-in
form. It loses the `_ForestCalendar` widget and its private helpers
(`_ForestDayCell`, `_WeekdayLabel`, `_dateKey`, `_statusLabel`,
`_isSameDate`) — those move to the new calendar screen. Its `NavigationBar`
gains the `Calendar` and `Home` destinations.

## Calendar screen

New file `lib/screens/calendar_screen.dart`, class `CalendarScreen`. Wraps
the extracted `_ForestCalendar` grid in a `Scaffold` with the same app-bar
actions (Shop, Report, Achievements) and the shared 4-destination
`NavigationBar` as the other tab screens, `selectedIndex: 1`.

Inputs: `summary` (`ForestSummary`), `shopState` (`ShopState`, needed for the
tree-skin icon inside each day cell), plus the same navigation callbacks
`HomeScreen` already takes (`onShowReport`, `onShowAchievements`,
`onShowShop`, and a new `onShowForest` / `onShowHomestead` pair for the nav
bar).

## Shared item-visual system

New file `lib/services/item_visuals.dart`. Consolidates icon/color mapping
that is currently duplicated between `_HomeScreenState._treeIcon` and
`_ForestDayCell._treeIcon` in `home_screen.dart`, and adds mappings for the
categories that currently render with no icon at all (ground, sky,
decoration):

```dart
IconData treeSkinIcon({required String? equippedId, required int level});
Color groundColor(ShopState state);
Color skyColor(ShopState state);
({IconData icon, Color color}) shopItemVisual(ShopItem item);
```

`shopItemVisual` is the single lookup used by `ShopScreen`'s item cards, the
Forest scene, and the Homestead canvas/tray. Colors are drawn from the
existing palette (`#2f7d50` green, `#c79a33` gold, `#3f8f8a` teal, `#8a6a4f`
brown, plus a couple of new muted tones for the decoration set below).

`ShopScreen`'s `_ShopItemCard` gains a leading circular tinted icon chip
(same visual language as the existing coin-balance pill) built from
`shopItemVisual`, for every category — not just decorations.

## Decoration catalog

`ShopItemCategory` gains a `decoration` value. Six new `ShopItem` entries are
added to `kShopCatalog`, `isDefault: false` (nothing pre-owned):

| id | name | icon | price | requiredLevel |
|---|---|---|---|---|
| `deco-garden-lantern` | Garden Lantern | `Icons.wb_incandescent` | 80 | 1 |
| `deco-flower-bed` | Flower Bed | `Icons.local_florist` | 100 | 1 |
| `deco-garden-bench` | Garden Bench | `Icons.weekend` | 160 | 2 |
| `deco-bird-bath` | Bird Bath | `Icons.water_drop` | 220 | 3 |
| `deco-beehive` | Beehive | `Icons.hive` | 280 | 4 |
| `deco-garden-cabin` | Garden Cabin | `Icons.cabin` | 450 | 6 |

Unlike the single-slot "equip" categories, decorations do not use
`ShopState.equippedItemIds` — ownership (`ShopState.ownedItemIds`) governs
whether an item can be placed; *placement* is tracked separately (see
below), and multiple owned decorations can be placed simultaneously.

## Homestead data model & service

New file `lib/models/home_layout.dart`:

```dart
class DecorationPlacement {
  const DecorationPlacement({
    required this.itemId,
    required this.dx, // 0..1, fraction of canvas width
    required this.dy, // 0..1, fraction of canvas height
  });

  final String itemId;
  final double dx;
  final double dy;
}

class HomeLayoutState {
  const HomeLayoutState({required this.placements});

  final List<DecorationPlacement> placements; // unique itemId per entry
}
```

New file `lib/services/home_layout_service.dart`, mirroring `ShopService`'s
plain data-in/data-out shape (no widget dependency):

```dart
class HomeLayoutService {
  HomeLayoutState initialState();

  /// Clamps dx/dy to [0, 1]. Replaces any existing placement for itemId
  /// (so calling place() again on an already-placed item moves it).
  HomeLayoutState place({
    required HomeLayoutState state,
    required String itemId,
    required double dx,
    required double dy,
  });

  HomeLayoutState remove({required HomeLayoutState state, required String itemId});
}
```

`_MyAppState` (`lib/main.dart`) gains a `HomeLayoutService _homeLayoutService`
and `HomeLayoutState _homeLayout` field (initialized via
`_homeLayoutService.initialState()`), plus `_handlePlaceDecoration` and
`_handleRemoveDecoration` methods wired the same way `_handlePurchase` /
`_handleEquip` are today. State is in-memory only, matching the rest of the
app's current (unpersisted) state — no persistence work in this change.

## Homestead screen

New file `lib/screens/homestead_screen.dart`, class `HomesteadScreen`,
`selectedIndex: 2` in the shared nav bar.

Inputs: `progression`, `shopState`, `layout` (`HomeLayoutState`),
`onPlace(String itemId, double dx, double dy)`, `onRemove(String itemId)`,
plus the standard navigation callbacks.

Layout:
- **Yard canvas**: a bounded `Container` (fixed height, e.g. 280, full
  available width) styled with `skyColor`/`groundColor` from
  `item_visuals.dart` for visual continuity with the Forest scene. Wrapped in
  a `DragTarget<String>` keyed with a `GlobalKey` so drop offsets can be
  converted from global to local coordinates and then to `dx`/`dy` fractions
  via the canvas's `RenderBox.size`. Placed decorations render as
  `Positioned` icons (from `shopItemVisual`) inside a `Stack`, each wrapped in
  `Draggable<String>` (data = itemId) so they can be picked up and moved
  again, and in a `GestureDetector` with `onLongPress: () => onRemove(itemId)`.
- **Inventory tray**: a `Wrap` of owned-but-unplaced decorations (owned minus
  currently-placed item ids), each a `Draggable<String>` chip built from
  `shopItemVisual` + item name.
- **Empty state**: when `shopState.ownedItemIds` contains zero items of
  category `decoration`, show a message and an `OutlinedButton` to
  `onShowShop` instead of an empty tray.

## Testing

- `test/home_layout_service_test.dart` (new): `place` clamps dx/dy to
  [0, 1]; placing the same item twice replaces rather than duplicates its
  entry; `remove` drops the entry and is a no-op for an unknown id.
- `test/calendar_screen_test.dart` (new): the calendar-grid assertions
  currently in `widget_test.dart` (`forest-calendar-grid`,
  `forest-day-<date>`, `forest-tree-<status>-<date>` keys), adapted to pump
  `CalendarScreen` directly.
- `test/homestead_screen_test.dart` (new): empty state renders when no
  decorations are owned; dragging a tray item onto the canvas calls
  `onPlace` with a fractional offset inside [0, 1]; dragging a placed item
  calls `onPlace` again with the new offset; long-pressing a placed item
  calls `onRemove`.
- `test/widget_test.dart` (updated): Forest-screen tests drop the
  calendar-grid assertions (moved to `calendar_screen_test.dart`); the
  `MyApp`-level nav test is extended to cover tapping the `Calendar` and
  `Home` destinations from the Forest screen.
- `test/shop_service_test.dart` (updated): purchase/equip-adjacent coverage
  extended to confirm `decoration` items behave like any other category for
  `purchase()` (equip/slot behavior is intentionally not exercised for
  decorations, since they don't use `equippedItemIds`).

## Out of scope

- Persisting app state (progression, shop, layout) to local storage.
- Making existing tree-skin/ground/sky items placeable in the homestead.
- Resizing, rotating, or z-ordering placed decorations.
