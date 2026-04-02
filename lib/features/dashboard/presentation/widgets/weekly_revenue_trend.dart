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
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weekly Revenue Trend',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(Icons.show_chart, color: colorScheme.primary),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: SizedBox(
              height: 200,
              child: CustomPaint(
                size: const Size(double.infinity, 200),
                painter: _LineChartPainter(
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                  data: [5, 8, 6, 12, 15, 18, 16],
                  labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
                  maxY: 20,
                ),
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

    // Draw grid lines
    final gridPaint = Paint()
      ..color = colorScheme.outlineVariant.withValues(alpha: 0.4)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const horizontalSteps = 4;
    for (int i = 0; i <= horizontalSteps; i++) {
      final y = topPadding + chartHeight - (i * chartHeight / horizontalSteps);
      _drawDashedLine(canvas, Offset(0, y), Offset(chartWidth, y), gridPaint);
    }

    // Calculate points
    final spanX = chartWidth / (data.length > 1 ? data.length - 1 : 1);
    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = i * spanX;
      final y = topPadding + chartHeight - (data[i] / maxY * chartHeight);
      points.add(Offset(x, y));
    }

    // Draw gradient area
    final path = Path();
    path.moveTo(points.first.dx, size.height - bottomPadding);
    for (int i = 0; i < points.length; i++) {
      if (i == 0) {
        path.lineTo(points[i].dx, points[i].dy);
      } else {
        final prevX = points[i - 1].dx;
        final prevY = points[i - 1].dy;
        final currX = points[i].dx;
        final currY = points[i].dy;
        final cp1x = prevX + (currX - prevX) / 2;
        final cp1y = prevY;
        final cp2x = cp1x;
        final cp2y = currY;
        path.cubicTo(cp1x, cp1y, cp2x, cp2y, currX, currY);
      }
    }
    path.lineTo(points.last.dx, size.height - bottomPadding);
    path.close();

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        colorScheme.primary.withValues(alpha: 0.3),
        colorScheme.primary.withValues(alpha: 0.0),
      ],
    );
    final gradientPaint = Paint()
      ..shader = gradient.createShader(Rect.fromLTWH(0, topPadding, chartWidth, chartHeight));
    canvas.drawPath(path, gradientPaint);

    // Draw line
    final linePath = Path();
    linePath.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      final prevX = points[i - 1].dx;
      final prevY = points[i - 1].dy;
      final currX = points[i].dx;
      final currY = points[i].dy;
      final cp1x = prevX + (currX - prevX) / 2;
      final cp1y = prevY;
      final cp2x = cp1x;
      final cp2y = currY;
      linePath.cubicTo(cp1x, cp1y, cp2x, cp2y, currX, currY);
    }
    
    final linePaint = Paint()
      ..color = colorScheme.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(linePath, linePaint);

    // Draw points
    final dotPaintOuter = Paint()
      ..color = colorScheme.surface
      ..style = PaintingStyle.fill;
    final dotPaintInner = Paint()
      ..color = colorScheme.primary
      ..style = PaintingStyle.fill;

    for (final point in points) {
      canvas.drawCircle(point, 6, dotPaintOuter);
      canvas.drawCircle(point, 4, dotPaintInner);
    }

    // Draw X-axis labels
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    for (int i = 0; i < labels.length; i++) {
      textPainter.text = TextSpan(
        text: labels[i],
        style: textTheme.labelSmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      );
      textPainter.layout();
      final x = points[i].dx - textPainter.width / 2;
      final y = size.height - bottomPadding + 8;
      textPainter.paint(canvas, Offset(x, y));
    }
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const dashWidth = 4.0;
    const dashSpace = 4.0;
    var currentX = p1.dx;
    while (currentX < p2.dx) {
      final nextX = (currentX + dashWidth) < p2.dx ? (currentX + dashWidth) : p2.dx;
      canvas.drawLine(
        Offset(currentX, p1.dy),
        Offset(nextX, p1.dy),
        paint,
      );
      currentX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.colorScheme != colorScheme ||
           oldDelegate.textTheme != textTheme ||
           !listEquals(oldDelegate.data, data) ||
           !listEquals(oldDelegate.labels, labels) ||
           oldDelegate.maxY != maxY;
  }
}
