import 'package:flutter/material.dart';

/// Warm-porch palette (maintainer call 2026-07-22): espresso grounds and the
/// porch honey/amber family from Front Porch AI's app_colors.dart — no
/// purple-tinted darks anywhere. UI_UX.md §3.4 keeps the warm-day /
/// dark-night pair, tinting whichever scene is active.
abstract final class LlmertaPalette {
  static const brass = Color(0xFFE9C46A); // porch honey
  static const brassDeep = Color(0xFFA97D1E);
  static const amber = Color(0xFFF4A259); // porch amber — primary actions
  static const onAmber = Color(0xFF1A1200);
  static const terracotta = Color(0xFFE29578);
  static const blood = Color(0xFFB53F35);
  static const ink = Color(0xFF171310); // warm espresso
  static const inkRaised = Color(0xFF261E17);
  static const bone = Color(0xFFEFE6D2);
  static const boneDim = Color(0xFFC2B295);
  static const parchment = Color(0xFFF4EAD6);
  static const parchmentRaised = Color(0xFFEADCC0);
  static const dayInk = Color(0xFF33261B);
}

abstract final class LlmertaTheme {
  static ThemeData get night => _base(
    const ColorScheme.dark(
      primary: LlmertaPalette.brass,
      onPrimary: LlmertaPalette.onAmber,
      secondary: LlmertaPalette.boneDim,
      onSecondary: LlmertaPalette.ink,
      secondaryContainer: Color(0xFF3A2E19),
      onSecondaryContainer: LlmertaPalette.brass,
      error: LlmertaPalette.blood,
      onError: LlmertaPalette.bone,
      surface: LlmertaPalette.ink,
      onSurface: LlmertaPalette.bone,
      surfaceContainerHighest: LlmertaPalette.inkRaised,
      outline: LlmertaPalette.boneDim,
    ),
  );

  static ThemeData get day => _base(
    const ColorScheme.light(
      primary: LlmertaPalette.brassDeep,
      onPrimary: LlmertaPalette.parchment,
      secondary: LlmertaPalette.blood,
      onSecondary: LlmertaPalette.parchment,
      secondaryContainer: Color(0xFFE3D2A9),
      onSecondaryContainer: LlmertaPalette.dayInk,
      error: LlmertaPalette.blood,
      onError: LlmertaPalette.parchment,
      surface: LlmertaPalette.parchment,
      onSurface: LlmertaPalette.dayInk,
      surfaceContainerHighest: LlmertaPalette.parchmentRaised,
      outline: LlmertaPalette.brassDeep,
    ),
  );

  static ThemeData _base(ColorScheme scheme) => ThemeData(
    colorScheme: scheme,
    fontFamily: 'LibreFranklin',
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: scheme.onSurface,
      elevation: 0,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: LlmertaPalette.amber,
        foregroundColor: LlmertaPalette.onAmber,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        textStyle: const TextStyle(
          letterSpacing: 1.1,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}
