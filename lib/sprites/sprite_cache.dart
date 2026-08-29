import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

/// Decoded sprite frames, keyed by asset path.
///
/// A [CustomPainter] must produce pixels synchronously, but [AssetImage] only
/// offers a stream. This holds the decoded frame so a repaint can look one up
/// with [peek] and fall back to a placeholder until it arrives.
class SpriteCache {
  SpriteCache._();

  static final SpriteCache instance = SpriteCache._();

  final Map<String, ui.Image> _images = <String, ui.Image>{};

  /// The decoded image for [assetPath], or null if it is not loaded yet.
  ui.Image? peek(String assetPath) => _images[assetPath];

  /// Decodes [assetPath] and keeps it. Repeat calls return the same image.
  Future<ui.Image> load(String assetPath) async {
    final cached = _images[assetPath];
    if (cached != null) return cached;

    final completer = Completer<ui.Image>();
    final stream = AssetImage(assetPath).resolve(ImageConfiguration.empty);
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        stream.removeListener(listener);
        if (!completer.isCompleted) completer.complete(info.image);
      },
      onError: (error, stack) {
        stream.removeListener(listener);
        if (!completer.isCompleted) completer.completeError(error, stack);
      },
    );
    stream.addListener(listener);

    final image = await completer.future;
    _images[assetPath] = image;
    return image;
  }

  Future<void> loadAll(Iterable<String> assetPaths) =>
      Future.wait(assetPaths.map(load));

  /// Test seam: seed a decoded image without reading the asset bundle.
  void put(String assetPath, ui.Image image) => _images[assetPath] = image;

  void clear() => _images.clear();
}
