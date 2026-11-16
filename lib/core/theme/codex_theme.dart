import 'package:material_ui/material_ui.dart';
import 'codex_tokens.dart';

abstract final class CodexTheme {
  static ThemeData build(CodexThemeMode mode) {
    final p = CodexPalette.forMode(mode);
    final isDark = mode == CodexThemeMode.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: p.background,
      colorScheme: ColorScheme(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: p.accent,
        onPrimary: p.onAccent,
        secondary: p.accent,
        onSecondary: p.onAccent,
        error: p.danger,
        onError: Colors.white,
        surface: p.surface,
        onSurface: p.textPrimary,
      ),
      dividerColor: p.border,
      cardTheme: CardThemeData(
        color: p.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(color: p.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surface,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
        hintStyle: CodexTypography.body(p.textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: p.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: p.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: p.accent),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: p.danger),
        ),
      ),
      extensions: [p],
    );
  }
}

extension CodexPaletteContext on BuildContext {
  CodexPalette get codex =>
      Theme.of(this).extension<CodexPalette>() ?? CodexPalette.dark;
}
