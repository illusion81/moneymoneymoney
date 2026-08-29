import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/models.dart';

/// Decorative bee flight: a swarm of bees that wander randomly across the
/// canvas rather than following scripted in/out paths.
///
/// [beesIn] bees are painted with the skin's inbound palette, [beesOut] with
/// its outbound palette (design.md §1.1 `Bee literals`). Each bee drifts on a
/// gently-jittering heading and bounces off the canvas edges, facing its
/// direction of travel. [size] scales the authored 9×6 bee (default 9).
///
/// Motion is driven by a single [Ticker] (no per-bee timers) and gated on
/// `MediaQuery.disableAnimations`: when animations are disabled the bees are
/// scattered statically and the ticker is stopped.
class BeeSwarm extends StatefulWidget {
  const BeeSwarm({
    super.key,
    required this.beesIn,
    required this.beesOut,
    required this.skin,
    this.size = 9,
  });

  /// Number of inbound-palette bees (capped at [_BeeSwarmState._cap]).
  final int beesIn;

  /// Number of outbound-palette bees (capped at [_BeeSwarmState._cap]).
  final int beesOut;

  /// The skin used to paint every bee.
  final BeeSkin skin;

  /// Scale of the authored 9×6 bee (default 9).
  final double size;

  @override
  State<BeeSwarm> createState() => _BeeSwarmState();
}

class _BeeSwarmState extends State<BeeSwarm> with TickerProviderStateMixin {
  static const int _cap = 10;

  final List<_WanderBee> _bees = <_WanderBee>[];
  final math.Random _rng = math.Random();

  late final Ticker _ticker;
  late final AnimationController _flap;

  Duration _last = Duration.zero;
  Size _canvas = Size.zero;
  bool _animationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _flap = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _ticker = createTicker(_onTick);
    _rebuildBees();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bool enabled = !MediaQuery.disableAnimationsOf(context);
    if (enabled == _animationsEnabled) {
      return;
    }
    _animationsEnabled = enabled;
    _last = Duration.zero;
    if (enabled) {
      _flap.repeat(reverse: true);
      _ticker.start();
    } else {
      _flap.stop();
      _ticker.stop();
    }
  }

  @override
  void didUpdateWidget(BeeSwarm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.beesIn != widget.beesIn ||
        oldWidget.beesOut != widget.beesOut) {
      _rebuildBees();
    }
  }

  void _rebuildBees() {
    _bees.clear();
    final int inCount = widget.beesIn.clamp(0, _cap);
    final int outCount = widget.beesOut.clamp(0, _cap);
    for (int i = 0; i < inCount; i++) {
      _bees.add(_WanderBee(_rng, incoming: true));
    }
    for (int i = 0; i < outCount; i++) {
      _bees.add(_WanderBee(_rng, incoming: false));
    }
  }

  void _onTick(Duration elapsed) {
    final double dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    if (dt <= 0 || _canvas.isEmpty) {
      return;
    }
    for (final _WanderBee bee in _bees) {
      bee.update(dt, _canvas);
    }
    setState(() {});
  }

  @override
  void dispose() {
    _flap.dispose();
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Size canvas =
            Size(constraints.maxWidth, constraints.maxHeight);
        if (canvas != _canvas) {
          _canvas = canvas;
          for (final _WanderBee bee in _bees) {
            bee.ensurePositioned(canvas);
          }
        }
        return Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            for (final _WanderBee bee in _bees) _buildBee(bee),
          ],
        );
      },
    );
  }

  Widget _buildBee(_WanderBee bee) {
    return Positioned(
      left: bee.position.dx,
      top: bee.position.dy,
      child: Transform.rotate(
        angle: bee.heading,
        child: _BeeVisual(
          skin: widget.skin,
          incoming: bee.incoming,
          size: widget.size,
          flap: _flap,
          animateFlap: _animationsEnabled,
        ),
      ),
    );
  }
}

/// One wandering bee: a position, a heading (radians) and a constant speed.
/// `update` jitters the heading and bounces the bee off the canvas edges.
class _WanderBee {
  _WanderBee(this._rng, {required this.incoming})
      : _heading = _rng.nextDouble() * 2 * math.pi,
        _speed = 26 + _rng.nextDouble() * 30;

  final math.Random _rng;
  final bool incoming;

  Offset position = Offset.zero;
  double _heading;
  final double _speed;
  bool _positioned = false;

  double get heading => _heading;

  /// Scatters the bee to a random spot on first layout (or when the canvas
  /// changes size).
  void ensurePositioned(Size canvas) {
    if (_positioned) {
      return;
    }
    const double margin = 14;
    final double w = math.max(0, canvas.width - 2 * margin);
    final double h = math.max(0, canvas.height - 2 * margin);
    position = Offset(
      margin + _rng.nextDouble() * w,
      margin + _rng.nextDouble() * h,
    );
    _positioned = true;
  }

  void update(double dt, Size canvas) {
    // Gentle heading drift (±1.5 rad/s) so the bee wanders, not darts.
    _heading += (_rng.nextDouble() - 0.5) * 3.0 * dt;
    final Offset v =
        Offset(math.cos(_heading) * _speed, math.sin(_heading) * _speed);
    position = position + v * dt;

    const double margin = 10;
    final double maxX = canvas.width - margin;
    final double maxY = canvas.height - margin;
    if (position.dx < margin) {
      position = Offset(margin, position.dy);
      _heading = math.pi - _heading;
    } else if (position.dx > maxX) {
      position = Offset(maxX, position.dy);
      _heading = math.pi - _heading;
    }
    if (position.dy < margin) {
      position = Offset(position.dx, margin);
      _heading = -_heading;
    } else if (position.dy > maxY) {
      position = Offset(position.dx, maxY);
      _heading = -_heading;
    }
  }
}

/// The static bee artwork: 9×6 r4 body + 2×4 stripe + 6×4 flapping wing,
/// scaled by [size]/9 and painted from the active [skin].
class _BeeVisual extends StatelessWidget {
  const _BeeVisual({
    required this.skin,
    required this.incoming,
    required this.size,
    required this.flap,
    required this.animateFlap,
  });

  final BeeSkin skin;
  final bool incoming;
  final double size;
  final Animation<double> flap;
  final bool animateFlap;

  @override
  Widget build(BuildContext context) {
    final double s = size / 9; // scale from authored 9-wide body
    final Color body = incoming ? skin.body : skin.outBody;
    final Color stripe = incoming ? skin.stripe : skin.outStripe;
    final Color wing = incoming ? skin.wing : skin.outWing;

    final double bodyW = 9 * s;
    final double bodyH = 6 * s;
    final double stripeW = 2 * s;
    final double stripeH = 4 * s;
    final double wingW = 6 * s;
    final double wingH = 4 * s;

    return SizedBox(
      width: bodyW,
      height: bodyH,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          // Body.
          Container(
            width: bodyW,
            height: bodyH,
            decoration: BoxDecoration(
              color: body,
              borderRadius: BorderRadius.circular(4 * s),
            ),
          ),
          // Stripe: 2×4 centred band.
          Positioned(
            left: (bodyW - stripeW) / 2,
            top: (bodyH - stripeH) / 2,
            child: Container(
              width: stripeW,
              height: stripeH,
              decoration: BoxDecoration(
                color: stripe,
                borderRadius: BorderRadius.circular(1 * s),
              ),
            ),
          ),
          // Wing: 6×4 ellipse above the body, flaps about its attachment point.
          Positioned(
            left: (bodyW - wingW) / 2,
            top: -wingH,
            child: AnimatedBuilder(
              animation: flap,
              builder: (BuildContext context, Widget? child) {
                // 0.28 s ease-in-out ALTERNATE: scaleY .5→1, rotate −8°→10°.
                final double t =
                    animateFlap ? Curves.easeInOut.transform(flap.value) : 1.0;
                final double scaleY = 0.5 + 0.5 * t;
                final double rotDeg = -8 + (10 - -8) * t;
                return Transform(
                  alignment: Alignment.bottomCenter,
                  transform: Matrix4.identity()
                    ..rotateZ(rotDeg * math.pi / 180)
                    ..scaleByDouble(1.0, scaleY, 1.0, 1.0),
                  child: Container(
                    width: wingW,
                    height: wingH,
                    decoration: BoxDecoration(
                      color: wing,
                      borderRadius: BorderRadius.circular(wingH / 2),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
