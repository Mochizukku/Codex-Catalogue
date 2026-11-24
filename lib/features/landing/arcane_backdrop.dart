import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import '../../core/theme/codex_theme.dart';
import '../../core/theme/codex_tokens.dart';

/// Paints the deep nocturnal fantasy backdrop, vignette, ambient nebula glows,
/// and parallax starfield behind the landing screen.
class ArcaneBackdrop extends StatelessWidget {
  const ArcaneBackdrop({
    super.key,
    required this.animation,
    this.scrollOffset,
  });

  final Animation<double> animation;
  final ValueListenable<double>? scrollOffset;

  @override
  Widget build(BuildContext context) {
    final p = context.codex;
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _ArcaneBackdropPainter(
            progress: animation,
            scrollOffset: scrollOffset,
            palette: p,
            cursedViolet: AnomalyClass.cursed.color,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

/// Paints the rotating Runic Astrolabe Seal and luminous core aura, designed
/// to sit centered directly behind the transparent Codex emblem.
class ArcaneSealRing extends StatelessWidget {
  const ArcaneSealRing({
    super.key,
    required this.animation,
    this.size = 350,
  });

  final Animation<double> animation;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.codex;
    final safeSize = math.max(0.0, size);
    return IgnorePointer(
      child: RepaintBoundary(
        child: SizedBox(
          width: safeSize,
          height: safeSize,
          child: CustomPaint(
            painter: _ArcaneSealPainter(
              progress: animation,
              palette: p,
              cursedViolet: AnomalyClass.cursed.color,
            ),
          ),
        ),
      ),
    );
  }
}

class _ArcaneBackdropPainter extends CustomPainter {
  _ArcaneBackdropPainter({
    required this.progress,
    required this.scrollOffset,
    required this.palette,
    required this.cursedViolet,
  }) : super(
         repaint: scrollOffset == null
             ? progress
             : Listenable.merge([progress, scrollOffset]),
       );

  final Animation<double> progress;
  final ValueListenable<double>? scrollOffset;
  final CodexPalette palette;
  final Color cursedViolet;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final t = progress.value;
    final pulse = 0.5 + 0.5 * math.sin(t * math.pi * 2);
    final isDark = palette.mode == CodexThemeMode.dark;
    final scroll = scrollOffset?.value ?? 0.0;

    final baseColors = isDark
        ? const [
            Color(0xFF09060E),
            Color(0xFF150D20),
            Color(0xFF110D12),
            Color(0xFF070509),
          ]
        : [
            palette.background,
            Color.lerp(palette.background, cursedViolet, 0.08)!,
            palette.surface,
            palette.background,
          ];
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(size.width * 0.4, size.height),
          baseColors,
          const [0.0, 0.38, 0.72, 1.0],
        ),
    );

    final heroGlowCenter = Offset(
      size.width * 0.5,
      size.height * 0.38 - scroll * 0.30,
    );
    final heroGlowRadius = math.min(size.width * 0.78, 380.0);
    canvas.drawCircle(
      heroGlowCenter,
      heroGlowRadius,
      Paint()
        ..shader = ui.Gradient.radial(
          heroGlowCenter,
          heroGlowRadius,
          [
            cursedViolet.withValues(alpha: (isDark ? 0.22 : 0.11) + 0.05 * pulse),
            palette.accent.withValues(alpha: isDark ? 0.09 : 0.06),
            Colors.transparent,
          ],
          const [0.0, 0.48, 1.0],
        ),
    );

    final lowerGlowCenter = Offset(
      size.width * 0.5,
      size.height * 0.85 - scroll * 0.15,
    );
    final lowerGlowRadius = size.longestSide * 0.55;
    canvas.drawCircle(
      lowerGlowCenter,
      lowerGlowRadius,
      Paint()
        ..shader = ui.Gradient.radial(
          lowerGlowCenter,
          lowerGlowRadius,
          [
            const Color(0xFF5D2D91).withValues(alpha: isDark ? 0.24 : 0.09),
            cursedViolet.withValues(alpha: isDark ? 0.10 : 0.04),
            Colors.transparent,
          ],
          const [0.0, 0.55, 1.0],
        ),
    );

    _drawStarfield(canvas, size, t, scroll, isDark);

    if (isDark) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..shader = ui.Gradient.radial(
            Offset(size.width * 0.5, size.height * 0.45),
            size.longestSide * 0.75,
            [
              Colors.transparent,
              const Color(0xFF040207).withValues(alpha: 0.62),
            ],
            const [0.45, 1.0],
          ),
      );
    }
  }

  void _drawStarfield(
    Canvas canvas,
    Size size,
    double t,
    double scroll,
    bool isDark,
  ) {
    final starPaint = Paint()..style = PaintingStyle.fill;
    final parallaxShift = (scroll * 0.08) % size.height;
    for (var i = 0; i < 28; i++) {
      final fx = (i * 0.381966) % 1.0;
      final fy = (i * 0.754877) % 1.0;
      final y = (size.height * fy - parallaxShift) % size.height;
      final twinkle =
          0.35 + 0.65 * (0.5 + 0.5 * math.sin(t * math.pi * 4 + i * 1.3));
      final r = (i % 4 == 0) ? 1.8 : 1.05;
      final color = (i % 3 == 0) ? cursedViolet : palette.accent;
      starPaint.color = color.withValues(alpha: (isDark ? 0.42 : 0.25) * twinkle);
      canvas.drawCircle(Offset(size.width * fx, y), r, starPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ArcaneBackdropPainter oldDelegate) =>
      oldDelegate.palette != palette || oldDelegate.cursedViolet != cursedViolet;
}

class _ArcaneSealPainter extends CustomPainter {
  _ArcaneSealPainter({
    required this.progress,
    required this.palette,
    required this.cursedViolet,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final CodexPalette palette;
  final Color cursedViolet;

  static const _runes = [
    'ᚠ', 'ᚢ', 'ᚦ', 'ᚨ', 'ᚱ', 'ᚲ', 'ᚷ', 'ᚹ',
    'ᚺ', 'ᚾ', 'ᛁ', 'ᛃ', 'ᛇ', 'ᛈ', 'ᛉ', 'ᛊ',
    'ᛏ', 'ᛒ', 'ᛖ', 'ᛗ', 'ᛚ', 'ᛜ', 'ᛞ', 'ᛟ',
  ];

  static final Map<CodexThemeMode, List<TextPainter>> _runeCache = {};

  List<TextPainter> _getRunePainters(bool isDark) {
    return _runeCache.putIfAbsent(palette.mode, () {
      final goldColor = palette.accent.withValues(alpha: isDark ? 0.42 : 0.28);
      final violetColor = cursedViolet.withValues(alpha: isDark ? 0.42 : 0.26);
      return List.generate(_runes.length, (i) {
        return TextPainter(
          text: TextSpan(
            text: _runes[i],
            style: TextStyle(
              fontSize: 11,
              color: i.isEven ? goldColor : violetColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
      });
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final t = progress.value;
    final pulse = 0.5 + 0.5 * math.sin(t * math.pi * 2);
    final isDark = palette.mode == CodexThemeMode.dark;
    final center = Offset(size.width * 0.5, size.height * 0.5);
    final radius = size.shortestSide * 0.5;

    // Luminous ethereal purple & gold aura directly behind the transparent logo
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = ui.Gradient.radial(
          center,
          radius,
          [
            cursedViolet.withValues(alpha: (isDark ? 0.34 : 0.18) + 0.08 * pulse),
            palette.accent.withValues(alpha: (isDark ? 0.16 : 0.10) + 0.04 * pulse),
            cursedViolet.withValues(alpha: isDark ? 0.08 : 0.04),
            Colors.transparent,
          ],
          const [0.0, 0.42, 0.72, 1.0],
        ),
    );

    final goldAlpha = (isDark ? 0.28 : 0.20) + 0.08 * pulse;
    final violetAlpha = (isDark ? 0.34 : 0.20) + 0.10 * pulse;
    final goldPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = palette.accent.withValues(alpha: goldAlpha);
    final violetPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..color = cursedViolet.withValues(alpha: violetAlpha);

    final outerR = radius * 0.94;
    final midR = radius * 0.76;
    final innerR = radius * 0.54;

    canvas.drawCircle(center, outerR, goldPaint);
    canvas.drawCircle(center, outerR - 6, violetPaint);
    canvas.drawCircle(center, midR, goldPaint);
    canvas.drawCircle(center, innerR, violetPaint);

    final angleA = t * math.pi * 0.22;
    final angleB = angleA + math.pi / 4;
    _drawPolygon(canvas, center, midR - 4, 4, angleA, goldPaint);
    _drawPolygon(canvas, center, midR - 4, 4, angleB, violetPaint);

    for (var i = 0; i < 24; i++) {
      final a = angleA * 0.7 + (i * math.pi * 2 / 24);
      final p1 = center + Offset(math.cos(a), math.sin(a)) * (midR + 2);
      final p2 = center +
          Offset(math.cos(a), math.sin(a)) * (midR + (i % 3 == 0 ? 11 : 6));
      canvas.drawLine(p1, p2, i % 3 == 0 ? goldPaint : violetPaint);
    }

    final runePainters = _getRunePainters(isDark);
    for (var i = 0; i < runePainters.length; i++) {
      final a = -angleA * 0.5 + (i * math.pi * 2 / runePainters.length);
      final pos = center +
          Offset(math.cos(a), math.sin(a)) * ((outerR + midR) * 0.5 - 1);
      final tp = runePainters[i];
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(a + math.pi / 2);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }
  }

  void _drawPolygon(
    Canvas canvas,
    Offset center,
    double radius,
    int sides,
    double rotation,
    Paint paint,
  ) {
    final path = Path();
    for (var i = 0; i < sides; i++) {
      final a = rotation + (i * math.pi * 2 / sides);
      final pt = center + Offset(math.cos(a), math.sin(a)) * radius;
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ArcaneSealPainter oldDelegate) =>
      oldDelegate.palette != palette || oldDelegate.cursedViolet != cursedViolet;
}
