import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../widgets/decoration_view.dart';

import '../models/forest_day.dart';
import '../models/home_layout.dart';
import '../models/shop_item.dart';
import '../services/image_export_service.dart';
import '../services/isometric_grid.dart';
import '../services/item_visuals.dart';
import '../services/savings_stats_service.dart';
import '../widgets/app_nav_bar.dart';
import '../widgets/savings_chart.dart';

class HomesteadScreen extends StatefulWidget {
  const HomesteadScreen({
    super.key,
    required this.shopState,
    required this.layout,
    required this.days,
    required this.onPlace,
    required this.onRemove,
    required this.onShowForest,
    required this.onShowSpending,
    required this.onShowCalendar,
    required this.onShowReport,
    required this.onShowAchievements,
    required this.onShowShop,
    required this.onExportImage,
    this.captureBoundary = captureBoundaryAsPng,
  });

  final ShopState shopState;
  final HomeLayoutState layout;

  /// Recorded forest days, used to compute the surplus-assets chart.
  final List<ForestDay> days;
  final void Function(String itemId, int row, int col) onPlace;
  final void Function(String itemId) onRemove;
  final VoidCallback onShowForest;
  final VoidCallback onShowSpending;
  final VoidCallback onShowCalendar;
  final VoidCallback onShowReport;
  final VoidCallback onShowAchievements;
  final VoidCallback onShowShop;

  /// Called with the PNG-encoded bytes of the yard grid when the user taps
  /// "Export image".
  final Future<void> Function(Uint8List pngBytes) onExportImage;

  /// Captures [GlobalKey]'s render boundary as PNG bytes. Overridable for
  /// testing — the real implementation exercises Flutter's rendering
  /// pipeline, which widget tests can't reliably await.
  final Future<Uint8List?> Function(GlobalKey key) captureBoundary;

  @override
  State<HomesteadScreen> createState() => _HomesteadScreenState();
}

/// Isometric tile geometry for the homestead grid, exposed so tests can
/// derive the on-screen position of a given grid cell.
const double kHomeTileWidth = 84;
const double kHomeTileHeight = 42;
const _geometry = IsoGridGeometry(
  tileWidth: kHomeTileWidth,
  tileHeight: kHomeTileHeight,
);
const double _dirtEdgeHeight = 24;
const double kHomeGridCanvasWidth =
    kHomeTileWidth * kHomeGridSize + kHomeTileWidth;
const double kHomeGridCanvasHeight =
    kHomeTileHeight * kHomeGridSize + _dirtEdgeHeight + kHomeTileHeight;
const kHomeGridOrigin = Offset(kHomeGridCanvasWidth / 2, kHomeTileHeight / 2);

class _HomesteadScreenState extends State<HomesteadScreen> {
  final _exportBoundaryKey = GlobalKey();
  String? _selectedItemId;
  StatsPeriod _statsPeriod = StatsPeriod.week;

  @override
  Widget build(BuildContext context) {
    final decorationItems = kShopCatalog
        .where((item) => item.category == ShopItemCategory.decoration)
        .toList();
    final placedIds = {
      for (final placement in widget.layout.placements) placement.itemId,
    };
    final ownedDecorationIds = widget.shopState.ownedItemIds
        .where((id) => decorationItems.any((item) => item.id == id))
        .toSet();
    final unplacedItems = decorationItems
        .where(
          (item) =>
              ownedDecorationIds.contains(item.id) &&
              !placedIds.contains(item.id),
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Homestead'),
        actions: [
          IconButton(
            key: const Key('export-image-button'),
            tooltip: 'Export image',
            onPressed: _exportImage,
            icon: const Icon(Icons.image_outlined),
          ),
          IconButton(
            tooltip: 'Shop',
            onPressed: widget.onShowShop,
            icon: const Icon(Icons.store_outlined),
          ),
          IconButton(
            tooltip: 'Report',
            onPressed: widget.onShowReport,
            icon: const Icon(Icons.description_outlined),
          ),
          IconButton(
            tooltip: 'Achievements',
            onPressed: widget.onShowAchievements,
            icon: const Icon(Icons.emoji_events_outlined),
          ),
        ],
      ),
      bottomNavigationBar: AppNavBar(
        selectedIndex: 3,
        onShowForest: widget.onShowForest,
        onShowSpending: widget.onShowSpending,
        onShowCalendar: widget.onShowCalendar,
        onShowHomestead: () {},
        onShowAchievements: widget.onShowAchievements,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: RepaintBoundary(
                    key: _exportBoundaryKey,
                    child: _buildGrid(placedIds),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _selectedItemId == null
                      ? 'Tap a decoration below, then tap a grid cell to place it.'
                      : 'Tap an empty cell to place the selected decoration.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 18),
                _SavingsStatsSection(
                  days: widget.days,
                  period: _statsPeriod,
                  onPeriodChanged: (period) =>
                      setState(() => _statsPeriod = period),
                ),
                const SizedBox(height: 18),
                if (ownedDecorationIds.isEmpty)
                  _EmptyDecorationState(onShowShop: widget.onShowShop)
                else
                  _InventoryTray(
                    items: unplacedItems,
                    selectedItemId: _selectedItemId,
                    onSelect: _selectTrayItem,
                  ),
                const SizedBox(height: 24),
                _ShareRow(
                  onShare: (network) => _showShareDemo(context, network),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGrid(Set<String> placedIds) {
    // The board is designed at kHomeGridCanvasWidth but a phone is narrower
    // than that, so scale the whole thing down uniformly to fit. Never scale
    // up past the design size — it only gets blurry and gigantic on desktop.
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth;
        final scale = available.isFinite && available > 0
            ? (available / kHomeGridCanvasWidth).clamp(0.0, 1.0)
            : 1.0;
        final geometry = IsoGridGeometry(
          tileWidth: kHomeTileWidth * scale,
          tileHeight: kHomeTileHeight * scale,
        );
        final canvasWidth = kHomeGridCanvasWidth * scale;
        final canvasHeight = kHomeGridCanvasHeight * scale;
        final origin = Offset(canvasWidth / 2, geometry.tileHeight / 2);

        return SizedBox(
          width: canvasWidth,
          height: canvasHeight,
          child: GestureDetector(
            key: const Key('homestead-grid'),
            behavior: HitTestBehavior.opaque,
            onTapUp: (details) =>
                _handleGridTap(details.localPosition, geometry, origin),
            child: Stack(
              children: [
                CustomPaint(
                  size: Size(canvasWidth, canvasHeight),
                  painter: _IsoGridPainter(
                    origin: origin,
                    geometry: geometry,
                    dirtEdgeHeight: _dirtEdgeHeight * scale,
                    grassColor: groundColor(widget.shopState),
                    dirtColor: _dirtColor(widget.shopState),
                  ),
                ),
                for (final placement in widget.layout.placements)
                  _positionedAt(
                    row: placement.row,
                    col: placement.col,
                    geometry: geometry,
                    origin: origin,
                    child: _PlacedDecoration(
                      key: Key('placed-item-${placement.itemId}'),
                      item: kShopCatalog.firstWhere(
                        (item) => item.id == placement.itemId,
                      ),
                      onRemove: () => widget.onRemove(placement.itemId),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _positionedAt({
    required int row,
    required int col,
    required IsoGridGeometry geometry,
    required Offset origin,
    required Widget child,
  }) {
    final center = origin + geometry.cellCenter(row: row, col: col);
    return Positioned(
      left: center.dx - geometry.tileWidth / 2,
      top: center.dy - geometry.tileHeight / 2,
      width: geometry.tileWidth,
      height: geometry.tileHeight,
      child: Center(child: child),
    );
  }

  void _selectTrayItem(String itemId) {
    setState(() {
      _selectedItemId = _selectedItemId == itemId ? null : itemId;
    });
  }

  /// Inverts the isometric projection to find which grid cell contains
  /// [localPosition], then places the selected tray item there if the cell
  /// is empty. Every point maps to the nearest cell (clamped to the grid),
  /// so there are no unreachable "dead zone" taps.
  void _handleGridTap(
    Offset localPosition,
    IsoGridGeometry geometry,
    Offset origin,
  ) {
    final selected = _selectedItemId;
    if (selected == null) {
      return;
    }

    final relative = localPosition - origin;
    final colF =
        relative.dx / geometry.tileWidth + relative.dy / geometry.tileHeight;
    final rowF =
        relative.dy / geometry.tileHeight - relative.dx / geometry.tileWidth;
    final row = rowF.round().clamp(0, kHomeGridSize - 1);
    final col = colF.round().clamp(0, kHomeGridSize - 1);

    final occupied = widget.layout.placements.any(
      (placement) => placement.row == row && placement.col == col,
    );
    if (occupied) {
      return;
    }
    widget.onPlace(selected, row, col);
    setState(() => _selectedItemId = null);
  }

  Color _dirtColor(ShopState shopState) {
    switch (shopState.equippedItemIds[ShopItemCategory.ground]) {
      case 'ground-riverbank':
        return const Color(0xff8a7a6a);
      case 'ground-autumn':
        return const Color(0xff8a6a4f);
      default:
        return const Color(0xff6b4a35);
    }
  }

  /// Sharing is not wired to any network. Rather than fake a successful post,
  /// this says so outright — a button that silently pretends to publish is the
  /// kind of thing people only discover is fake after they have told friends
  /// to go look for it.
  void _showShareDemo(BuildContext context, String network) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('share-demo-dialog'),
        title: Text('Share to $network'),
        content: Text(
          'Demo only — nothing was posted to $network. Real sharing needs an '
          'app review and API keys from $network, which this build does not '
          'have. Use "Export image" to save your homestead and post it '
          'yourself.',
        ),
        actions: [
          TextButton(
            key: const Key('share-demo-close'),
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportImage() async {
    final bytes = await widget.captureBoundary(_exportBoundaryKey);
    if (bytes == null) {
      return;
    }
    await widget.onExportImage(bytes);
  }
}

class _IsoGridPainter extends CustomPainter {
  const _IsoGridPainter({
    required this.origin,
    required this.geometry,
    required this.dirtEdgeHeight,
    required this.grassColor,
    required this.dirtColor,
  });

  final Offset origin;
  final IsoGridGeometry geometry;
  final double dirtEdgeHeight;
  final Color grassColor;
  final Color dirtColor;

  @override
  void paint(Canvas canvas, Size size) {
    _paintDirtBase(canvas);
    _paintTiles(canvas);
  }

  void _paintDirtBase(Canvas canvas) {
    final left =
        origin +
        geometry.cellCenter(row: kHomeGridSize - 1, col: 0) +
        Offset(-geometry.tileWidth / 2, 0);
    final bottom =
        origin +
        geometry.cellCenter(row: kHomeGridSize - 1, col: kHomeGridSize - 1) +
        Offset(0, geometry.tileHeight / 2);
    final right =
        origin +
        geometry.cellCenter(row: 0, col: kHomeGridSize - 1) +
        Offset(geometry.tileWidth / 2, 0);

    final path = Path()
      ..moveTo(left.dx, left.dy)
      ..lineTo(bottom.dx, bottom.dy)
      ..lineTo(right.dx, right.dy)
      ..lineTo(right.dx, right.dy + dirtEdgeHeight)
      ..lineTo(bottom.dx, bottom.dy + dirtEdgeHeight)
      ..lineTo(left.dx, left.dy + dirtEdgeHeight)
      ..close();

    canvas.drawPath(path, Paint()..color = dirtColor);
  }

  void _paintTiles(Canvas canvas) {
    final borderPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (var row = 0; row < kHomeGridSize; row++) {
      for (var col = 0; col < kHomeGridSize; col++) {
        final corners = _geometry
            .tileCorners(row: row, col: col)
            .map((corner) => origin + corner)
            .toList();
        final path = Path()
          ..moveTo(corners[0].dx, corners[0].dy)
          ..lineTo(corners[1].dx, corners[1].dy)
          ..lineTo(corners[2].dx, corners[2].dy)
          ..lineTo(corners[3].dx, corners[3].dy)
          ..close();

        final checker = (row + col).isEven;
        final fill = checker
            ? grassColor
            : Color.lerp(grassColor, Colors.black, 0.06)!;
        canvas.drawPath(path, Paint()..color = fill);
        canvas.drawPath(path, borderPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _IsoGridPainter oldDelegate) {
    return oldDelegate.grassColor != grassColor ||
        oldDelegate.dirtColor != dirtColor ||
        oldDelegate.origin != origin ||
        oldDelegate.geometry.tileWidth != geometry.tileWidth;
  }
}

class _PlacedDecoration extends StatelessWidget {
  const _PlacedDecoration({
    super.key,
    required this.item,
    required this.onRemove,
  });

  final ShopItem item;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onRemove,
      child: _DecorationIcon(visual: shopItemVisual(item), itemId: item.id),
    );
  }
}

class _DecorationIcon extends StatelessWidget {
  const _DecorationIcon({required this.visual, this.itemId});

  final ShopItemVisual visual;
  final String? itemId;

  @override
  Widget build(BuildContext context) {
    // Decorations that map to an animal render as the real artwork; anything
    // else keeps the coloured disc. A yard of flat icon badges reads as a
    // wireframe, not a homestead.
    final animal = visual.animalAsset;
    if (animal != null) {
      return Image.asset(
        'assets/animals/$animal.png',
        width: 58,
        height: 58,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, _, _) => _disc(),
      );
    }
    // Decorations are painted, not icon badges — see decoration_view.dart.
    if (itemId != null && itemId!.startsWith('deco-')) {
      return DecorationView(itemId: itemId!, size: 58);
    }
    return _disc();
  }

  Widget _disc() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: visual.color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Icon(visual.icon, color: Colors.white, size: 24),
    );
  }
}

class _SavingsStatsSection extends StatelessWidget {
  const _SavingsStatsSection({
    required this.days,
    required this.period,
    required this.onPeriodChanged,
  });

  final List<ForestDay> days;
  final StatsPeriod period;
  final void Function(StatsPeriod period) onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    final series = computeSavingsSeries(days: days, period: period);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and three chips do not fit side by side at real phone width
          // (390pt) — Wrap lets the chips drop to their own line instead of
          // running off the edge.
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            runSpacing: 8,
            spacing: 12,
            children: [
              Text(
                'Surplus assets',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              Wrap(
                spacing: 6,
                children: [
                  for (final option in StatsPeriod.values)
                    ChoiceChip(
                      key: Key('stats-period-${option.name}'),
                      label: Text(_periodLabel(option)),
                      selected: option == period,
                      onSelected: (_) => onPeriodChanged(option),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          SavingsChart(points: series),
        ],
      ),
    );
  }

  String _periodLabel(StatsPeriod period) {
    switch (period) {
      case StatsPeriod.week:
        return 'Week';
      case StatsPeriod.month:
        return 'Month';
      case StatsPeriod.year:
        return 'Year';
    }
  }
}

/// Share affordances for the homestead. Both are demo-only — see
/// _showShareDemo for why they say so rather than faking a post.
class _ShareRow extends StatelessWidget {
  const _ShareRow({required this.onShare});

  final void Function(String network) onShare;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Show off your homestead',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton.icon(
              key: const Key('share-facebook-button'),
              onPressed: () => onShare('Facebook'),
              icon: const Icon(Icons.facebook, size: 18),
              label: const Text('Facebook'),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              key: const Key('share-instagram-button'),
              onPressed: () => onShare('Instagram'),
              icon: const Icon(Icons.camera_alt_outlined, size: 18),
              label: const Text('Instagram'),
            ),
          ],
        ),
      ],
    );
  }
}

class _EmptyDecorationState extends StatelessWidget {
  const _EmptyDecorationState({required this.onShowShop});

  final VoidCallback onShowShop;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          const Text(
            'Buy decorations in the Shop to decorate your homestead.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onShowShop,
            icon: const Icon(Icons.store_outlined),
            label: const Text('Go to Shop'),
          ),
        ],
      ),
    );
  }
}

class _InventoryTray extends StatelessWidget {
  const _InventoryTray({
    required this.items,
    required this.selectedItemId,
    required this.onSelect,
  });

  final List<ShopItem> items;
  final String? selectedItemId;
  final void Function(String itemId) onSelect;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Text('All your decorations are placed.'),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final item in items)
          _TrayDecoration(
            key: Key('tray-item-${item.id}'),
            item: item,
            selected: item.id == selectedItemId,
            onTap: () => onSelect(item.id),
          ),
      ],
    );
  }
}

class _TrayDecoration extends StatelessWidget {
  const _TrayDecoration({
    super.key,
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final ShopItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final visual = shopItemVisual(item);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? visual.color.withValues(alpha: 0.15) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? visual.color
                : visual.color.withValues(alpha: 0.4),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(visual.icon, color: visual.color, size: 20),
            const SizedBox(width: 6),
            Text(item.name),
          ],
        ),
      ),
    );
  }
}
