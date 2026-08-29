import 'package:flutter/material.dart';

import '../services/savings_stats_service.dart';

/// A bar chart of the running "surplus assets" total (see
/// [computeSavingsSeries]). A single series, so no legend — the title above
/// this widget names it. Bars are colored by sign (saved vs. overspent), and
/// tapping a bar shows its exact value.
class SavingsChart extends StatefulWidget {
  const SavingsChart({
    super.key,
    required this.points,
    this.positiveColor = const Color(0xff2f7d50),
    this.negativeColor = const Color(0xff8a6a4f),
  });

  final List<SavingsPoint> points;
  final Color positiveColor;
  final Color negativeColor;

  @override
  State<SavingsChart> createState() => _SavingsChartState();
}

const double _chartHeight = 160;
const double _leftPad = 40;
const double _rightPad = 12;
const double _topPad = 20;
const double _bottomPad = 22;

class _SavingsChartState extends State<SavingsChart> {
  int? _selectedIndex;

  @override
  void didUpdateWidget(covariant SavingsChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The points list is replaced wholesale whenever the underlying data
    // (e.g. the selected stats period) changes, so a stale index could
    // otherwise point past the end of a shorter new list.
    if (widget.points != oldWidget.points) {
      _selectedIndex = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.points.isEmpty) {
      return const SizedBox(
        height: _chartHeight,
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'No savings data yet — check in on the Forest tab to start tracking.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final selected = _selectedIndex != null
            ? widget.points[_selectedIndex!]
            : null;

        return SizedBox(
          height: _chartHeight,
          width: width,
          child: Stack(
            children: [
              GestureDetector(
                key: const Key('savings-chart-canvas'),
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) =>
                    _selectNearest(details.localPosition.dx, width),
                onPanUpdate: (details) =>
                    _selectNearest(details.localPosition.dx, width),
                child: CustomPaint(
                  size: Size(width, _chartHeight),
                  painter: _SavingsBarPainter(
                    points: widget.points,
                    positiveColor: widget.positiveColor,
                    negativeColor: widget.negativeColor,
                    selectedIndex: _selectedIndex,
                  ),
                ),
              ),
              if (selected != null)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    alignment: Alignment.center,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: selected.cumulativeSaved >= 0
                            ? widget.positiveColor
                            : widget.negativeColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${selected.label} · ${selected.cumulativeSaved.toStringAsFixed(0)} saved',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _selectNearest(double localX, double width) {
    final points = widget.points;
    final slotWidth = (width - _leftPad - _rightPad) / points.length;
    final slotIndex = ((localX - _leftPad) / slotWidth).clamp(
      0.0,
      points.length - 1.0,
    );
    setState(() => _selectedIndex = slotIndex.round());
  }
}

class _SavingsBarPainter extends CustomPainter {
  const _SavingsBarPainter({
    required this.points,
    required this.positiveColor,
    required this.negativeColor,
    required this.selectedIndex,
  });

  final List<SavingsPoint> points;
  final Color positiveColor;
  final Color negativeColor;
  final int? selectedIndex;

  static const double _cornerRadius = 4;
  static const double _barGap = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final values = points.map((p) => p.cumulativeSaved).toList();
    var minValue = values.reduce((a, b) => a < b ? a : b);
    var maxValue = values.reduce((a, b) => a > b ? a : b);
    // Always include zero — bars are anchored to the "broke even" baseline.
    minValue = minValue > 0 ? 0 : minValue;
    maxValue = maxValue < 0 ? 0 : maxValue;
    if (minValue == maxValue) {
      maxValue += 1;
    }

    final plotWidth = size.width - _leftPad - _rightPad;
    final plotHeight = size.height - _topPad - _bottomPad;
    final slotWidth = plotWidth / points.length;
    final barWidth = (slotWidth - _barGap).clamp(4.0, 32.0);
    final baselineY =
        _topPad + plotHeight * (1 - (0 - minValue) / (maxValue - minValue));

    double yFor(double value) =>
        _topPad + plotHeight * (1 - (value - minValue) / (maxValue - minValue));

    double xCenterFor(int index) => _leftPad + slotWidth * (index + 0.5);

    _paintGridlines(canvas, size, minValue, maxValue);
    _paintBars(canvas, values, xCenterFor, yFor, baselineY, barWidth);
    _paintXLabels(canvas, size, xCenterFor);
  }

  void _paintGridlines(
    Canvas canvas,
    Size size,
    double minValue,
    double maxValue,
  ) {
    final gridPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    final labelStyle = TextStyle(
      color: Colors.black.withValues(alpha: 0.45),
      fontSize: 10,
    );

    for (final fraction in [0.0, 0.5, 1.0]) {
      final y = _topPad + (size.height - _topPad - _bottomPad) * (1 - fraction);
      canvas.drawLine(
        Offset(_leftPad, y),
        Offset(size.width - _rightPad, y),
        gridPaint,
      );
      final value = minValue + (maxValue - minValue) * fraction;
      final painter = TextPainter(
        text: TextSpan(text: value.toStringAsFixed(0), style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(canvas, Offset(0, y - painter.height / 2));
    }
  }

  void _paintBars(
    Canvas canvas,
    List<double> values,
    double Function(int) xCenterFor,
    double Function(double) yFor,
    double baselineY,
    double barWidth,
  ) {
    for (var i = 0; i < points.length; i++) {
      final value = values[i];
      final xCenter = xCenterFor(i);
      final valueY = yFor(value);
      final isPositive = value >= 0;
      final top = isPositive ? valueY : baselineY;
      final bottom = isPositive ? baselineY : valueY;
      final radius = Radius.circular(_cornerRadius);

      final rect = Rect.fromLTRB(
        xCenter - barWidth / 2,
        top,
        xCenter + barWidth / 2,
        bottom == top ? top + 1 : bottom,
      );
      final rrect = RRect.fromRectAndCorners(
        rect,
        topLeft: isPositive ? radius : Radius.zero,
        topRight: isPositive ? radius : Radius.zero,
        bottomLeft: isPositive ? Radius.zero : radius,
        bottomRight: isPositive ? Radius.zero : radius,
      );

      final color = isPositive ? positiveColor : negativeColor;
      final paint = Paint()
        ..color = i == selectedIndex ? color : color.withValues(alpha: 0.85);
      canvas.drawRRect(rrect, paint);

      if (i == selectedIndex) {
        canvas.drawRRect(
          rrect,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
    }
  }

  void _paintXLabels(
    Canvas canvas,
    Size size,
    double Function(int) xCenterFor,
  ) {
    final labelStyle = TextStyle(
      color: Colors.black.withValues(alpha: 0.55),
      fontSize: 10,
    );
    final maxLabels = (size.width / 70).floor().clamp(1, points.length);
    final step = (points.length / maxLabels).ceil().clamp(1, points.length);

    for (var i = 0; i < points.length; i += step) {
      final x = xCenterFor(i);
      final painter = TextPainter(
        text: TextSpan(text: points[i].label, style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(
        canvas,
        Offset(
          (x - painter.width / 2).clamp(0, size.width - painter.width),
          size.height - _bottomPad + 6,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SavingsBarPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.positiveColor != positiveColor ||
        oldDelegate.negativeColor != negativeColor;
  }
}
