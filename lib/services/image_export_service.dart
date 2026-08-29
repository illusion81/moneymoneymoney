import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Captures the render boundary attached to [key] as PNG-encoded bytes.
/// Returns null if [key] is not currently attached to a repaint boundary.
Future<Uint8List?> captureBoundaryAsPng(
  GlobalKey key, {
  double pixelRatio = 2.0,
}) async {
  final boundary =
      key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
  if (boundary == null) {
    return null;
  }
  final image = await boundary.toImage(pixelRatio: pixelRatio);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  return byteData?.buffer.asUint8List();
}
