import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Decorative bee flight, one bee per transaction, capped at 5 per direction
/// (design.md §6 "BeeSwarm" + Motion appendix `beeIn` / `beeOut` / `flap`).
///
/// Amber in-bees (body `#4A3520`, stripe `#FFD972`, wing white @80%) fly in
/// over the honey side; cream out-bees (body `#F0DFC4`, stripe `#6E4826`,
/// wing white @55%) fly out under the brown side.
///
/// Each bee is a tiny 9×6 rounded body + 2×4 stripe + 6×4 wing that flaps on a
/// 0.28 s ease-in-out ALTERNATE loop. [size] scales the authored 9×6 bee and its
/// flight path (default 9 = authored size).
///
/// All flight controllers are gated on `MediaQuery.disableAnimations` — when
/// animations are disabled the bees are rendered statically at their start
/// positions and every controller is stopped.
class BeeSwarm extends StatefulWidget {
  const BeeSwarm({
    super.key,
    required this.beesIn,
    required this.beesOut,
    this.size = 9,
  });

  /// Number of amber bees flying in over the honey side (capped at 5).
  final int beesIn;

  /// Number of cream bees flying out under the brown side (capped at 5).
  final int beesOut;

  /// Scale of the authored 9×6 bee and its flight path (default 9).
  final double size;

  @override
  State<BeeSwarm> createState() => _BeeSwarmState();
}

class _BeeSwarmState extends State<BeeSwarm> with TickerProviderStateMixin {
  final List<_BeeFlight> _flights = <_BeeFlight>[];

  static const int _cap = 5;

  /// Last-known `MediaQuery.disableAnimations` value, so controllers are only
  /// (re)started/stopped when the setting actually changes.
  bool? _animationsEnabled;

  @override
  void initState() {
    super.initState();
    _rebuildFlights();
  }

  @override
  void didUpdateWidget(BeeSwarm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.beesIn != widget.beesIn ||
        oldWidget.beesOut != widget.beesOut) {
      _rebuildFlights();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimationsEnabled();
  }

  void _rebuildFlights() {
    for (final _BeeFlight flight in _flights) {
      flight.dispose();
    }
    _flights.clear();

    final int inCount = widget.beesIn.clamp(0, _cap);
    final int outCount = widget.beesOut.clamp(0, _cap);
    for (int i = 0; i < inCount; i++) {
      _flights.add(_BeeFlight.of(
        vsync: this,
        beeIndex: i,
        direction: _BeeDirection.incoming,
      ));
    }
    for (int i = 0; i < outCount; i++) {
      _flights.add(_BeeFlight.of(
        vsync: this,
        beeIndex: i,
        direction: _BeeDirection.outgoing,
      ));
    }
    _animationsEnabled = null; // force re-sync of running state
  }

  void _syncAnimationsEnabled() {
    final bool enabled = !MediaQuery.disableAnimationsOf(context);
    if (_animationsEnabled == enabled) {
      return;
    }
    _animationsEnabled = enabled;
    for (final _BeeFlight flight in _flights) {
      if (enabled) {
        flight.start();
      } else {
        flight.stop();
      }
    }
  }

  @override
  void dispose() {
    for (final _BeeFlight flight in _flights) {
      flight.dispose();
    }
    _flights.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _syncAnimationsEnabled();
    final bool animated = _animationsEnabled ?? false;
    final double scale = widget.size / 9;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            for (final _BeeFlight flight in _flights)
              _buildBee(flight, constraints, animated, scale),
          ],
        );
      },
    );
  }

  Widget _buildBee(
    _BeeFlight flight,
    BoxConstraints constraints,
    bool animated,
    double scale,
  ) {
    final bool incoming = flight.direction == _BeeDirection.incoming;

    // Start position (percentages of the container). Out-bees are anchored
    // from the bottom, so their top comes from the bottom edge.
    final double leftPct = 4 + flight.beeIndex * 18;
    final double topPct = incoming
        ? 34 + (flight.beeIndex % 3) * 15
        : 100 - (34 + (flight.beeIndex % 3) * 15);

    final double left = constraints.maxWidth * leftPct / 100;
    final double top = constraints.maxHeight * topPct / 100;

    return AnimatedBuilder(
      animation: flight,
      builder: (BuildContext context, Widget? child) {
        // When animations are disabled the controllers are stopped at 0, so
        // these evaluate to the flight's start position.
        final Offset translate = flight.translate * scale;
        final double rotateDeg = flight.rotateDeg;
        final double opacity = incoming ? flight.opacity : 1.0;

        return Positioned(
          left: left + translate.dx,
          top: top + translate.dy,
          child: Opacity(
            opacity: opacity,
            child: Transform.rotate(
              angle: rotateDeg * math.pi / 180,
              child: _BeeVisual(
                incoming: incoming,
                size: widget.size,
                flap: flight.flap,
                animateFlap: animated,
              ),
            ),
          ),
        );
      },
    );
  }
}

enum _BeeDirection { incoming, outgoing }

/// One bee's repeating flight: a single flight controller (drives translate +
/// rotate + opacity through a stagger [Interval]) plus an independent 0.28 s
/// ALTERNATE flap controller. Exposed as a [Listenable] so one
/// [AnimatedBuilder] rebuilds for both.
class _BeeFlight extends ChangeNotifier {
  _BeeFlight._({
    required this.beeIndex,
    required this.direction,
    required AnimationController flightController,
    required this.flap,
    required CurvedAnimation pathProgress,
  })  : _flight = flightController,
        _pathProgress = pathProgress {
    _flight.addListener(notifyListeners);
    flap.addListener(notifyListeners);
  }

  factory _BeeFlight.of({
    required TickerProvider vsync,
    required int beeIndex,
    required _BeeDirection direction,
  }) {
    final bool incoming = direction == _BeeDirection.incoming;

    // Per-bee timing: duration 4.4 + 0.55*i s, delay 0.9*i s, linear, infinite.
    final double flightDuration = 4.4 + 0.55 * beeIndex;
    final double delay = 0.9 * beeIndex;
    // Total controller period = delay + flight; the [Interval] below holds the
    // bee at its start position during the delay (stagger).
    final double total = flightDuration + delay;

    final AnimationController flight = AnimationController(
      vsync: vsync,
      duration: Duration(milliseconds: (total * 1000).round()),
    );

    // 0.28 s ease-in-out ALTERNATE wing flap.
    final AnimationController flap = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 280),
    );

    final double delayFrac = delay / total;
    final CurvedAnimation pathProgress = CurvedAnimation(
      parent: flight,
      curve: Interval(delayFrac, 1.0, curve: Curves.linear),
    );

    return _BeeFlight._(
      beeIndex: beeIndex,
      direction: direction,
      flightController: flight,
      flap: flap,
      pathProgress: pathProgress,
    )
      .._translateAnim = _translateTween(incoming).animate(pathProgress)
      .._rotateAnim = _rotateTween(incoming).animate(pathProgress)
      .._opacityAnim =
          incoming ? _opacityTween().animate(pathProgress) : null;
  }

  final int beeIndex;
  final _BeeDirection direction;
  final AnimationController _flight;
  final CurvedAnimation _pathProgress;
  late final Animation<Offset> _translateAnim;
  late final Animation<double> _rotateAnim;
  late final Animation<double>? _opacityAnim;

  /// The 0.28 s ALTERNATE wing flap controller (value 0→1, reversing).
  final AnimationController flap;

  /// Current flight translate offset (start offset while stopped at 0).
  Offset get translate => _translateAnim.value;

  /// Current flight rotation in degrees.
  double get rotateDeg => _rotateAnim.value;

  /// Current in-bee opacity (1.0 for out-bees, which never fade).
  double get opacity => _opacityAnim?.value ?? 1.0;

  /// Starts both repeating loops (infinite; flap alternates).
  void start() {
    _flight.repeat();
    flap.repeat(reverse: true);
  }

  /// Stops both loops and parks the flight at its start position.
  void stop() {
    _flight.stop();
    flap.stop();
    _flight.value = 0;
    flap.value = 0;
  }

  @override
  void dispose() {
    _flight.removeListener(notifyListeners);
    flap.removeListener(notifyListeners);
    _pathProgress.dispose();
    _flight.dispose();
    flap.dispose();
    super.dispose();
  }
}

/// TweenSequence over the flight progress producing translate offsets.
TweenSequence<Offset> _translateTween(bool incoming) {
  return incoming
      ? TweenSequence<Offset>(<TweenSequenceItem<Offset>>[
          // (-26,34) → (26,10) @62% → (58,-10)
          TweenSequenceItem<Offset>(
            tween: Tween<Offset>(
              begin: const Offset(-26, 34),
              end: const Offset(26, 10),
            ),
            weight: 0.62,
          ),
          TweenSequenceItem<Offset>(
            tween: Tween<Offset>(
              begin: const Offset(26, 10),
              end: const Offset(58, -10),
            ),
            weight: 0.38,
          ),
        ])
      : TweenSequence<Offset>(<TweenSequenceItem<Offset>>[
          // (34,-6) → (2,16) @58% → (-30,38)
          TweenSequenceItem<Offset>(
            tween: Tween<Offset>(
              begin: const Offset(34, -6),
              end: const Offset(2, 16),
            ),
            weight: 0.58,
          ),
          TweenSequenceItem<Offset>(
            tween: Tween<Offset>(
              begin: const Offset(2, 16),
              end: const Offset(-30, 38),
            ),
            weight: 0.42,
          ),
        ]);
}

/// TweenSequence producing rotation degrees: in −14°→6°→10°, out 8°→−6°→−16°.
TweenSequence<double> _rotateTween(bool incoming) {
  return incoming
      ? TweenSequence<double>(<TweenSequenceItem<double>>[
          TweenSequenceItem<double>(
            tween: Tween<double>(begin: -14, end: 6),
            weight: 0.62,
          ),
          TweenSequenceItem<double>(
            tween: Tween<double>(begin: 6, end: 10),
            weight: 0.38,
          ),
        ])
      : TweenSequence<double>(<TweenSequenceItem<double>>[
          TweenSequenceItem<double>(
            tween: Tween<double>(begin: 8, end: -6),
            weight: 0.58,
          ),
          TweenSequenceItem<double>(
            tween: Tween<double>(begin: -6, end: -16),
            weight: 0.42,
          ),
        ]);
}

/// In-bee opacity: 0→1 @18%, hold, →fade from 86% (design.md Motion appendix).
TweenSequence<double> _opacityTween() {
  return TweenSequence<double>(<TweenSequenceItem<double>>[
    TweenSequenceItem<double>(
      tween: Tween<double>(begin: 0, end: 1),
      weight: 0.18,
    ),
    TweenSequenceItem<double>(
      tween: Tween<double>(begin: 1, end: 1),
      weight: 0.68,
    ),
    TweenSequenceItem<double>(
      tween: Tween<double>(begin: 1, end: 0),
      weight: 0.14,
    ),
  ]);
}

/// The static bee artwork: 9×6 r4 body + 2×4 stripe + 6×4 flapping wing,
/// scaled by [size]/9. Colours depend on [incoming] (amber vs cream).
class _BeeVisual extends StatelessWidget {
  const _BeeVisual({
    required this.incoming,
    required this.size,
    required this.flap,
    required this.animateFlap,
  });

  final bool incoming;
  final double size;
  final Animation<double> flap;
  final bool animateFlap;

  @override
  Widget build(BuildContext context) {
    final double s = size / 9; // scale from authored 9-wide body
    final Color body =
        incoming ? const Color(0xFF4A3520) : const Color(0xFFF0DFC4);
    final Color stripe =
        incoming ? const Color(0xFFFFD972) : const Color(0xFF6E4826);
    final Color wing = Colors.white.withValues(
      alpha: incoming ? 0.80 : 0.55,
    );

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