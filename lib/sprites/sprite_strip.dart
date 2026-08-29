import 'dart:ui';

/// A horizontal run of equal-sized frames inside one image.
///
/// A still sprite is just a strip of one frame, so every drawable subject can
/// use the same type and the field needs only one painter.
class SpriteStrip {
  const SpriteStrip({
    required this.assetPath,
    required this.frameCount,
    required Size this.frameSize,
    this.fps = 8,
  }) : assert(frameCount > 0, 'a strip needs at least one frame'),
       assert(fps > 0, 'fps must be positive');

  /// A still image: one frame covering the whole asset, whatever its size.
  ///
  /// Leaving the frame size to the image is what lets the market icons, which
  /// are all different shapes, share this type with the 32x32 animal sprites.
  const SpriteStrip.single(this.assetPath)
    : frameCount = 1,
      frameSize = null,
      fps = 1;

  final String assetPath;

  final int frameCount;

  /// Size of one frame in source pixels, or null to mean the whole image.
  /// Only a one-frame strip may leave this null.
  final Size? frameSize;

  /// Frames per second when played back.
  final double fps;

  bool get isAnimated => frameCount > 1;

  /// The source rectangle of [frame] within [image].
  Rect sourceRect(int frame, Image image) {
    final size = frameSize;
    if (size == null) {
      return Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    }
    final index = frame.clamp(0, frameCount - 1);
    return Rect.fromLTWH(index * size.width, 0, size.width, size.height);
  }

  /// Which frame is showing at [seconds].
  ///
  /// A one-shot clip holds its last frame instead of snapping back to the
  /// start, which is what a hatch should do.
  int frameAt(double seconds, {bool loop = true}) {
    if (frameCount == 1) return 0;
    final elapsed = seconds < 0 ? 0.0 : seconds;
    final raw = (elapsed * fps).floor();
    return loop ? raw % frameCount : raw.clamp(0, frameCount - 1);
  }

  /// How long one pass through the strip takes.
  Duration get duration =>
      Duration(microseconds: (frameCount / fps * 1000000).round());
}
