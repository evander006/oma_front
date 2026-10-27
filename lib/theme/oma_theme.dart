import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class OmaColors {
  /// Figma home / ОМА. Дом tokens (node 160:3283).
  static const background = Color(0xFFF4F6F8);
  static const white = Color(0xFFFFFFFF);
  static const ink = Color(0xFF172F40);
  static const black = Color(0xFF171717);
  static const muted = Color(0xFF607482);
  static const hint = Color(0xFFB4BBC0);
  static const blue = Color(0xFF0065AE);
  static const blueDark = Color(0xFF073D66);
  static const blueSoft = Color(0xFFEAF3FA);
  static const orange = Color(0xFFFB981E);
  static const cream = Color(0xFFFFF3E3);
  static const line = Color(0xFFDCE4E9);
  static const searchFill = Color(0xFFFFFFFF);
  static const green = Color(0xFF25815A);
  static const greenSoft = Color(0xFFEAF6EF);
  static const danger = Color(0xFFC0392B);
  static const dangerSoft = Color(0xFFFDECEA);
  static const cartRed = Color(0xFFE53935);
}

/// Shared spacing scale (dp).
abstract final class OmaSpace {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

/// Shared corner radii.
abstract final class OmaRadius {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 14.0;
  static const xl = 20.0;
  static const pill = 100.0;
}

abstract final class OmaType {
  static TextStyle _base(double size, FontWeight weight, Color color) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      height: 1.35,
      color: color,
    );
  }

  static TextStyle regular(double size, Color color) =>
      _base(size, FontWeight.w400, color);

  static TextStyle medium(double size, Color color) =>
      _base(size, FontWeight.w500, color);

  static TextStyle semibold(double size, Color color) =>
      _base(size, FontWeight.w600, color);

  static TextStyle bold(double size, Color color) =>
      _base(size, FontWeight.w700, color);
}

ThemeData buildOmaTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: OmaColors.background,
    canvasColor: OmaColors.background,
    cardColor: OmaColors.white,
    splashColor: OmaColors.blue.withValues(alpha: 0.08),
    highlightColor: Colors.transparent,
    colorScheme: ColorScheme.fromSeed(
      seedColor: OmaColors.blue,
      brightness: Brightness.light,
      primary: OmaColors.blue,
      secondary: OmaColors.orange,
      surface: OmaColors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: OmaColors.white,
      foregroundColor: OmaColors.ink,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
  );
}
