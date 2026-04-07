import 'package:flutter/material.dart';
import 'package:futsmandu_design_system/futsmandu_design_system.dart' as ds;

import '../../core/design_system/app_spacing.dart';

/// A card widget with a subtle press-down scale animation.
/// Every tappable card in the app benefits automatically.
class AppCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return ds.AppCard(
      padding: padding,
      onTap: onTap,
      child: child,
    );
  }
}
