import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/home_layout.dart';
import '../models/shop_item.dart';
import '../services/image_export_service.dart';
import '../services/item_visuals.dart';
import '../widgets/app_nav_bar.dart';

class HomesteadScreen extends StatefulWidget {
  const HomesteadScreen({
    super.key,
    required this.shopState,
    required this.layout,
    required this.onPlace,
    required this.onRemove,
    required this.onShowForest,
    required this.onShowCalendar,
    required this.onShowReport,
    required this.onShowAchievements,
    required this.onShowShop,
    required this.onExportImage,
    this.captureBoundary = captureBoundaryAsPng,
  });

  final ShopState shopState;
  final HomeLayoutState layout;
  final void Function(String itemId, double dx, double dy) onPlace;
  final void Function(String itemId) onRemove;
  final VoidCallback onShowForest;
  final VoidCallback onShowCalendar;
  final VoidCallback onShowReport;
  final VoidCallback onShowAchievements;
  final VoidCallback onShowShop;

  /// Called with the PNG-encoded bytes of the yard canvas when the user taps
  /// "Export image".
  final Future<void> Function(Uint8List pngBytes) onExportImage;

  /// Captures [GlobalKey]'s render boundary as PNG bytes. Overridable for
  /// testing — the real implementation exercises Flutter's rendering
  /// pipeline, which widget tests can't reliably await.
  final Future<Uint8List?> Function(GlobalKey key) captureBoundary;

  @override
  State<HomesteadScreen> createState() => _HomesteadScreenState();
}

const double _canvasHeight = 280;

class _HomesteadScreenState extends State<HomesteadScreen> {
  BuildContext? _canvasContext;
  final _exportBoundaryKey = GlobalKey();

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
        selectedIndex: 2,
        onShowForest: widget.onShowForest,
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
                RepaintBoundary(key: _exportBoundaryKey, child: _buildCanvas()),
                const SizedBox(height: 18),
                if (ownedDecorationIds.isEmpty)
                  _EmptyDecorationState(onShowShop: widget.onShowShop)
                else
                  _InventoryTray(items: unplacedItems),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCanvas() {
    return DragTarget<String>(
      key: const Key('homestead-canvas'),
      onAcceptWithDetails: (details) {
        final box = _canvasContext?.findRenderObject() as RenderBox?;
        if (box == null) {
          return;
        }
        final local = box.globalToLocal(details.offset);
        final dx = (local.dx / box.size.width).clamp(0.0, 1.0);
        final dy = (local.dy / box.size.height).clamp(0.0, 1.0);
        widget.onPlace(details.data, dx, dy);
      },
      builder: (context, candidateData, rejectedData) {
        _canvasContext = context;
        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            return Container(
              height: _canvasHeight,
              width: width,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: skyColor(widget.shopState),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 90,
                    child: Container(color: groundColor(widget.shopState)),
                  ),
                  if (widget.layout.placements.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Drag decorations here to place them.'),
                      ),
                    ),
                  for (final placement in widget.layout.placements)
                    Positioned(
                      left: (placement.dx * width - 20).clamp(
                        0.0,
                        width - 40,
                      ),
                      top: placement.dy * _canvasHeight - 20,
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
            );
          },
        );
      },
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

class _PlacedDecoration extends StatelessWidget {
  const _PlacedDecoration({super.key, required this.item, required this.onRemove});

  final ShopItem item;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final icon = _DecorationIcon(visual: shopItemVisual(item));

    return GestureDetector(
      onLongPress: onRemove,
      child: Draggable<String>(
        data: item.id,
        feedback: icon,
        childWhenDragging: Opacity(opacity: 0.3, child: icon),
        child: icon,
      ),
    );
  }
}

class _DecorationIcon extends StatelessWidget {
  const _DecorationIcon({required this.visual});

  final ShopItemVisual visual;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: visual.color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Icon(visual.icon, color: Colors.white, size: 22),
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
  const _InventoryTray({required this.items});

  final List<ShopItem> items;

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
          _TrayDecoration(key: Key('tray-item-${item.id}'), item: item),
      ],
    );
  }
}

class _TrayDecoration extends StatelessWidget {
  const _TrayDecoration({super.key, required this.item});

  final ShopItem item;

  @override
  Widget build(BuildContext context) {
    final visual = shopItemVisual(item);
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: visual.color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(visual.icon, color: visual.color, size: 20),
          const SizedBox(width: 6),
          Text(item.name),
        ],
      ),
    );

    return Draggable<String>(
      data: item.id,
      feedback: Material(color: Colors.transparent, child: chip),
      childWhenDragging: Opacity(opacity: 0.3, child: chip),
      child: chip,
    );
  }
}
