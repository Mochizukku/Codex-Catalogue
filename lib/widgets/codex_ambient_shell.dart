import 'dart:ui' as ui;
import 'package:material_ui/material_ui.dart';
import '../core/theme/codex_theme.dart';
import '../core/theme/codex_tokens.dart';

/// Lightweight ambient background for Dashboard & secondary screens:
/// renders a nocturnal violet-obsidian vignette (or warm parchment gradient)
/// with subtle static corner mist without per-frame animation overhead.
class CodexAmbientBackground extends StatelessWidget {
  const CodexAmbientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.codex;
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _AmbientBackdropPainter(
                  palette: p,
                  cursedViolet: AnomalyClass.cursed.color,
                ),
                size: Size.infinite,
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _AmbientBackdropPainter extends CustomPainter {
  _AmbientBackdropPainter({
    required this.palette,
    required this.cursedViolet,
  });

  final CodexPalette palette;
  final Color cursedViolet;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final isDark = palette.mode == CodexThemeMode.dark;

    final baseColors = isDark
        ? const [
            Color(0xFF0A0710),
            Color(0xFF130D1B),
            Color(0xFF120F0B),
            Color(0xFF09060D),
          ]
        : [
            palette.background,
            Color.lerp(palette.background, cursedViolet, 0.05)!,
            palette.surface.withValues(alpha: 0.7),
            palette.background,
          ];

    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(size.width * 0.45, size.height),
          baseColors,
          const [0.0, 0.35, 0.72, 1.0],
        ),
    );

    // Subtle static corner mist plumes
    final mistAlpha = isDark ? 0.14 : 0.07;
    _drawCornerGlow(
      canvas,
      Offset(size.width * 0.12, size.height * 0.10),
      size.shortestSide * 0.48,
      cursedViolet.withValues(alpha: mistAlpha),
    );
    _drawCornerGlow(
      canvas,
      Offset(size.width * 0.88, size.height * 0.86),
      size.shortestSide * 0.56,
      const Color(0xFF5D2D91).withValues(alpha: mistAlpha * 1.15),
    );
    _drawCornerGlow(
      canvas,
      Offset(size.width * 0.82, size.height * 0.16),
      size.shortestSide * 0.36,
      palette.accent.withValues(alpha: isDark ? 0.06 : 0.05),
    );
  }

  void _drawCornerGlow(
    Canvas canvas,
    Offset center,
    double radius,
    Color color,
  ) {
    if (radius <= 0) return;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = ui.Gradient.radial(
          center,
          radius,
          [color, color.withValues(alpha: color.a * 0.35), Colors.transparent],
          const [0.0, 0.5, 1.0],
        ),
    );
  }

  @override
  bool shouldRepaint(covariant _AmbientBackdropPainter oldDelegate) =>
      oldDelegate.palette != palette || oldDelegate.cursedViolet != cursedViolet;
}

/// Shared translucent grimoire surface card with subtle arcane edge glow.
class CodexSectionCard extends StatelessWidget {
  const CodexSectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(15),
    this.glowColor,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? glowColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final p = context.codex;
    final isDark = p.mode == CodexThemeMode.dark;
    final effectiveGlow = glowColor ?? AnomalyClass.cursed.color;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: p.surface.withValues(alpha: isDark ? 0.84 : 0.92),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor ?? p.border),
        boxShadow: [
          BoxShadow(
            color: effectiveGlow.withValues(alpha: isDark ? 0.09 : 0.05),
            blurRadius: 18,
            spreadRadius: 0.5,
          ),
        ],
      ),
      child: child,
    );
  }
}
