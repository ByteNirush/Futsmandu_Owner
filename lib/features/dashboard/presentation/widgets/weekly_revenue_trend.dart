import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:futsmandu_design_system/core/theme/app_typography.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';

class WeeklyRevenueTrend extends StatelessWidget {
  const WeeklyRevenueTrend({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Weekly Revenue',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: AppFontWeights.bold,
                  ),
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
          ),
          const SizedBox(height: AppSpacing.xs2),
          SizedBox(
            height: 180,
            child: CustomPaint(
              size: const Size(double.infinity, 180),
              painter: _BarChartPainter(
                colorScheme: colorScheme,
                textTheme: textTheme,
                data: [5, 8, 6, 12, 15, 18, 16],
                labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
                maxY: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  _BarChartPainter({
    required this.colorScheme,
    required this.textTheme,
    required this.data,
    required this.labels,
    required this.maxY,
  });

  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final List<double> data;
  final List<String> labels;
  final double maxY;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    const bottomPadding = 24.0;
    const topPadding = 8.0;
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
    }

    // Bars
    final spanX = chartWidth / data.length;
    final barWidth = spanX * 0.45; // 45% of available span width
    
    // Find today/highest to highlight. I'll highlight the max value as "current/best".
    double currentMax = 0;
    int maxIndex = -1;
    for (int i = 0; i < data.length; i++) {
      if (data[i] > currentMax) {
        currentMax = data[i];
        maxIndex = i;
      }
    }

    for (int i = 0; i < data.length; i++) {
      // Bar center
      final cx = (i * spanX) + (spanX / 2);
      final height = (data[i] / maxY) * chartHeight;
      final yTop = topPadding + chartHeight - height;
      final yBottom = topPadding + chartHeight;

      final isHiglighted = i == maxIndex;
      
      final barPaint = Paint()
        ..color = isHiglighted 
            ? colorScheme.primary 
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.8)
        ..style = PaintingStyle.fill;
        
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTRB(cx - (barWidth / 2), yTop, cx + (barWidth / 2), yBottom),
        const Radius.circular(6), // Soft rounded tops
      );
      
      canvas.drawRRect(rect, barPaint);

      // Labels
      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: textTheme.labelSmall?.copyWith(
            color: isHiglighted 
                ? colorScheme.onSurface 
                : colorScheme.onSurfaceVariant,
            fontWeight: isHiglighted ? AppFontWeights.bold : AppFontWeights.regular,
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
        !listEquals(old.data, data) ||
        !listEquals(old.labels, labels) ||
        old.maxY != maxY;
  }
}
