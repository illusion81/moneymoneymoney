import 'package:flutter/widgets.dart';

import '../services/item_visuals.dart';
import 'market_icon.dart';

/// The widget twin of [shopItemVisual]: renders a shop item's icon, using the
/// pixel-art [MarketIcon] when the visual carries one and falling back to the
/// Material [IconData] otherwise.
///
/// Screens that still only understand `IconData` (forest, homestead, calendar)
/// keep calling [shopItemVisual] and drawing `Icon(visual.icon)` themselves.
/// Screens adopting the real art render through this widget instead, so a
/// `ShopItemVisual` is the single source of truth for both representations.
class ShopItemIcon extends StatelessWidget {
  const ShopItemIcon({super.key, required this.visual, this.size = 24});

  final ShopItemVisual visual;

  /// Width and height in logical pixels, applied to whichever representation
  /// ends up drawn.
  final double size;

  @override
  Widget build(BuildContext context) {
    final marketIcon = visual.marketIcon;
    if (marketIcon != null) {
      return MarketIconImage(icon: marketIcon, size: size);
    }
    return Icon(visual.icon, size: size);
  }
}
