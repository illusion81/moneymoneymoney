// The level-up moment.
//
// This is the three seconds of the demo people actually remember, so it gets
// the animation budget: the number punches in, the XP bar fills, coins count
// up, and light rays sweep behind it. Everything is driven by one controller so
// the beats land in sequence rather than all at once.

import 'dart:math' as math;

import 'package:flutter/material.dart';

class LevelUpOverlay extends StatefulWidget {
  const LevelUpOverlay({
    super.key,
    required this.newLevel,
    required this.xpGained,
    required this.coinsGained,
    this.unlockedLabel,
    this.onDismiss,
  });

  final int newLevel;
  final int xpGained;
  final int coinsGained;

  /// e.g. "New skin unlocked: Jade Pagoda"
  final String? unlockedLabel;
  final VoidCallback? onDismiss;

  /// Convenience: show it over whatever is on screen.
  static Future<void> show(
    BuildContext context, {
    required int newLevel,
    required int xpGained,
    required int coinsGained,
    String? unlockedLabel,
  }) =>
      showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Level up',
        barrierColor: Colors.black54,
        transitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (ctx, _, __) => LevelUpOverlay(
          newLevel: newLevel,
          xpGained: xpGained,
          coinsGained: coinsGained,
          unlockedLabel: unlockedLabel,
          onDismiss: () => Navigator.of(ctx).maybePop(),
        ),
      );

  @override
  State<LevelUpOverlay> createState() => _LevelUpOverlayState();
}

class _LevelUpOverlayState extends State<LevelUpOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2000),
  )..forward();

  // Sequenced beats, all off one controller.
  late final Animation<double> _rays =
      CurvedAnimation(parent: _c, curve: const Interval(0.0, 1.0));
  late final Animation<double> _pop = CurvedAnimation(
      parent: _c, curve: const Interval(0.05, 0.45, curve: Curves.elasticOut));
  late final Animation<double> _bar = CurvedAnimation(
      parent: _c, curve: const Interval(0.35, 0.75, curve: Curves.easeOutCubic));
  late final Animation<double> _coins = CurvedAnimation(
      parent: _c, curve: const Interval(0.5, 0.9, curve: Curves.easeOut));
  late final Animation<double> _unlock = CurvedAnimation(
      parent: _c, curve: const Interval(0.7, 1.0, curve: Curves.easeOut));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    // Honour the OS "reduce motion" setting — spinning rays are exactly what
    // that setting exists for.
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return GestureDetector(
      onTap: widget.onDismiss,
      child: Material(
        color: Colors.transparent,
        child: Center(
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) => Stack(
              alignment: Alignment.center,
              children: [
                if (!reduceMotion)
                  SizedBox(
                    width: 420,
                    height: 420,
                    child: CustomPaint(
                      painter: _RayPainter(
                        turns: _rays.value,
                        colour: scheme.primary.withValues(alpha: 0.18),
                      ),
                    ),
                  ),
                Container(
                  width: 320,
                  padding: const EdgeInsets.fromLTRB(28, 30, 28, 24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('LEVEL UP',
                        style: t.labelLarge?.copyWith(
                          letterSpacing: 3,
                          color: scheme.primary,
                          fontWeight: FontWeight.w700,
                        )),
                    const SizedBox(height: 14),
                    Transform.scale(
                      scale: reduceMotion ? 1 : _pop.value.clamp(0.0, 1.4),
                      child: Container(
                        width: 96,
                        height: 96,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              scheme.primary,
                              scheme.primary.withValues(alpha: 0.65),
                            ],
                          ),
                        ),
                        child: Text('${widget.newLevel}',
                            style: t.displaySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            )),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: reduceMotion ? 1 : _bar.value,
                        minHeight: 10,
                        backgroundColor: scheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation(scheme.primary),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _stat(context, '+${(widget.xpGained * (reduceMotion ? 1 : _bar.value)).round()}', 'XP'),
                        const SizedBox(width: 28),
                        _stat(context,
                            '+${(widget.coinsGained * (reduceMotion ? 1 : _coins.value)).round()}',
                            'coins'),
                      ],
                    ),
                    if (widget.unlockedLabel != null) ...[
                      const SizedBox(height: 18),
                      Opacity(
                        opacity: reduceMotion ? 1 : _unlock.value,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 9),
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.auto_awesome, size: 15),
                            const SizedBox(width: 7),
                            Flexible(
                                child: Text(widget.unlockedLabel!,
                                    style: t.bodySmall)),
                          ]),
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: widget.onDismiss,
                        child: const Text('Nice'),
                      ),
                    ),
                  ]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stat(BuildContext c, String value, String label) => Column(
        children: [
          Text(value,
              style: Theme.of(c)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700)),
          Text(label, style: Theme.of(c).textTheme.bodySmall),
        ],
      );
}

/// Slowly rotating light rays behind the card.
class _RayPainter extends CustomPainter {
  _RayPainter({required this.turns, required this.colour});
  final double turns;
  final Color colour;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..color = colour;
    const rays = 12;
    canvas.save();
    canvas.translate(centre.dx, centre.dy);
    canvas.rotate(turns * math.pi / 3);
    for (var i = 0; i < rays; i++) {
      final path = Path()
        ..moveTo(0, 0)
        ..lineTo(size.width * 0.55, -14)
        ..lineTo(size.width * 0.55, 14)
        ..close();
      canvas.drawPath(path, paint);
      canvas.rotate(2 * math.pi / rays);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RayPainter old) => old.turns != turns;
}
