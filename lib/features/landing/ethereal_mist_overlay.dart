import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:material_ui/material_ui.dart';
import '../../core/theme/codex_theme.dart';
import '../../core/theme/codex_tokens.dart';

/// Drives the periodic arcane mist & runic animation cycle without blocking
/// widget-test settling, and provides coordinated painters for background and
/// subtle foreground edge wisps.
class LandingAtmosphereController {
  LandingAtmosphereController(TickerProvider vsync)
    : controller = AnimationController(
        vsync: vsync,
        duration: const Duration(milliseconds: 9000),
      );

  final AnimationController controller;
  Timer? _initialDelayTimer;
  Timer? _periodicTimer;
  int cycleSeed = 0;
  bool disableAnimations = false;

  void start(bool Function() isActive) {
    _initialDelayTimer = Timer(
      const Duration(milliseconds: 1600),
      () => _trigger(isActive),
    );
    _periodicTimer = Timer.periodic(
      const Duration(milliseconds: 9800),
      (_) => _trigger(isActive),
    );
  }

  void _trigger(bool Function() isActive) {
    if (!isActive() || disableAnimations) return;
    if (controller.isAnimating) return;
    cycleSeed++;
    controller.forward(from: 0);
  }

  void dispose() {
    _initialDelayTimer?.cancel();
    _periodicTimer?.cancel();
    controller.dispose();
  }
}

/// Renders rich, layered ethereal purple mist, drifting wisps, and rising
/// arcane sparks/runes.
class EtherealMistOverlay extends StatelessWidget {
  const EtherealMistOverlay({
    super.key,
    required this.animation,
    this.seed = 0,
    this.foreground = false,
  });

  final Animation<double> animation;
  final int seed;
  final bool foreground;

  @override
  Widget build(BuildContext context) {
    final p = context.codex;
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _EtherealMistPainter(
            progress: animation,
            cursedViolet: AnomalyClass.cursed.color,
            deepAmethyst: const Color(0xFF5D2D91),
            spectralLavender: const Color(0xFFD6BAFF),
            moteGold: p.accent,
            isDark: p.mode == CodexThemeMode.dark,
            seed: seed,
            foreground: foreground,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _EtherealMistPainter extends CustomPainter {
  _EtherealMistPainter({
    required this.progress,
    required this.cursedViolet,
    required this.deepAmethyst,
    required this.spectralLavender,
    required this.moteGold,
    required this.isDark,
    required this.seed,
    required this.foreground,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final Color cursedViolet;
  final Color deepAmethyst;
  final Color spectralLavender;
  final Color moteGold;
  final bool isDark;
  final int seed;
  final bool foreground;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final t = progress.value;
    final waveEnvelope = t > 0 && t < 1 ? math.sin(t * math.pi) : 0.0;
    final dir = seed.isEven ? 1.0 : -1.0;

    if (!foreground) {
      _paintPersistentFogBanks(canvas, size);
      if (waveEnvelope > 0) {
        _paintRollingMistSurges(canvas, size, t, waveEnvelope, dir);
        _paintArcaneSparks(canvas, size, t, waveEnvelope, dir);
      }
    } else if (waveEnvelope > 0) {
      _paintForegroundWisps(canvas, size, t, waveEnvelope, dir);
    }
  }

  void _paintPersistentFogBanks(Canvas canvas, Size size) {
    final baseAlpha = isDark ? 0.28 : 0.14;
    final banks = [
      (
        center: Offset(size.width * 0.18, size.height * 0.92),
        rx: size.width * 0.58,
        ry: size.height * 0.26,
        color: deepAmethyst,
        alpha: baseAlpha,
      ),
      (
        center: Offset(size.width * 0.82, size.height * 0.88),
        rx: size.width * 0.55,
        ry: size.height * 0.28,
        color: cursedViolet,
        alpha: baseAlpha * 0.85,
      ),
      (
        center: Offset(size.width * 0.12, size.height * 0.14),
        rx: size.width * 0.45,
        ry: size.height * 0.22,
        color: deepAmethyst,
        alpha: baseAlpha * 0.65,
      ),
      (
        center: Offset(size.width * 0.88, size.height * 0.36),
        rx: size.width * 0.42,
        ry: size.height * 0.24,
        color: cursedViolet,
        alpha: baseAlpha * 0.55,
      ),
    ];

    for (final bank in banks) {
      _drawEllipticalMist(
        canvas,
        bank.center,
        bank.rx,
        bank.ry,
        bank.color,
        bank.alpha,
      );
    }
  }

  void _paintRollingMistSurges(
    Canvas canvas,
    Size size,
    double t,
    double envelope,
    double dir,
  ) {
    final peak = (isDark ? 0.36 : 0.20) * envelope;
    final surges = [
      (
        center: Offset(
          size.width * (0.5 + 0.38 * (t - 0.5) * dir),
          size.height * (0.76 - 0.08 * math.sin(t * math.pi * 2)),
        ),
        rx: size.width * 0.62,
        ry: size.height * 0.22,
        color: cursedViolet,
        alpha: peak,
      ),
      (
        center: Offset(
          size.width * (0.5 - 0.42 * (t - 0.5) * dir),
          size.height * (0.52 + 0.06 * math.cos(t * math.pi * 2)),
        ),
        rx: size.width * 0.55,
        ry: size.height * 0.19,
        color: deepAmethyst,
        alpha: peak * 0.92,
      ),
      (
        center: Offset(
          size.width * (0.28 + 0.46 * t * dir),
          size.height * (0.28 + 0.05 * math.sin(t * math.pi * 3)),
        ),
        rx: size.width * 0.46,
        ry: size.height * 0.16,
        color: spectralLavender,
        alpha: peak * 0.42,
      ),
      (
        center: Offset(
          size.width * (0.74 - 0.40 * t * dir),
          size.height * (0.90 - 0.12 * t),
        ),
        rx: size.width * 0.64,
        ry: size.height * 0.22,
        color: cursedViolet,
        alpha: peak * 0.95,
      ),
    ];

    for (final s in surges) {
      _drawEllipticalMist(canvas, s.center, s.rx, s.ry, s.color, s.alpha);
    }
  }

  void _paintForegroundWisps(
    Canvas canvas,
    Size size,
    double t,
    double envelope,
    double dir,
  ) {
    // Soft edge-only tendrils so center text stays crystal clear.
    final edgeAlpha = (isDark ? 0.18 : 0.10) * envelope;
    _drawEllipticalMist(
      canvas,
      Offset(size.width * (0.14 + 0.18 * t * dir), size.height * 0.95),
      size.width * 0.48,
      size.height * 0.13,
      spectralLavender,
      edgeAlpha,
    );
    _drawEllipticalMist(
      canvas,
      Offset(size.width * (0.86 - 0.18 * t * dir), size.height * 0.94),
      size.width * 0.46,
      size.height * 0.14,
      cursedViolet,
      edgeAlpha * 1.15,
    );
  }

  void _paintArcaneSparks(
    Canvas canvas,
    Size size,
    double t,
    double envelope,
    double dir,
  ) {
    final motePaint = Paint()..style = PaintingStyle.fill;
    final glowPaint = Paint()..style = PaintingStyle.fill;

    for (var i = 0; i < 20; i++) {
      final phase = (seed * 0.29 + i * 0.618033) % 1.0;
      final mx = size.width * ((phase + 0.12 * math.sin(t * math.pi * 2 + i) * dir) % 1.0);
      final my = size.height * (0.96 - ((i * 0.085 + t * 0.36) % 0.92));
      final r = 1.2 + (i % 3) * 0.85;
      final color = i % 3 == 0 ? moteGold : (i.isEven ? spectralLavender : cursedViolet);
      final localFade = math.sin(((t + i * 0.11) % 1.0) * math.pi).clamp(0.0, 1.0);
      final alpha = (isDark ? 0.65 : 0.42) * envelope * localFade;

      glowPaint.color = color.withValues(alpha: alpha * 0.35);
      canvas.drawCircle(Offset(mx, my), r * 3.2, glowPaint);
      motePaint.color = color.withValues(alpha: alpha);
      canvas.drawCircle(Offset(mx, my), r, motePaint);
    }
  }

  void _drawEllipticalMist(
    Canvas canvas,
    Offset center,
    double rx,
    double ry,
    Color color,
    double alpha,
  ) {
    if (alpha <= 0.002 || rx <= 0 || ry <= 0) return;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(1.0, ry / rx);
    canvas.drawCircle(
      Offset.zero,
      rx,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset.zero,
          rx,
          [
            color.withValues(alpha: alpha),
            color.withValues(alpha: alpha * 0.45),
            Colors.transparent,
          ],
          const [0.0, 0.5, 1.0],
        ),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _EtherealMistPainter oldDelegate) =>
      oldDelegate.seed != seed ||
      oldDelegate.isDark != isDark ||
      oldDelegate.foreground != foreground ||
      oldDelegate.moteGold != moteGold;
}
