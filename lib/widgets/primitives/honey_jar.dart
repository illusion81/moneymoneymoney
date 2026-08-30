import 'dart:math' as math;

import 'package:flutter/material.dart';

/// One colour band of the [HoneyJar] pot (design.md §6).
///
/// Layers are measured from the jar bottom: [fromFrac] and [toFrac] are 0..1
/// fractions of the body's inner height, with 0 at the jar bottom and 1 at the
/// top. The [label] is metadata for an external legend — the jar itself does
/// not draw text.
class PotLayer {
  const PotLayer({
    required this.id,
    required this.label,
    required this.fromFrac,
    required this.toFrac,
    required this.fill,
    this.stripe,
  });

  /// Stable identifier; reported back through [HoneyJar.onSelectLayer].
  final String id;

  /// Legend label (design.md §6) — rendered by the caller, not the jar.
  final String label;

  /// Fraction of the inner height at which this layer starts, from the bottom.
  final double fromFrac;

  /// Fraction of the inner height at which this layer ends, from the bottom.
  final double toFrac;

  /// Layer fill colour.
  final Color fill;

  /// When set, the layer is drawn as a 115° hatched band alternating this
  /// colour and [fill] (7 px stripes) instead of a solid fill (design.md §6,
  /// the debt band).
  final Color? stripe;
}

/// The 118×176 honey-jar pot (design.md §6).
///
/// Draws a rim, a 3 px-stroked body with bottom-anchored [PotLayer]s, a glass
/// shine, a hatched debt band (via a small [CustomPainter]), an ink selection
/// ring, and three decorative infinite animations gated on
/// [MediaQuery.disableAnimationsOf]:
///   * two honey drops falling per the `fall` keyframes,
///   * an amber `swell` ellipse on impact,
///   * a clay `drip` teardrop below the jar.
class HoneyJar extends StatefulWidget {
  const HoneyJar({
    super.key,
    required this.layers,
    this.selectedId,
    this.onSelectLayer,
    this.width = 118,
    this.height = 176,
  });

  /// The pot's layers, drawn bottom-up (first layer sits at the jar bottom).
  final List<PotLayer> layers;

  /// The id of the currently selected layer, drawn with the ink ring.
  final String? selectedId;

  /// Invoked with a layer's [PotLayer.id] when it is tapped.
  final ValueChanged<String>? onSelectLayer;

  /// Total jar width (118 at the authored size, design.md §6).
  final double width;

  /// Total jar height (176 at the authored size, design.md §6).
  final double height;

  @override
  State<HoneyJar> createState() => _HoneyJarState();
}

class _HoneyJarState extends State<HoneyJar> with TickerProviderStateMixin {
  static const Color _ink = Color(0xFF33251A);
  static const Color _rimStroke = Color(0xFF7A5230);
  static const Color _bodyFill = Color(0xFFFFFCF3);

  late final AnimationController _fallController;
  late final AnimationController _dripController;

  @override
  void initState() {
    super.initState();
    _fallController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800), // `fall` / `swell` period.
    );
    _dripController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600), // `drip` period.
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _fallController.stop();
      _dripController.stop();
    } else if (!_fallController.isAnimating) {
      _fallController.repeat();
      _dripController.repeat();
    }
  }

  @override
  void dispose() {
    _fallController.dispose();
    _dripController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double w = widget.width;
    final double h = widget.height;
    final bool animating = !MediaQuery.disableAnimationsOf(context);

    // Body geometry (design.md §6): inset 4 px left/right, top 20; 3 px stroke.
    const double bodyWidth = 110;
    const double bodyHeight = 156;
    const double stroke = 3;
    // Inner (fill) area after the stroke, in body-local coordinates.
    final double innerBottom = bodyHeight - stroke; // 153
    final double innerHeight = bodyHeight - 2 * stroke; // 150

    return SizedBox(
      width: w,
      height: h,
      child: Stack(
        // The clay drip below the jar overhangs the box; don't clip it.
        clipBehavior: Clip.none,
        children: <Widget>[
          // --- Rim (88×9, radius 4) ---
          Positioned(
            left: (w - 88) / 2,
            top: 0,
            width: 88,
            height: 9,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: _rimStroke,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          // --- Body: 3 px stroke, TL16 TR16 BR44 BL44, clips its children ---
          Positioned(
            left: 4,
            top: 20,
            width: bodyWidth,
            height: bodyHeight,
            child: Container(
              decoration: BoxDecoration(
                color: _bodyFill,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomRight: Radius.circular(44),
                  bottomLeft: Radius.circular(44),
                ),
                border: Border.all(color: _rimStroke, width: stroke),
              ),
              clipBehavior: Clip.hardEdge,
              child: Stack(
                children: <Widget>[
                  // Layers, bottom-anchored.
                  for (final PotLayer layer in widget.layers)
                    _buildLayer(layer, innerHeight, innerBottom, bodyHeight),
                  // Glass shine: 9×54 r6 white @ 55% at jar (12, 26).
                  Positioned(
                    left: 8,
                    top: 6,
                    width: 9,
                    height: 54,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0x8CFFFFFF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                  // Decorative honey drops + impact swell (fall/swell).
                  if (animating) _buildImpactAndDrops(),
                ],
              ),
            ),
          ),
          // --- Clay drip below the jar ---
          if (animating) _buildDrip(),
        ],
      ),
    );
  }

  /// One bottom-anchored, tappable pot layer inside the body's inner area.
  Widget _buildLayer(
    PotLayer layer,
    double innerHeight,
    double innerBottom,
    double bodyHeight,
  ) {
    final bool selected = layer.id == widget.selectedId;
    // Layer edges in body-local coordinates (y grows downward).
    final double top = innerBottom - layer.toFrac * innerHeight;
    final double bottomEdgeY = innerBottom - layer.fromFrac * innerHeight;

    final Widget? content = layer.stripe == null
        ? null
        : CustomPaint(
            painter: _HatchPainter(stripe: layer.stripe!, fill: layer.fill),
          );

    return Positioned(
      left: 3,
      right: 3,
      top: top,
      bottom: bodyHeight - bottomEdgeY,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onSelectLayer == null
            ? null
            : () => widget.onSelectLayer!(layer.id),
        child: Container(
          decoration: BoxDecoration(color: layer.fill),
          // Sanctioned 2.5 px ink selection ring drawn over the fill
          // (design.md §4.2 / §4.7).
          foregroundDecoration: selected
              ? BoxDecoration(border: Border.all(color: _ink, width: 2.5))
              : null,
          child: content,
        ),
      ),
    );
  }

  /// The `fall` drops and the `swell` ellipse, driven by [_fallController].
  Widget _buildImpactAndDrops() {
    return AnimatedBuilder(
      animation: _fallController,
      builder: (BuildContext context, Widget? _) {
        final double t = _fallController.value;
        // Second drop delayed 1.4 s = half the 2.8 s period.
        final double t2 = (t + 0.5) % 1.0;
        return Stack(
          children: <Widget>[
            // Swell: 5 dp amber ellipse, scaleX .4→1→1.5, opacity 0→.85→0.
            Positioned(
              left: 38,
              top: 70,
              child: Transform.scale(
                scaleX: _swellScale(t),
                child: Opacity(
                  opacity: _swellOpacity(t),
                  child: Container(
                    width: 10,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF5B322),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
            _drop(t, big: true, left: 40, top: 20),
            _drop(t2, big: false, left: 56, top: 30),
          ],
        );
      },
    );
  }

  /// A single honey teardrop falling per the `fall` keyframes.
  Widget _drop(
    double t, {
    required bool big,
    required double left,
    required double top,
  }) {
    final Size size = big ? const Size(7, 11) : const Size(6, 9);
    return Positioned(
      left: left,
      top: top,
      child: Opacity(
        opacity: _dropOpacity(t),
        child: Transform.translate(
          offset: Offset(0, _dropTranslateY(t)),
          child: Transform.scale(
            scaleX: _dropScaleX(t),
            scaleY: _dropScaleY(t),
            child: CustomPaint(
              size: size,
              painter: _TeardropPainter(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[Color(0xFFFFD972), Color(0xFFE08C1B)],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The clay `drip` teardrop below the jar, driven by [_dripController].
  Widget _buildDrip() {
    return Positioned(
      left: 56,
      top: 174,
      child: AnimatedBuilder(
        animation: _dripController,
        builder: (BuildContext context, Widget? _) {
          final double t = _dripController.value;
          final double eased = Curves.easeIn.transform(t); // translateY 0→14.
          return Opacity(
            opacity: _dripOpacity(t),
            child: Transform.translate(
              offset: Offset(0, 14 * eased),
              child: CustomPaint(
                size: const Size(6, 9),
                painter: _TeardropPainter(
                  gradient: const LinearGradient(
                    colors: <Color>[Color(0xFFC4634C), Color(0xFFC4634C)],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // --- `fall` / `swell` / `drip` keyframes (design.md Motion appendix) ---

  double _dropTranslateY(double t) {
    // 0→40 @72%, then 40→48.
    return t < 0.72 ? (t / 0.72) * 40 : 40 + ((t - 0.72) / 0.28) * 8;
  }

  double _dropOpacity(double t) {
    // 0→1 @12%, →0.5 @88%, →0.
    if (t < 0.12) return t / 0.12;
    if (t <= 0.88) return 1 - ((t - 0.12) / 0.76) * 0.5;
    return 0.5 * (1 - (t - 0.88) / 0.12);
  }

  double _dropScaleX(double t) {
    // (.7)→(1)@0.35→(1.4)@0.8→(1.6)@1.
    if (t < 0.35) return _lerp(0.7, 1.0, t / 0.35);
    if (t < 0.8) return _lerp(1.0, 1.4, (t - 0.35) / 0.45);
    return _lerp(1.4, 1.6, (t - 0.8) / 0.2);
  }

  double _dropScaleY(double t) {
    // (.8)→(1.3)@0.35→(0.35)@0.8→(0.2)@1.
    if (t < 0.35) return _lerp(0.8, 1.3, t / 0.35);
    if (t < 0.8) return _lerp(1.3, 0.35, (t - 0.35) / 0.45);
    return _lerp(0.35, 0.2, (t - 0.8) / 0.2);
  }

  double _swellScale(double t) {
    // .4→1 @72%→1.5.
    return t < 0.72 ? 0.4 + (t / 0.72) * 0.6 : 1.0 + ((t - 0.72) / 0.28) * 0.5;
  }

  double _swellOpacity(double t) {
    // Dead until 55%, then 0→.85→0.
    if (t < 0.55) return 0;
    if (t < 0.85) return ((t - 0.55) / 0.30) * 0.85;
    return 0.85 * (1 - (t - 0.85) / 0.15);
  }

  double _dripOpacity(double t) {
    // 0→1 @30%→0.
    return t < 0.3 ? t / 0.3 : 1 - ((t - 0.3) / 0.7);
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;
}

/// Paints the 115° two-stripe hatch for a striped pot layer (design.md §6):
/// 7 px bands alternating `stripe` and `fill`.
class _HatchPainter extends CustomPainter {
  _HatchPainter({required this.stripe, required this.fill});

  final Color stripe;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    const double stripeWidth = 7;
    final double angle = 115 * math.pi / 180;
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(angle);
    // Bounding box large enough that the rotated stripes still cover the layer.
    final double r =
        math.sqrt(size.width * size.width + size.height * size.height) / 2 +
            stripeWidth;
    final Rect band =
        Rect.fromCenter(center: Offset.zero, width: 2 * r, height: 2 * r);
    final Paint paint = Paint();
    int i = 0;
    for (double x = band.left; x < band.right; x += stripeWidth) {
      paint.color = i.isEven ? stripe : fill;
      canvas.drawRect(Rect.fromLTWH(x, band.top, stripeWidth, band.height), paint);
      i++;
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _HatchPainter oldDelegate) =>
      oldDelegate.stripe != stripe || oldDelegate.fill != fill;
}

/// Paints a pointed-top, rounded-bottom teardrop filled with [gradient] (the
/// CSS `50% 50% 60% 60% / 70% 70% 40% 40%` drop shape from design.md §6).
class _TeardropPainter extends CustomPainter {
  _TeardropPainter({required this.gradient});

  final LinearGradient gradient;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..shader = gradient.createShader(Offset.zero & size);
    canvas.drawPath(_teardropPath(size), paint);
  }

  @override
  bool shouldRepaint(covariant _TeardropPainter oldDelegate) =>
      oldDelegate.gradient != gradient;
}

/// Pointed top, rounded bottom — a honey/debt drop.
Path _teardropPath(Size size) {
  final double w = size.width;
  final double h = size.height;
  return Path()
    ..moveTo(w / 2, 0)
    ..quadraticBezierTo(w, h * 0.3, w * 0.85, h * 0.8)
    ..quadraticBezierTo(w * 0.7, h, w * 0.5, h * 0.95)
    ..quadraticBezierTo(w * 0.3, h, w * 0.15, h * 0.8)
    ..quadraticBezierTo(0, h * 0.3, w / 2, 0)
    ..close();
}
