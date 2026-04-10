import 'package:flutter/material.dart';

import '../../core/design_system/app_spacing.dart';

/// Animated shimmer skeleton shown while screens load.
/// Uses a single [AnimationController] for all items — efficient and smooth.
class LoadingSkeleton extends StatefulWidget {
  const LoadingSkeleton({super.key, this.items = 5});

  final int items;

  @override
  State<LoadingSkeleton> createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<LoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  // Staggered heights give the skeleton a more realistic shape
  static const _heights = [80.0, 72.0, 88.0, 76.0, 84.0];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final baseColor = colorScheme.surfaceContainerHighest;
    final shimmerColor = colorScheme.surface;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.sm),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.items,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (_, index) {
            final height = _heights[index % _heights.length];
            return ShaderMask(
              blendMode: BlendMode.srcATop,
              shaderCallback: (bounds) {
                return LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [baseColor, shimmerColor, baseColor],
                  stops: [
                    (_controller.value - 0.3).clamp(0.0, 1.0),
                    _controller.value.clamp(0.0, 1.0),
                    (_controller.value + 0.3).clamp(0.0, 1.0),
                  ],
                ).createShader(bounds);
              },
              child: Container(
                height: height,
                decoration: BoxDecoration(
                  color: baseColor,
                  borderRadius: BorderRadius.circular(AppSpacing.radius),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
