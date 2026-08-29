import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

import '../placeholder/motion/squash_stretch.dart';
import 'sprite_strip.dart';

/// The paint every sprite draw uses.
///
/// Pixel art must land on whole pixels: any resampling or antialiasing turns a
/// 32x32 sprite scaled up into a blurry smear.
Paint spritePaint() => Paint()
  ..filterQuality = FilterQuality.none
  ..isAntiAlias = false;

/// Where a sprite of [designSize] at [position] lands once [scale] is applied.
///
/// Anchored bottom-centre so a squash reads as weight pressing into the ground
/// rather than the whole body shrinking. This matches `PlaceholderBoxPainter`,
/// so swapping painters does not shift an actor.
Rect spriteDestRect({
  required Offset position,
  required Size designSize,
  required ScalePair scale,
}) {
  final width = designSize.width * scale.x;
  final height = designSize.height * scale.y;
  return Rect.fromLTWH(
    position.dx + (designSize.width - width) / 2,
    position.dy + (designSize.height - height),
    width,
    height,
  );
}

/// Draws one frame of a sprite strip under squash and stretch.
///
/// A still sprite is a one-frame strip, so this is the only sprite painter the
/// field needs.
class SpriteActorPainter extends CustomPainter {
  SpriteActorPainter({
    required this.image,
    required this.strip,
    required this.position,
    required this.designSize,
    required this.scale,
    this.frame = 0,
  });

  final ui.Image image;

  final SpriteStrip strip;

  /// Top-left of the unscaled design box.
  final Offset position;

  /// Design-space size before squash and stretch, not the source pixel size.
  final Size designSize;

  final ScalePair scale;

  /// Index into [strip]. Out-of-range values are clamped.
  final int frame;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImageRect(
      image,
      strip.sourceRect(frame, image),
      spriteDestRect(position: position, designSize: designSize, scale: scale),
      spritePaint(),
    );
  }

  @override
  bool shouldRepaint(SpriteActorPainter oldDelegate) =>
      oldDelegate.image != image ||
      oldDelegate.frame != frame ||
      oldDelegate.strip.assetPath != strip.assetPath ||
      oldDelegate.position != position ||
      oldDelegate.designSize != designSize ||
      oldDelegate.scale.x != scale.x ||
      oldDelegate.scale.y != scale.y;
}
