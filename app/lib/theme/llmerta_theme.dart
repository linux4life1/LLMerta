import 'package:flutter/material.dart';

/// Noir palette shared with the showcase artifact; UI_UX.md §3.4 requires the
/// warm-day / dark-night pair below, tinting whichever scene is active.
abstract final class LlmertaPalette {
  static const brass = Color(0xFFD4AB2E);
  static const brassDeep = Color(0xFF8C6F1E);
  static const blood = Color(0xFFB53F35);
  static const ink = Color(0xFF0E0A14);
  static const inkRaised = Color(0xFF1C1526);
  static const bone = Color(0xFFEFE6D2);
  static const boneDim = Color(0xFFB8AC94);
  static const parchment = Color(0xFFF4EAD6);
  static const parchmentRaised = Color(0xFFEADCC0);
  static const dayInk = Color(0xFF2B2133);
}

abstract final class LlmertaTheme {
  static ThemeData get night => _base(
    const ColorScheme.dark(
      primary: LlmertaPalette.brass,
      onPrimary: LlmertaPalette.ink,
      secondary: LlmertaPalette.boneDim,
      onSecondary: LlmertaPalette.ink,
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
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: scheme.onSurface,
      elevation: 0,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        textStyle: const TextStyle(
          letterSpacing: 1.1,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}
