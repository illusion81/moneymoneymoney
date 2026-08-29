import 'dart:ui';

/// Path helpers for rig parts. Every path is authored in part-local space with
/// the part's pivot at (0, 0).

Path ovalPath(double cx, double cy, double rx, double ry) => Path()
  ..addOval(
    Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: ry * 2),
  );

Path capsulePath(double cx, double cy, double w, double h) => Path()
  ..addRRect(
    RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy), width: w, height: h),
      Radius.circular(w / 2),
    ),
  );

Path trianglePath(Offset a, Offset b, Offset c) => Path()
  ..moveTo(a.dx, a.dy)
  ..lineTo(b.dx, b.dy)
  ..lineTo(c.dx, c.dy)
  ..close();

/// Builds a closed path from [start] through a list of
/// (control1, control2, endPoint) cubic segments.
Path curvedPath(Offset start, List<(Offset, Offset, Offset)> cubics) {
  final path = Path()..moveTo(start.dx, start.dy);
  for (final (c1, c2, end) in cubics) {
    path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, end.dx, end.dy);
  }
  return path..close();
}
