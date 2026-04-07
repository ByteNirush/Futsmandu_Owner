import 'package:flutter/material.dart';
import 'package:futsmandu_design_system/core/theme/app_colors.dart' as ds;

class AppColors {
  static const Color seed = ds.AppColors.primary;

  static const Color success = ds.AppColors.success;
  static const Color warning = ds.AppColors.warning;
  static const Color danger = ds.AppColors.error;

  static const Color lightSurface = ds.AppColors.lightSurface;
  static const Color darkSurface = ds.AppColors.darkSurface;
}

class AppColorSchemes {
  static ColorScheme get light => ds.AppColors.lightScheme;

  static ColorScheme get dark => ds.AppColors.darkScheme;
}
