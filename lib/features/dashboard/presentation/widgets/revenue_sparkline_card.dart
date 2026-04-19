import 'package:flutter/material.dart';
import 'package:futsmandu_design_system/core/theme/app_typography.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';

class RevenueSparklineCard extends StatelessWidget {
  const RevenueSparklineCard({
    super.key,
    required this.title,
    required this.value,
    this.sparklineData = const [2, 4, 3, 6, 5, 8, 10], // Sample high-growth data
  });

  final String title;
  final String value;
  final List<double> sparklineData;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: AppFontWeights.regular,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: AppFontWeights.bold,
                    letterSpacing: -1,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 48,
              child: CustomPaint(
                painter: _SparklinePainter(
                  color: colorScheme.primary,
                  data: sparklineData,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({
    required this.color,
    required this.data,
  });

  final Color color;
  final List<double> data;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final double maxVal = data.reduce((a, b) => a > b ? a : b);
    final double minVal = data.reduce((a, b) => a < b ? a : b);
    final double range = maxVal - minVal == 0 ? 1 : maxVal - minVal;

    final spanX = size.width / (data.length > 1 ? data.length - 1 : 1);
    final points = <Offset>[];
    
    for (int i = 0; i < data.length; i++) {
      final x = i * spanX;
      // Normalizing the value and inverting Y (since 0 is top)
      final y = size.height - ((data[i] - minVal) / range * size.height * 0.8) - (size.height * 0.1); 
      points.add(Offset(x, y));
    }

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);
    
    for (int i = 1; i < points.length; i++) {
      final cpx = points[i - 1].dx + (points[i].dx - points[i - 1].dx) / 2;
      path.cubicTo(
        cpx, points[i - 1].dy,
        cpx, points[i].dy,
        points[i].dx, points[i].dy,
      );
    }

    // Paint line
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
      
    // Gradient underneath
    final fillPath = Path.from(path)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();
      
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.2),
          color.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
    
    // Draw dot on last point
    canvas.drawCircle(
      points.last, 
      4, 
      Paint()..color = color..style = PaintingStyle.fill
    );
    canvas.drawCircle(
      points.last, 
      2, 
      Paint()..color = Colors.white..style = PaintingStyle.fill
    );
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.data != data;
  }
}
