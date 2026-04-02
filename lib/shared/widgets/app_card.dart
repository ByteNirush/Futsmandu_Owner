import 'package:flutter/material.dart';

import '../../core/design_system/app_radius.dart';
import '../../core/design_system/app_shadows.dart';
import '../../core/design_system/app_spacing.dart';

/// A card widget with a subtle press-down scale animation.
/// Every tappable card in the app benefits automatically.
class AppCard extends StatefulWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.cardPadding),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 100),
    lowerBound: 0.0,
    upperBound: 1.0,
  );

  late final Animation<double> _scale = Tween<double>(
    begin: 1.0,
    end: 0.97,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

  void _onTapDown(TapDownDetails _) {
    if (widget.onTap != null) _controller.forward();
  }

  void _onTapUp(TapUpDetails _) => _controller.reverse();
  void _onTapCancel() => _controller.reverse();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(AppRadius.lg);

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(
          scale: _scale.value,
          child: child,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: radius,
            border: Border.all(color: colorScheme.outlineVariant),
            boxShadow: AppShadows.card(colorScheme),
          ),
          child: Material(
            color: colorScheme.surface.withValues(alpha: 0),
            borderRadius: radius,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: radius,
              child: Padding(padding: widget.padding, child: widget.child),
            ),
          ),
        ),
      ),
    );
  }
}
