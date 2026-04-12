import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
                    fontWeight: FontWeight.w700,
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
                        fontWeight: FontWeight.w600,
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
              painter: _LineChartPainter(
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

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({
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

    // Grid lines
    final gridPaint = Paint()
      ..color = colorScheme.outlineVariant.withValues(alpha: 0.4)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const horizontalSteps = 4;
    for (int i = 0; i <= horizontalSteps; i++) {
      final y = topPadding + chartHeight - (i * chartHeight / horizontalSteps);
      _drawDashedLine(canvas, Offset(0, y), Offset(chartWidth, y), gridPaint);
    }

    // Data points
    final spanX = chartWidth / (data.length > 1 ? data.length - 1 : 1);
    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = i * spanX;
      final y = topPadding + chartHeight - (data[i] / maxY * chartHeight);
      points.add(Offset(x, y));
    }

    // Gradient fill
    final fillPath = Path();
    fillPath.moveTo(points.first.dx, size.height - bottomPadding);
    for (int i = 0; i < points.length; i++) {
      if (i == 0) {
        fillPath.lineTo(points[i].dx, points[i].dy);
      } else {
        final cpx = points[i - 1].dx + (points[i].dx - points[i - 1].dx) / 2;
        fillPath.cubicTo(
          cpx, points[i - 1].dy,
          cpx, points[i].dy,
          points[i].dx, points[i].dy,
        );
      }
    }
    fillPath.lineTo(points.last.dx, size.height - bottomPadding);
    fillPath.close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorScheme.primary.withValues(alpha: 0.28),
            colorScheme.primary.withValues(alpha: 0.0),
          ],
        ).createShader(
          Rect.fromLTWH(0, topPadding, chartWidth, chartHeight),
        ),
    );

    // Line
    final linePath = Path();
    linePath.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      final cpx = points[i - 1].dx + (points[i].dx - points[i - 1].dx) / 2;
      linePath.cubicTo(
        cpx, points[i - 1].dy,
        cpx, points[i].dy,
        points[i].dx, points[i].dy,
      );
    }
    canvas.drawPath(
      linePath,
      Paint()
        ..color = colorScheme.primary
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Data point dots
    final outerDot = Paint()
      ..color = colorScheme.surface
      ..style = PaintingStyle.fill;
    final innerDot = Paint()
      ..color = colorScheme.primary
      ..style = PaintingStyle.fill;

    for (final point in points) {
      canvas.drawCircle(point, 5, outerDot);
      canvas.drawCircle(point, 3.5, innerDot);
    }

    // X-axis labels
    final tp = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    for (int i = 0; i < labels.length; i++) {
      tp.text = TextSpan(
        text: labels[i],
        style: textTheme.labelSmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      );
      tp.layout();
      tp.paint(
        canvas,
        Offset(
          points[i].dx - tp.width / 2,
          size.height - bottomPadding + 6,
        ),
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
  bool shouldRepaint(covariant _LineChartPainter old) {
    return old.colorScheme != colorScheme ||
        old.textTheme != textTheme ||
        !listEquals(old.data, data) ||
        !listEquals(old.labels, labels) ||
        old.maxY != maxY;
  }
}
