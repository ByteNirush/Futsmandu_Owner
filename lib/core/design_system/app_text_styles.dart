import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  static TextStyle poppinsTextTheme({
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
  }) {
    return GoogleFonts.poppins(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  // Headings
  static TextStyle h1(ColorScheme scheme) => poppinsTextTheme(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: scheme.onSurface,
  );

  static TextStyle h2(ColorScheme scheme) => poppinsTextTheme(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: scheme.onSurface,
  );

  static TextStyle h3(ColorScheme scheme) => poppinsTextTheme(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: scheme.onSurface,
  );

  // Titles
  static TextStyle titleMd(ColorScheme scheme) => poppinsTextTheme(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: scheme.onSurface,
  );

  static TextStyle titleSm(ColorScheme scheme) => poppinsTextTheme(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: scheme.onSurface,
  );

  // Body
  static TextStyle body(ColorScheme scheme) => poppinsTextTheme(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: scheme.onSurface,
  );

  static TextStyle bodySm(ColorScheme scheme) => poppinsTextTheme(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: scheme.onSurface,
  );

  static TextStyle bodyXs(ColorScheme scheme) => poppinsTextTheme(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: scheme.onSurfaceVariant,
  );

  // Labels
  static TextStyle label(ColorScheme scheme) => poppinsTextTheme(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: scheme.onSurface,
  );

  static TextStyle labelSm(ColorScheme scheme) => poppinsTextTheme(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: scheme.onSurfaceVariant,
  );

  static TextStyle labelXs(ColorScheme scheme) => poppinsTextTheme(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: scheme.onSurfaceVariant,
  );

  static TextTheme textTheme(ColorScheme scheme) {
    final base = GoogleFonts.poppinsTextTheme();
    return base.copyWith(
      headlineMedium: h1(scheme),
      headlineSmall: h2(scheme),
      titleLarge: h3(scheme),
      titleMedium: titleMd(scheme),
      titleSmall: titleSm(scheme),
      bodyLarge: body(scheme),
      bodyMedium: bodySm(scheme),
      bodySmall: bodyXs(scheme),
      labelLarge: label(scheme),
      labelMedium: labelSm(scheme),
      labelSmall: labelXs(scheme),
    );
  }
}
