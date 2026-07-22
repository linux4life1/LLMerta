import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:llmerta_app/theme/theme.dart';

void main() {
  test('night theme carries the noir palette', () {
    final theme = LlmertaTheme.night;
    expect(theme.brightness, Brightness.dark);
    expect(theme.colorScheme.primary, LlmertaPalette.brass);
    expect(theme.colorScheme.error, LlmertaPalette.blood);
    expect(theme.scaffoldBackgroundColor, LlmertaPalette.ink);
    expect(theme.colorScheme.onSurface, LlmertaPalette.bone);
  });

  test('day theme is the warm counterpart of the pair', () {
    final theme = LlmertaTheme.day;
    expect(theme.brightness, Brightness.light);
    expect(theme.scaffoldBackgroundColor, LlmertaPalette.parchment);
    expect(theme.colorScheme.onSurface, LlmertaPalette.dayInk);
    expect(theme.colorScheme.error, LlmertaPalette.blood);
  });
}
