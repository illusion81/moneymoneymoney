import 'dart:typed_data';
import 'dart:ui';

/// Captures the draw calls a [CustomPainter] makes, so painter behaviour can be
/// asserted without golden files.
class RecordingCanvas implements Canvas {
  final List<Path> paths = <Path>[];
  final List<Paint> paints = <Paint>[];
  final List<Float64List> transforms = <Float64List>[];

  @override
  void drawPath(Path path, Paint paint) {
    paths.add(path);
    paints.add(paint);
  }

  @override
  void transform(Float64List matrix4) {
    transforms.add(Float64List.fromList(matrix4));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
