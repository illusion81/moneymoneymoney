import 'package:flutter/widgets.dart';

import '../sprites/asset_paths.dart';

/// The market-sheet icons the app uses, named by role rather than by the
/// shape they happen to be, so swapping the art is a one-line change here.
enum MarketIcon {
  coin('coin'),
  xp('sparkle_eight'),
  streak('sparkle_six'),
  achievement('badge_rosette'),
  wallet('bank'),
  receipt('note_cash'),

  /// The sheet has no egg; the capsule seal is the closest silhouette.
  egg('seal_capsule'),
  lockedSkin('padlock'),
  lootbox('ticket'),
  vault('vault');

  const MarketIcon(this.iconName);

  /// Name of the underlying sheet icon, as listed in [SpriteAssets.iconNames].
  final String iconName;

  String get assetPath => SpriteAssets.icon(iconName);
}

/// Draws a [MarketIcon] at a fixed square size.
///
/// The icons are rasterised line art, so they are drawn unfiltered to keep
/// their outlines crisp at small sizes.
class MarketIconImage extends StatelessWidget {
  const MarketIconImage({
    super.key,
    required this.icon,
    this.size = 24,
    this.tint,
  });

  final MarketIcon icon;

  /// Width and height in logical pixels.
  final double size;

  /// Recolours the icon's opaque pixels. Null keeps the sheet's own two-tone.
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      icon.assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.none,
      isAntiAlias: false,
      color: tint,
      colorBlendMode: tint == null ? null : BlendMode.srcATop,
    );
  }
}
