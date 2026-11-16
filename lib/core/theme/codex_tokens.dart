import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

enum CodexThemeMode { dark, light, papyrus }

enum AnomalyClass {
  beneficial('Beneficial', Color(0xFF6FAE7A)),
  harmless('Harmless', Color(0xFF7FA3C7)),
  cursed('Cursed', Color(0xFFA679CF)),
  dangerous('Dangerous', Color(0xFFD0604A));

  const AnomalyClass(this.label, this.color);
  final String label;
  final Color color;

  static AnomalyClass fromString(String? value) =>
      AnomalyClass.values.firstWhere(
        (e) => e.label.toLowerCase() == value?.trim().toLowerCase(),
        orElse: () => AnomalyClass.cursed,
      );
}

@immutable
class CodexPalette extends ThemeExtension<CodexPalette> {
  const CodexPalette({
    required this.mode,
    required this.background,
    required this.surface,
    required this.pillSurface,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
    required this.accent,
    required this.onAccent,
    required this.danger,
  });

  final CodexThemeMode mode;
  final Color background;
  final Color surface;
  final Color pillSurface;
  final Color border;
  final Color textPrimary;
  final Color textMuted;
  final Color accent;
  final Color onAccent;
  final Color danger;

  static const dark = CodexPalette(
    mode: CodexThemeMode.dark,
    background: Color(0xFF120F0B),
    surface: Color(0xFF1D1812),
    pillSurface: Color(0xFF2A2319),
    border: Color(0xFF3B3224),
    textPrimary: Color(0xFFEFE4CC),
    textMuted: Color(0xFFA39676),
    accent: Color(0xFFD2A94C),
    onAccent: Color(0xFF1A1408),
    danger: Color(0xFFD0604A),
  );

  static const light = CodexPalette(
    mode: CodexThemeMode.light,
    background: Color(0xFFF6F1E3),
    surface: Color(0xFFEBE3CD),
    pillSurface: Color(0xFFDDD2B4),
    border: Color(0xFFC9BC97),
    textPrimary: Color(0xFF2B2114),
    textMuted: Color(0xFF6F5F3D),
    accent: Color(0xFF8A6414),
    onAccent: Color(0xFFFFF6DC),
    danger: Color(0xFFD0604A),
  );

  static const papyrus = CodexPalette(
    mode: CodexThemeMode.papyrus,
    background: Color(0xFFE6D3A0),
    surface: Color(0xFFDCC78C),
    pillSurface: Color(0xFFCDB677),
    border: Color(0xFFB59D5C),
    textPrimary: Color(0xFF3A2A10),
    textMuted: Color(0xFF6B5527),
    accent: Color(0xFF7A4F0C),
    onAccent: Color(0xFFFFF2D0),
    danger: Color(0xFFD0604A),
  );

  static CodexPalette forMode(CodexThemeMode mode) => switch (mode) {
    CodexThemeMode.dark => dark,
    CodexThemeMode.light => light,
    CodexThemeMode.papyrus => papyrus,
  };

  @override
  CodexPalette copyWith({
    CodexThemeMode? mode,
    Color? background,
    Color? surface,
    Color? pillSurface,
    Color? border,
    Color? textPrimary,
    Color? textMuted,
    Color? accent,
    Color? onAccent,
    Color? danger,
  }) => CodexPalette(
    mode: mode ?? this.mode,
    background: background ?? this.background,
    surface: surface ?? this.surface,
    pillSurface: pillSurface ?? this.pillSurface,
    border: border ?? this.border,
    textPrimary: textPrimary ?? this.textPrimary,
    textMuted: textMuted ?? this.textMuted,
    accent: accent ?? this.accent,
    onAccent: onAccent ?? this.onAccent,
    danger: danger ?? this.danger,
  );

  @override
  CodexPalette lerp(ThemeExtension<CodexPalette>? other, double t) {
    if (other is! CodexPalette) return this;
    return CodexPalette(
      mode: t < 0.5 ? mode : other.mode,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      pillSurface: Color.lerp(pillSurface, other.pillSurface, t)!,
      border: Color.lerp(border, other.border, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
    );
  }
}

abstract final class CodexTypography {
  static TextStyle screenTitle(Color color) => GoogleFonts.cinzel(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: 0.85,
    color: color,
  );

  static TextStyle dossierTitle(Color color) => GoogleFonts.cinzel(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: color,
  );

  static TextStyle warningHeading(Color color) => GoogleFonts.cinzel(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: color,
  );

  static TextStyle cardTitle(Color color) => GoogleFonts.cormorantGaramond(
    fontSize: 19,
    fontWeight: FontWeight.w600,
    height: 1.15,
    color: color,
  );

  static TextStyle transcript(Color color, {double fontSize = 17}) =>
      GoogleFonts.cormorantGaramond(
        fontSize: fontSize,
        fontWeight: FontWeight.w400,
        height: 1.55,
        color: color,
      );

  static TextStyle textArea(Color color) => GoogleFonts.cormorantGaramond(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: color,
  );

  static TextStyle body(Color color) => GoogleFonts.figtree(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: color,
  );

  static TextStyle button(Color color) => GoogleFonts.figtree(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.45,
    color: color,
  );

  static TextStyle dossierLabel(Color color, {bool active = false}) =>
      GoogleFonts.figtree(
        fontSize: 12,
        fontWeight: active ? FontWeight.w600 : FontWeight.w400,
        height: 1.45,
        color: color,
      );

  static TextStyle chip(Color color) => GoogleFonts.figtree(
    fontSize: 11.5,
    fontWeight: FontWeight.w600,
    height: 1.45,
    color: color,
  );

  static TextStyle metadata(Color color) => GoogleFonts.figtree(
    fontSize: 11.5,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: color,
  );

  static TextStyle artifactId(Color color) => GoogleFonts.figtree(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.45,
    color: color,
  );

  static TextStyle fallbackCaption(Color color) => GoogleFonts.figtree(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.45,
    letterSpacing: 0.66,
    color: color,
  );

  static TextStyle badge(Color color) => GoogleFonts.figtree(
    fontSize: 10.5,
    fontWeight: FontWeight.w600,
    height: 1.45,
    color: color,
  );

  static TextStyle navLabel(Color color, {bool active = false}) =>
      GoogleFonts.figtree(
        fontSize: 10.5,
        fontWeight: active ? FontWeight.w600 : FontWeight.w400,
        height: 1.45,
        color: color,
      );
}
