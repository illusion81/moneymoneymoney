import 'dart:math';

import 'package:flutter/material.dart';

import 'finance_pillars.dart';
import 'pixel_tree_painter.dart';
import 'tree_generator.dart';

/// The central tree: generated from the pillars, grown in once on mount.
///
/// Draw-only; the subtree is wrapped in [IgnorePointer].
class FinanceTreeView extends StatefulWidget {
  const FinanceTreeView({
    super.key,
    required this.pillars,
    this.seed = 1,
    this.growDuration = const Duration(seconds: 4),
  });

  final FinancePillars pillars;

  /// Same seed plus same pillars gives the same tree, every time.
  final int seed;

  final Duration growDuration;

  @override
  State<FinanceTreeView> createState() => _FinanceTreeViewState();
}

class _FinanceTreeViewState extends State<FinanceTreeView>
    with SingleTickerProviderStateMixin {
  static const Size _design = Size(200, 240);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.growDuration,
  )..forward();

  late List<TreeSegment> _segments = _build();

  List<TreeSegment> _build() => const TreeGenerator().generate(
    pillars: widget.pillars,
    random: Random(widget.seed),
    canvasSize: _design,
  );

  @override
  void didUpdateWidget(FinanceTreeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Regrow only when the tree would actually differ.
    if (oldWidget.seed != widget.seed ||
        oldWidget.pillars.health != widget.pillars.health) {
      _segments = _build();
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.pillars.isWithered
        ? const TreePalette.withered()
        : const TreePalette.healthy();

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: PixelTreePainter(
            segments: _segments,
            progress: _controller.value,
            palette: palette,
            designSize: _design,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}