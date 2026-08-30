import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A breathing beehive avatar (design.md §6 `BreathingHive`; motion appendix
/// `hum` + `spin`).
///
/// The hive is three stacked rounded honey bands whose width grows with
/// [honey] (`26 + min(1, honey/2500) × 20` dp) plus an 8×7 entrance at the
/// bottom centre. It breathes via `hum` (3.4 s ease-in-out: translateY
/// 0→−2→0, rotate −1°→1°→−1°, infinite) and is orbited by 4 px ink-dot bees —
/// tiered by [streak] (≥25 → 3, ≥10 → 2, >0 → 1, 0 → none) — each dot sitting
/// in a full-size square wrapper that spins 360° (linear, infinite,
/// `2.6 + 0.7i` s, one-time start delay `0.9i` s, dot offset `top: 5i − 1` px).
///
/// All controllers are gated on `MediaQuery.disableAnimations`: when reduced
/// motion is requested the hive renders statically.
class BreathingHive extends StatefulWidget {
  const BreathingHive({
    super.key,
    required this.honey,
    required this.streak,
    this.size = 56,
  });

  /// Total honey — drives the hive width.
  final int honey;

  /// Current streak — drives the orbiting-bee count.
  final int streak;

  /// Outer square slot; the hive is centred within it.
  final double size;

  @override
  State<BreathingHive> createState() => _BreathingHiveState();
}

class _BreathingHiveState extends State<BreathingHive>
    with TickerProviderStateMixin {
  // Palette (design.md §1.1 / §6). Quoted inline because this primitive is
  // intentionally self-contained and must not depend on the theme layer.
  static const Color _topBand = Color(0xFFFFD972); // honeyLight
  static const Color _midBand = Color(0xFFF5B322); // honey
  static const Color _bottomBand = Color(0xFFE08C1B); // honeyDeep
  static const Color _entrance = Color(0xFF5A3A20); // brownDeep alternate
  static const Color _bee = Color(0xFF33251A); // ink

  static const Duration _humPeriod = Duration(milliseconds: 3400);
  static const double _bandRadius = 7;
  static const double _entranceSize = 7; // entrance height (8 wide).

  late final AnimationController _humController;
  late final CurvedAnimation _humCurve;
  late final Animation<double> _humTranslateY;
  late final Animation<double> _humRotation;
  late List<AnimationController> _beeControllers;
  final List<Timer> _beeStartTimers = <Timer>[];

  /// Whether reduced motion is requested via `MediaQuery.disableAnimations`.
  /// Defaults to `true` so the first `didChangeDependencies` (which reports
  /// the real value) decides whether any animation is started.
  bool _animationsDisabled = true;

  /// Orbiting-bee count from [BreathingHive.streak]: ≥25 → 3, ≥10 → 2,
  /// >0 → 1, 0 → none (design.md §6).
  int get _beeCount {
    if (widget.streak >= 25) return 3;
    if (widget.streak >= 10) return 2;
    if (widget.streak > 0) return 1;
    return 0;
  }

  /// Hive width in dp — `26 + min(1, honey/2500) × 20` (design.md §6).
  double get _hiveWidth =>
      26 + math.min(1.0, math.max(0, widget.honey) / 2500) * 20;

  @override
  void initState() {
    super.initState();
    _humController = AnimationController(vsync: this, duration: _humPeriod);
    // `hum`: 3.4 s ease-in-out, keyframes 0/100 % at rest, 50 % at the peak.
    _humCurve = CurvedAnimation(
      parent: _humController,
      curve: Curves.easeInOut,
    );
    _humTranslateY = TweenSequence<double>([
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0.0, end: -2.0),
        weight: 50,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: -2.0, end: 0.0),
        weight: 50,
      ),
    ]).animate(_humCurve);
    _humRotation = TweenSequence<double>([
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: -1.0, end: 1.0),
        weight: 50,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1.0, end: -1.0),
        weight: 50,
      ),
    ]).animate(_humCurve);
    _beeControllers = _createBeeControllers(_beeCount);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bool disabled =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (disabled == _animationsDisabled) return;
    _animationsDisabled = disabled;
    if (disabled) {
      _stopAnimations();
    } else {
      _startAnimations();
    }
  }

  @override
  void didUpdateWidget(BreathingHive oldWidget) {
    super.didUpdateWidget(oldWidget);
    final int count = _beeCount;
    if (count == _beeControllers.length) return;
    for (final Timer timer in _beeStartTimers) {
      timer.cancel();
    }
    _beeStartTimers.clear();
    for (final AnimationController controller in _beeControllers) {
      controller.dispose();
    }
    _beeControllers = _createBeeControllers(count);
    if (!_animationsDisabled) {
      _scheduleBeeSpins();
    }
  }

  @override
  void dispose() {
    for (final Timer timer in _beeStartTimers) {
      timer.cancel();
    }
    _humCurve.dispose();
    _humController.dispose();
    for (final AnimationController controller in _beeControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  /// One controller per bee, period `2.6 + 0.7i` s (design.md motion appendix
  /// `spin`).
  List<AnimationController> _createBeeControllers(int count) {
    return List<AnimationController>.generate(count, (int i) {
      final double spinPeriod = 2.6 + 0.7 * i;
      return AnimationController(
        vsync: this,
        duration: Duration(milliseconds: (spinPeriod * 1000).round()),
      );
    });
  }

  void _startAnimations() {
    _humController.repeat();
    _scheduleBeeSpins();
  }

  /// One-time start delay per wrapper: `0.9i` s, then `repeat()` spins it
  /// continuously (design.md motion appendix `spin`).
  void _scheduleBeeSpins() {
    for (int i = 0; i < _beeControllers.length; i++) {
      _beeStartTimers.add(
        Timer(Duration(milliseconds: (0.9 * i * 1000).round()), () {
          if (mounted && !_animationsDisabled) {
            _beeControllers[i].repeat();
          }
        }),
      );
    }
  }

  void _stopAnimations() {
    for (final Timer timer in _beeStartTimers) {
      timer.cancel();
    }
    _beeStartTimers.clear();
    _humController.stop();
    _humController.value = 0;
    for (final AnimationController controller in _beeControllers) {
      controller.stop();
      controller.value = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        // Bees orbit beyond the slot, so keep the stack unclipped.
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: <Widget>[
          _buildHive(),
          for (int i = 0; i < _beeControllers.length; i++) _buildBee(i),
        ],
      ),
    );
  }

  /// The hive body with the `hum` breathing transform applied (static when
  /// reduced motion is requested).
  Widget _buildHive() {
    final Widget body = _buildHiveBody();
    if (_animationsDisabled) return body;
    return AnimatedBuilder(
      animation: _humController,
      builder: (BuildContext context, Widget? child) {
        return Transform.translate(
          offset: Offset(0, _humTranslateY.value),
          child: Transform.rotate(
            angle: _humRotation.value * math.pi / 180,
            child: child,
          ),
        );
      },
      child: body,
    );
  }

  /// The three stacked rounded honey bands plus the bottom-centre entrance.
  /// Bands are 52 % / 76 % / 100 % of the hive width, each 34 % of the hive
  /// height tall, with a 1 px negative overlap between them.
  Widget _buildHiveBody() {
    final double w = _hiveWidth;
    final double h = w * 1.15;
    final double bandH = 0.34 * h;
    final double totalH = 3 * bandH - 2; // two 1 px overlaps.

    Widget band(double width, double top, Color color) {
      return Positioned(
        top: top,
        left: (w - width) / 2,
        width: width,
        height: bandH,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(_bandRadius),
          ),
        ),
      );
    }

    return SizedBox(
      width: w,
      height: totalH,
      child: Stack(
        children: <Widget>[
          band(0.52 * w, 0, _topBand),
          band(0.76 * w, bandH - 1, _midBand),
          band(w, 2 * bandH - 2, _bottomBand),
          // 8×7 entrance at the bottom centre (the handoff specifies no
          // radius, so it is drawn square).
          Positioned(
            top: totalH - _entranceSize,
            left: (w - 8) / 2,
            width: 8,
            height: _entranceSize,
            child: Container(decoration: const BoxDecoration(color: _entrance)),
          ),
        ],
      ),
    );
  }

  /// One orbiting bee: a 4 px ink dot in a full-size square wrapper that
  /// spins 360° around the hive centre (design.md motion appendix `spin`).
  /// The dot is offset `top: 5i − 1` px from the wrapper's top edge (negative
  /// for the first bee), so it is shifted with a [Transform.translate] rather
  /// than padding — negative padding is not allowed.
  Widget _buildBee(int i) {
    final Widget dot = Transform.translate(
      offset: Offset(0, 5 * i - 1),
      child: const Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: 4,
          height: 4,
          child: DecoratedBox(
            decoration: BoxDecoration(color: _bee, shape: BoxShape.circle),
          ),
        ),
      ),
    );
    if (_animationsDisabled) return dot;
    final AnimationController controller = _beeControllers[i];
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, Widget? child) {
        return Transform.rotate(
          angle: 2 * math.pi * controller.value,
          child: child,
        );
      },
      child: dot,
    );
  }
}
