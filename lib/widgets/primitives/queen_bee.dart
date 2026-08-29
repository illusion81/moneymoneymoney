import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/models.dart';

/// The queen bee: a larger crowned bee that roams the hive along the six
/// hexagonal axes. Every step it picks one of the 6 pointy-top hex directions,
/// glides a cell-sized hop, then picks again — bouncing off the canvas edges
/// and facing its direction of travel. Motion is gated on
/// `MediaQuery.disableAnimations`.
class QueenBee extends StatefulWidget {
  const QueenBee({
    super.key,
    required this.skin,
    this.size = 26,
  });

  /// The skin used to paint the queen.
  final BeeSkin skin;

  /// Body width in logical pixels (the bee scales from a 24-wide authoring).
  final double size;

  @override
  State<QueenBee> createState() => _QueenBeeState();
}

class _QueenBeeState extends State<QueenBee>
    with SingleTickerProviderStateMixin {
  final math.Random _rng = math.Random();

  late final AnimationController _move;
  late final CurvedAnimation _curve;

  Offset _from = Offset.zero;
  Offset _to = Offset.zero;
  double _angle = 0;
  Size _bounds = Size.zero;
  bool _animationsEnabled = true;
  bool _firstLayout = true;

  static const double _hopMin = 40;
  static const double _hopMax = 72;

  @override
  void initState() {
    super.initState();
    _move = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _curve = CurvedAnimation(parent: _move, curve: Curves.easeInOut);
    _move.addStatusListener(_onStatus);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bool enabled = !MediaQuery.disableAnimationsOf(context);
    if (enabled == _animationsEnabled) {
      return;
    }
    _animationsEnabled = enabled;
    if (enabled) {
      _startNextHop();
    } else {
      _move.stop();
      _move.value = 0;
    }
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _startNextHop();
    }
  }

  /// Chooses one of the six hexagonal axes, computes the next cell-sized hop,
  /// and glides there.
  void _startNextHop() {
    if (_bounds.isEmpty) {
      return;
    }
    final double rad = _rng.nextInt(6) * math.pi / 3; // 0°,60°,…,300°
    final double dist = _hopMin + _rng.nextDouble() * (_hopMax - _hopMin);
    final Offset dir = Offset(math.cos(rad), math.sin(rad));
    final Offset target = _to + dir * dist;

    final double margin = widget.size;
    final double cx = target.dx.clamp(
      margin,
      math.max(margin, _bounds.width - margin),
    );
    final double cy = target.dy.clamp(
      margin,
      math.max(margin, _bounds.height - margin),
    );

    setState(() {
      _from = _to;
      _to = Offset(cx, cy);
      _angle = rad;
    });
    _move.forward(from: 0);
  }

  @override
  void dispose() {
    _move.removeStatusListener(_onStatus);
    _curve.dispose();
    _move.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Size bounds =
            Size(constraints.maxWidth, constraints.maxHeight);
        if (bounds != _bounds) {
          _bounds = bounds;
          if (_firstLayout) {
            _firstLayout = false;
            _to = Offset(bounds.width / 2, bounds.height / 2);
            if (_animationsEnabled) {
              _startNextHop();
            }
          }
        }

        return AnimatedBuilder(
          animation: _move,
          builder: (BuildContext context, Widget? child) {
            final double t = _animationsEnabled ? _curve.value : 0.0;
            final Offset pos = Offset.lerp(_from, _to, t) ?? Offset.zero;
            final double h = widget.size * 22 / 24;
            return Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                Positioned(
                  left: pos.dx - widget.size / 2,
                  top: pos.dy - h / 2,
                  child: Transform.rotate(
                    angle: _animationsEnabled ? _angle : 0,
                    child: CustomPaint(
                      size: Size(widget.size, h),
                      painter: _QueenBeePainter(skin: widget.skin),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// Draws the queen bee: two flanking wings, a rounded body + stripe, a small
/// eye, and a three-point gold crown, all scaled from a 24-wide authoring box.
class _QueenBeePainter extends CustomPainter {
  _QueenBeePainter({required this.skin});

  final BeeSkin skin;

  static const Color _crown = Color(0xFFF5B322); // honey
  static const Color _crownEdge = Color(0xFFE08C1B); // honeyDeep
  static const Color _eye = Color(0xFF33251A); // ink

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width / 24;

    // Flanking wings (behind the body).
    final Paint wingPaint = Paint()..color = skin.wing;
    canvas.save();
    canvas.translate(8 * s, 7 * s);
    canvas.rotate(-0.35);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 12 * s, height: 9 * s),
      wingPaint,
    );
    canvas.restore();
    canvas.save();
    canvas.translate(16 * s, 7 * s);
    canvas.rotate(0.35);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 12 * s, height: 9 * s),
      wingPaint,
    );
    canvas.restore();

    // Body (rounded capsule) below the crown.
    final RRect body = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 6 * s, 24 * s, 16 * s),
      Radius.circular(8 * s),
    );
    canvas.drawRRect(body, Paint()..color = skin.body);

    // Stripe band.
    final RRect stripe = RRect.fromRectAndRadius(
      Rect.fromLTWH(9.5 * s, 12 * s, 5 * s, 9 * s),
      Radius.circular(1.5 * s),
    );
    canvas.drawRRect(stripe, Paint()..color = skin.stripe);

    // Eye dot on the head.
    canvas.drawCircle(Offset(17 * s, 10 * s), 1.4 * s, Paint()..color = _eye);

    // Three-point crown.
    final Path crown = Path()
      ..moveTo(4 * s, 7 * s)
      ..lineTo(4 * s, 3 * s)
      ..lineTo(8.5 * s, 5 * s)
      ..lineTo(12 * s, 1.5 * s)
      ..lineTo(15.5 * s, 5 * s)
      ..lineTo(20 * s, 3 * s)
      ..lineTo(20 * s, 7 * s)
      ..close();
    canvas.drawPath(crown, Paint()..color = _crown);
    canvas.drawPath(
      crown,
      Paint()
        ..color = _crownEdge
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8 * s,
    );
  }

  @override
  bool shouldRepaint(covariant _QueenBeePainter oldDelegate) {
    return oldDelegate.skin != skin;
  }
}
