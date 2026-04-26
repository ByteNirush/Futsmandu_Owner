import 'dart:math' show pow;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:futsmandu_design_system/core/theme/app_typography.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../data/dashboard_controller.dart';

/// Displays a weekly revenue trend bar chart with API-bound data.
class WeeklyRevenueTrend extends StatelessWidget {
  const WeeklyRevenueTrend({
    super.key,
    this.revenue,
    this.isLoading = false,
  });

  /// The weekly revenue data to display. If null/empty, shows empty state.
  final List<DailyRevenue>? revenue;

  /// Whether data is currently loading.
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Handle loading state
    if (isLoading) {
      return AppCard(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, colorScheme, textTheme, 0),
            const SizedBox(height: AppSpacing.xs2),
            SizedBox(
              height: 180,
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final revenueData = revenue ?? [];

    // Handle empty state
    if (revenueData.isEmpty) {
      return AppCard(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, colorScheme, textTheme, 0),
            const SizedBox(height: AppSpacing.xs2),
            SizedBox(
              height: 180,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bar_chart_outlined,
                      size: 48,
                      color: colorScheme.outlineVariant,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'No revenue data yet',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Prepare chart data
    final values = revenueData.map((r) => r.amount).toList();
    final maxY = _calculateMaxY(values);

    // Calculate total weekly revenue
    final totalRevenue = values.reduce((a, b) => a + b);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, colorScheme, textTheme, totalRevenue),
          const SizedBox(height: AppSpacing.xs2),
          _InteractiveBarChart(
            colorScheme: colorScheme,
            textTheme: textTheme,
            data: revenueData,
            maxY: maxY,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
    double totalRevenue,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Weekly Revenue',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: AppFontWeights.bold,
                ),
              ),
              if (totalRevenue > 0)
                Text(
                  _formatCompactAmount(totalRevenue),
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.xxs,
          ),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.trending_up_rounded,
                size: 14,
                color: colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.xxs),
              Text(
                'This week',
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: AppFontWeights.semiBold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatCompactAmount(double amount) {
    if (amount >= 100000) {
      return 'NPR ${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return 'NPR ${(amount / 1000).toStringAsFixed(1)}K';
    }
    return 'NPR ${amount.toStringAsFixed(0)}';
  }

  /// Calculates an appropriate max Y value with nice rounding
  double _calculateMaxY(List<double> values) {
    if (values.isEmpty) return 100;
    final max = values.reduce((a, b) => a > b ? a : b);
    if (max == 0) return 100;

    // Round up to next nice number
    final magnitude = max.toInt().toString().length - 1;
    final base = pow(10, magnitude).toDouble();
    return ((max / base).ceil() * base).toDouble();
  }
}

/// Interactive bar chart with tap-to-show tooltip support
class _InteractiveBarChart extends StatefulWidget {
  const _InteractiveBarChart({
    required this.colorScheme,
    required this.textTheme,
    required this.data,
    required this.maxY,
  });

  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final List<DailyRevenue> data;
  final double maxY;

  @override
  State<_InteractiveBarChart> createState() => _InteractiveBarChartState();
}

class _InteractiveBarChartState extends State<_InteractiveBarChart> {
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: GestureDetector(
        onTapUp: (details) {
          final index = _getIndexFromPosition(details.localPosition.dx);
          if (index != null && index >= 0 && index < widget.data.length) {
            setState(() {
              _hoveredIndex = _hoveredIndex == index ? null : index;
            });
          }
        },
        child: CustomPaint(
          size: const Size(double.infinity, 180),
          painter: _BarChartPainter(
            colorScheme: widget.colorScheme,
            textTheme: widget.textTheme,
            data: widget.data,
            maxY: widget.maxY,
            highlightedIndex: _hoveredIndex,
          ),
        ),
      ),
    );
  }

  int? _getIndexFromPosition(double x) {
    final chartWidth = context.size?.width ?? 0;
    if (chartWidth == 0) return null;
    final spanX = chartWidth / widget.data.length;
    final index = (x / spanX).floor();
    if (index >= 0 && index < widget.data.length) return index;
    return null;
  }
}

class _BarChartPainter extends CustomPainter {
  _BarChartPainter({
    required this.colorScheme,
    required this.textTheme,
    required this.data,
    required this.maxY,
    this.highlightedIndex,
  });

  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final List<DailyRevenue> data;
  final double maxY;
  final int? highlightedIndex;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    const bottomPadding = 28.0;
    const topPadding = 24.0;
    final chartHeight = size.height - bottomPadding - topPadding;
    final chartWidth = size.width;

    // Grid lines (horizontal)
    final gridPaint = Paint()
      ..color = colorScheme.outlineVariant.withValues(alpha: 0.3)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const horizontalSteps = 4;
    for (int i = 0; i <= horizontalSteps; i++) {
      final y = topPadding + chartHeight - (i * chartHeight / horizontalSteps);
      _drawDashedLine(canvas, Offset(0, y), Offset(chartWidth, y), gridPaint);

      // Y-axis labels
      final value = (maxY / horizontalSteps) * i;
      final label = _formatYLabel(value);
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.outline,
            fontSize: 10,
          ),
        ),
        textAlign: TextAlign.right,
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(
        canvas,
        Offset(4, y - tp.height / 2),
      );
    }

    // Bars
    final spanX = chartWidth / data.length;
    final barWidth = spanX * 0.5;

    // Find highest value to highlight
    double currentMax = 0;
    int maxIndex = 0;
    for (int i = 0; i < data.length; i++) {
      if (data[i].amount > currentMax) {
        currentMax = data[i].amount;
        maxIndex = i;
      }
    }

    for (int i = 0; i < data.length; i++) {
      final cx = (i * spanX) + (spanX / 2);
      final height = maxY > 0 ? (data[i].amount / maxY) * chartHeight : 0;
      final yTop = topPadding + chartHeight - height;
      final yBottom = topPadding + chartHeight;

      final isHighlighted = i == highlightedIndex;
      final isMaxValue = i == maxIndex;

      // Bar shadow for highlighted state
      if (isHighlighted) {
        final shadowPaint = Paint()
          ..color = colorScheme.primary.withValues(alpha: 0.2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTRB(
              cx - (barWidth / 2) - 2,
              yTop - 2,
              cx + (barWidth / 2) + 2,
              yBottom + 2,
            ),
            const Radius.circular(8),
          ),
          shadowPaint,
        );
      }

      // Bar fill
      final barPaint = Paint()
        ..color = isHighlighted || isMaxValue
            ? colorScheme.primary
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.9)
        ..style = PaintingStyle.fill;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTRB(cx - (barWidth / 2), yTop, cx + (barWidth / 2), yBottom),
        const Radius.circular(6),
      );

      canvas.drawRRect(rect, barPaint);

      // Value label on top of bar (if highlighted or is max)
      if (isHighlighted || (isMaxValue && highlightedIndex == null)) {
        final valueLabel = data[i].formattedAmount;
        final valueTp = TextPainter(
          text: TextSpan(
            text: valueLabel,
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: AppFontWeights.bold,
              fontSize: 10,
            ),
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        );
        valueTp.layout();
        valueTp.paint(
          canvas,
          Offset(cx - valueTp.width / 2, yTop - valueTp.height - 4),
        );
      }

      // Day labels
      final tp = TextPainter(
        text: TextSpan(
          text: data[i].day,
          style: textTheme.labelSmall?.copyWith(
            color: isHighlighted || isMaxValue
                ? colorScheme.onSurface
                : colorScheme.onSurfaceVariant,
            fontWeight: isHighlighted || isMaxValue
                ? AppFontWeights.semiBold
                : AppFontWeights.regular,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(
        canvas,
        Offset(cx - tp.width / 2, size.height - bottomPadding + 6),
      );
    }
  }

  String _formatYLabel(double value) {
    if (value >= 100000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    }
    return value.toStringAsFixed(0);
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const dashWidth = 4.0;
    const dashSpace = 4.0;
    var x = p1.dx;
    while (x < p2.dx) {
      final end = (x + dashWidth) < p2.dx ? x + dashWidth : p2.dx;
      canvas.drawLine(Offset(x, p1.dy), Offset(end, p1.dy), paint);
      x += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter old) {
    return old.colorScheme != colorScheme ||
        old.textTheme != textTheme ||
        old.highlightedIndex != highlightedIndex ||
        old.maxY != maxY ||
        !listEquals(old.data, data);
  }
}
