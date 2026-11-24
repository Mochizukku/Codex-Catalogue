import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:material_ui/material_ui.dart';
import '../../core/theme/codex_tokens.dart';

/// Plays the full-screen crimson "Mark of Codex Catalogue" SVG line-drawing
/// ritual after Sign Up succeeds, blooming bright across the screen before
/// dissolving seamlessly onto the Sign In view.
void showTheMarkRitualTransition(
  BuildContext context, {
  required VoidCallback onSwitchToSignIn,
}) {
  _showRitualOverlay(
    context,
    duration: const Duration(milliseconds: 3000),
    peakThreshold: 0.86,
    onPeak: onSwitchToSignIn,
    painterBuilder: (controller, disposeCallbacks) {
      final geometry = _MarkSvgGeometry();
      disposeCallbacks.add(geometry.dispose);
      return _TheMarkRitualPainter(progress: controller, geometry: geometry);
    },
  );
}

/// Plays the Sanctum Awakening violet-and-gold astrolabe portal transition
/// after Sign In succeeds, brightening the viewport before dissolving
/// seamlessly onto the Dashboard.
void showSanctumAwakeningTransition(
  BuildContext context, {
  required VoidCallback onEnterDashboard,
}) {
  _showRitualOverlay(
    context,
    duration: const Duration(milliseconds: 2100),
    peakThreshold: 0.84,
    onPeak: onEnterDashboard,
    painterBuilder: (controller, disposeCallbacks) {
      final painters = _buildAwakeningRunePainters();
      disposeCallbacks.add(() {
        for (final tp in painters) {
          tp.dispose();
        }
      });
      return _SanctumAwakeningPainter(
        progress: controller,
        runePainters: painters,
      );
    },
  );
}

List<TextPainter> _buildAwakeningRunePainters() {
  const runes = ['ᛏ', 'ᚱ', 'ᚢ', 'ᚦ', 'ᛁ', 'ᛋ', 'ᚨ', 'ᛒ', 'ᛟ', 'ᚢ', 'ᛖ', 'ᛚ'];
  return List.generate(runes.length, (i) {
    final color = i.isEven
        ? const Color(0xFFD2A94C)
        : AnomalyClass.cursed.color;
    return TextPainter(
      text: TextSpan(
        text: runes[i],
        style: TextStyle(
          fontSize: 18,
          color: color,
          fontWeight: FontWeight.w600,
          shadows: [Shadow(color: color.withValues(alpha: 0.9), blurRadius: 10)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  });
}

void _showRitualOverlay(
  BuildContext context, {
  required Duration duration,
  required double peakThreshold,
  required VoidCallback onPeak,
  required CustomPainter Function(
    AnimationController controller,
    List<VoidCallback> disposeCallbacks,
  )
  painterBuilder,
}) {
  if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
    onPeak();
    return;
  }

  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) {
    onPeak();
    return;
  }

  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _FullscreenRitualHost(
      duration: duration,
      peakThreshold: peakThreshold,
      onPeak: onPeak,
      painterBuilder: painterBuilder,
      onFinished: () {
        if (entry.mounted) {
          entry.remove();
        }
        entry.dispose();
      },
    ),
  );
  overlay.insert(entry);
}

class _FullscreenRitualHost extends StatefulWidget {
  const _FullscreenRitualHost({
    required this.duration,
    required this.peakThreshold,
    required this.onPeak,
    required this.painterBuilder,
    required this.onFinished,
  });

  final Duration duration;
  final double peakThreshold;
  final VoidCallback onPeak;
  final CustomPainter Function(
    AnimationController controller,
    List<VoidCallback> disposeCallbacks,
  )
  painterBuilder;
  final VoidCallback onFinished;

  @override
  State<_FullscreenRitualHost> createState() => _FullscreenRitualHostState();
}

class _FullscreenRitualHostState extends State<_FullscreenRitualHost>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CustomPainter _painter;
  final List<VoidCallback> _disposeCallbacks = [];
  bool _triggeredPeak = false;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..addListener(_onTick)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && !_finished) {
          _finished = true;
          widget.onFinished();
        }
      });
    _painter = widget.painterBuilder(_controller, _disposeCallbacks);
    _controller.forward();
  }

  void _onTick() {
    if (!_triggeredPeak && _controller.value >= widget.peakThreshold) {
      _triggeredPeak = true;
      widget.onPeak();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTick);
    _controller.dispose();
    for (final cb in _disposeCallbacks) {
      cb();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: AbsorbPointer(
        child: RepaintBoundary(
          child: CustomPaint(painter: _painter, size: Size.infinite),
        ),
      ),
    );
  }
}

class _TimedPath {
  _TimedPath(
    this.path, {
    required this.start,
    required this.end,
    required this.width,
    required this.color,
  });

  final Path path;
  final double start;
  final double end;
  final double width;
  final Color color;
  late final List<ui.PathMetric> metrics = path.computeMetrics().toList();
}

class _GlyphOnRing {
  _GlyphOnRing(this.painter, this.position, this.angle);

  final TextPainter painter;
  final Offset position;
  final double angle;
}

class _MarkSvgGeometry {
  _MarkSvgGeometry() {
    _buildPaths();
    _buildRunes();
  }

  static const _center = Offset(340, 340);
  static const _crimsonBright = Color(0xFFEF4444);
  static const _crimsonCore = Color(0xFFDC2626);
  static const _crimsonMid = Color(0xFFB91C1C);
  static const _crimsonDark = Color(0xFF7F1D1D);
  static const _crimsonHighlight = Color(0xFFFCA5A5);

  final List<_TimedPath> strokePaths = [];
  final List<Path> diamondFills = [];
  final List<Offset> spearDots = [];
  final List<Offset> vertexNodes = [];
  final List<_GlyphOnRing> ringRunes = [];
  final List<_GlyphOnRing> arcGlyphs = [];

  late final Path outerSealCircle;
  late final Path innerOccluderCircle;
  late final Path eyeOuterPath;

  void _buildPaths() {
    outerSealCircle = Path()
      ..addOval(Rect.fromCircle(center: _center, radius: 334));
    innerOccluderCircle = Path()
      ..addOval(Rect.fromCircle(center: _center, radius: 130));
    eyeOuterPath = Path()
      ..moveTo(236, 340)
      ..quadraticBezierTo(340, 252, 444, 340)
      ..quadraticBezierTo(340, 428, 236, 340)
      ..close();

    strokePaths.add(
      _TimedPath(
        outerSealCircle,
        start: 0.04,
        end: 0.28,
        width: 3.0,
        color: _crimsonCore,
      ),
    );
    strokePaths.add(
      _TimedPath(
        Path()..addOval(Rect.fromCircle(center: _center, radius: 300)),
        start: 0.08,
        end: 0.32,
        width: 2.0,
        color: _crimsonCore,
      ),
    );

    diamondFills.addAll([
      _polyPath(const [
        Offset(23, 331),
        Offset(32, 340),
        Offset(23, 349),
        Offset(14, 340),
      ]),
      _polyPath(const [
        Offset(657, 331),
        Offset(666, 340),
        Offset(657, 349),
        Offset(648, 340),
      ]),
    ]);

    final hexSpecs = [
      (
        pts: const [Offset(340, 70), Offset(573.8, 475), Offset(106.2, 475)],
        start: 0.18,
        end: 0.44,
        w: 2.5,
        c: _crimsonCore,
      ),
      (
        pts: const [Offset(340, 610), Offset(573.8, 205), Offset(106.2, 205)],
        start: 0.22,
        end: 0.48,
        w: 2.5,
        c: _crimsonBright,
      ),
      (
        pts: const [Offset(340, 118), Offset(532.3, 451), Offset(147.7, 451)],
        start: 0.26,
        end: 0.48,
        w: 1.2,
        c: _crimsonDark,
      ),
      (
        pts: const [Offset(340, 562), Offset(532.3, 229), Offset(147.7, 229)],
        start: 0.28,
        end: 0.50,
        w: 1.2,
        c: _crimsonDark,
      ),
      (
        pts: const [Offset(340, 166), Offset(484, 415), Offset(196, 415)],
        start: 0.30,
        end: 0.52,
        w: 1.2,
        c: _crimsonMid,
      ),
      (
        pts: const [Offset(340, 514), Offset(484, 265), Offset(196, 265)],
        start: 0.32,
        end: 0.54,
        w: 1.2,
        c: _crimsonMid,
      ),
    ];
    for (final h in hexSpecs) {
      strokePaths.add(
        _TimedPath(
          _polyPath(h.pts),
          start: h.start,
          end: h.end,
          width: h.w,
          color: h.c,
        ),
      );
    }

    const outerNodes = [
      Offset(340, 70),
      Offset(340, 610),
      Offset(573.8, 205),
      Offset(573.8, 475),
      Offset(106.2, 205),
      Offset(106.2, 475),
    ];
    for (var i = 0; i < outerNodes.length; i++) {
      final pt = outerNodes[i];
      vertexNodes.add(pt);
      strokePaths.add(
        _TimedPath(
          Path()..addOval(Rect.fromCircle(center: pt, radius: 10)),
          start: 0.36 + i * 0.02,
          end: 0.54 + i * 0.02,
          width: 2.0,
          color: _crimsonBright,
        ),
      );
    }

    for (var i = 0; i < 6; i++) {
      final deg = 30.0 + i * 60.0;
      final rad = deg * math.pi / 180.0;
      final rotMatrix = Matrix4.identity()
        ..translateByDouble(340.0, 340.0, 0.0, 1.0)
        ..rotateZ(rad)
        ..translateByDouble(-340.0, -340.0, 0.0, 1.0);

      final spearLine = Path()
        ..moveTo(340, 134)
        ..lineTo(340, 174)
        ..moveTo(340, 56)
        ..lineTo(340, 76);
      strokePaths.add(
        _TimedPath(
          spearLine.transform(rotMatrix.storage),
          start: 0.34,
          end: 0.54,
          width: 1.5,
          color: _crimsonMid,
        ),
      );

      final diamond = _polyPath(const [
        Offset(340, 55),
        Offset(346, 63),
        Offset(340, 71),
        Offset(334, 63),
      ]).transform(rotMatrix.storage);
      diamondFills.add(diamond);

      final dotRad = (deg - 90.0) * math.pi / 180.0;
      spearDots.add(
        _center + Offset(math.cos(dotRad), math.sin(dotRad)) * 294.0,
      );

      final spokeRad = (i * 60.0) * math.pi / 180.0;
      final p1 = _center + Offset(math.cos(spokeRad), math.sin(spokeRad)) * 130;
      final p2 = _center + Offset(math.cos(spokeRad), math.sin(spokeRad)) * 156;
      strokePaths.add(
        _TimedPath(
          Path()
            ..moveTo(p1.dx, p1.dy)
            ..lineTo(p2.dx, p2.dy),
          start: 0.38,
          end: 0.56,
          width: 2.0,
          color: _crimsonMid,
        ),
      );
    }

    strokePaths.add(
      _TimedPath(
        eyeOuterPath,
        start: 0.14,
        end: 0.42,
        width: 3.0,
        color: _crimsonBright,
      ),
    );
    strokePaths.add(
      _TimedPath(
        Path()
          ..moveTo(262, 340)
          ..quadraticBezierTo(340, 282, 418, 340)
          ..quadraticBezierTo(340, 398, 262, 340)
          ..close(),
        start: 0.24,
        end: 0.50,
        width: 1.5,
        color: _crimsonDark,
      ),
    );
    strokePaths.add(
      _TimedPath(
        Path()..addOval(Rect.fromCircle(center: _center, radius: 38)),
        start: 0.34,
        end: 0.58,
        width: 1.8,
        color: _crimsonHighlight,
      ),
    );
    strokePaths.add(
      _TimedPath(
        Path()..addOval(Rect.fromCircle(center: _center, radius: 26)),
        start: 0.38,
        end: 0.60,
        width: 2.0,
        color: _crimsonDark,
      ),
    );

    const eyeRays = [
      (Offset(340, 236), Offset(340, 216)),
      (Offset(340, 444), Offset(340, 464)),
      (Offset(236, 340), Offset(216, 340)),
      (Offset(444, 340), Offset(464, 340)),
      (Offset(268, 278), Offset(256, 266)),
      (Offset(412, 278), Offset(424, 266)),
      (Offset(268, 402), Offset(256, 414)),
      (Offset(412, 402), Offset(424, 414)),
    ];
    for (final r in eyeRays) {
      strokePaths.add(
        _TimedPath(
          Path()
            ..moveTo(r.$1.dx, r.$1.dy)
            ..lineTo(r.$2.dx, r.$2.dy),
          start: 0.42,
          end: 0.62,
          width: 2.0,
          color: _crimsonCore,
        ),
      );
    }
  }

  void _buildRunes() {
    const innerRunes = ['ᛟ', 'ᛉ', 'ᚦ', 'ᛞ', 'ᚷ', 'ᛗ'];
    for (var i = 0; i < innerRunes.length; i++) {
      final rad = (i * 60.0 - 90.0) * math.pi / 180.0;
      final pos = _center + Offset(math.cos(rad), math.sin(rad)) * 228.0;
      final tp = _makeTextPainter(innerRunes[i], 32, _crimsonBright);
      ringRunes.add(_GlyphOnRing(tp, pos, (i * 60.0) * math.pi / 180.0));
    }

    const outerRunes = ['ᚠ', 'ᚨ', 'ᛊ', 'ᛏ', 'ᛈ', 'ᚱ'];
    for (var i = 0; i < outerRunes.length; i++) {
      final deg = 30.0 + i * 60.0;
      final rad = (deg - 90.0) * math.pi / 180.0;
      final pos = _center + Offset(math.cos(rad), math.sin(rad)) * 240.0;
      final tp = _makeTextPainter(outerRunes[i], 28, _crimsonCore);
      ringRunes.add(_GlyphOnRing(tp, pos, deg * math.pi / 180.0));
    }

    const topInscription = 'ᛏᚱᚢᚦ ᛫ ᛁᛋ ᛫ ᚨᛒᛟᚢᛖ ᛫ ᚨᛚᛚ';
    const topSpan = 1.95;
    for (var i = 0; i < topInscription.length; i++) {
      final frac = (i / (topInscription.length - 1)) - 0.5;
      final angle = -math.pi / 2 + frac * topSpan;
      final pos = _center + Offset(math.cos(angle), math.sin(angle)) * 315.0;
      final tp = _makeTextPainter(topInscription[i], 21, _crimsonBright);
      arcGlyphs.add(_GlyphOnRing(tp, pos, angle + math.pi / 2));
    }

    const bottomTitle = 'THE MARK OF CODEX CATALOGUE';
    const bottomSpan = 2.08;
    for (var i = 0; i < bottomTitle.length; i++) {
      final frac = 0.5 - (i / (bottomTitle.length - 1));
      final angle = math.pi / 2 + frac * bottomSpan;
      final pos = _center + Offset(math.cos(angle), math.sin(angle)) * 319.0;
      final tp = TextPainter(
        text: TextSpan(
          text: bottomTitle[i],
          style: CodexTypography.screenTitle(_crimsonBright).copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            shadows: [
              Shadow(
                color: _crimsonCore.withValues(alpha: 0.9),
                blurRadius: 10,
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      arcGlyphs.add(_GlyphOnRing(tp, pos, angle - math.pi / 2));
    }
  }

  TextPainter _makeTextPainter(String ch, double size, Color color) {
    return TextPainter(
      text: TextSpan(
        text: ch,
        style: TextStyle(
          fontSize: size,
          color: color,
          fontWeight: FontWeight.w500,
          shadows: [
            Shadow(color: _crimsonCore.withValues(alpha: 0.95), blurRadius: 12),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  static Path _polyPath(List<Offset> pts) {
    final p = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      p.lineTo(pts[i].dx, pts[i].dy);
    }
    return p..close();
  }

  void dispose() {
    for (final g in ringRunes) {
      g.painter.dispose();
    }
    for (final g in arcGlyphs) {
      g.painter.dispose();
    }
  }
}

class _TheMarkRitualPainter extends CustomPainter {
  _TheMarkRitualPainter({required this.progress, required this.geometry})
    : super(repaint: progress);

  final Animation<double> progress;
  final _MarkSvgGeometry geometry;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final t = progress.value;

    final enterFade = (t / 0.12).clamp(0.0, 1.0);
    final exitFade = t >= 0.86
        ? (1.0 - ((t - 0.86) / 0.14)).clamp(0.0, 1.0)
        : 1.0;

    final bloomT = ((t - 0.62) / 0.24).clamp(0.0, 1.0);
    final bloomEased = Curves.easeInCubic.transform(bloomT);

    if (t < 0.86) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..color = const Color(0xFF0A0406).withValues(
            alpha: (0.96 * enterFade) * (1.0 - bloomEased),
          ),
      );
    }

    final center = Offset(size.width * 0.5, size.height * 0.5);
    final baseSealDiameter = math.min(size.width * 0.82, 420.0);
    final baseScale = baseSealDiameter / 690.0;
    final growthScale = 1.0 + bloomEased * 2.2;

    final auraRadius = (baseSealDiameter * 0.68) * (1.0 + bloomEased * 1.4);
    canvas.drawCircle(
      center,
      auraRadius,
      Paint()
        ..shader = ui.Gradient.radial(
          center,
          auraRadius,
          [
            const Color(0xFFEF4444).withValues(
              alpha: (0.35 * enterFade + 0.45 * bloomEased) * exitFade,
            ),
            const Color(0xFF991B1B).withValues(
              alpha: 0.25 * enterFade * exitFade,
            ),
            Colors.transparent,
          ],
          const [0.0, 0.55, 1.0],
        ),
    );

    if (exitFade > 0.01) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.scale(baseScale * growthScale);
      canvas.translate(-340.0, -340.0);

      if (t > 0.12 && bloomEased < 0.85) {
        final discAlpha =
            ((t - 0.12) / 0.20).clamp(0.0, 1.0) * (1.0 - bloomEased) * 0.72;
        canvas.drawPath(
          geometry.outerSealCircle,
          Paint()..color = const Color(0xFF16090B).withValues(alpha: discAlpha),
        );
        canvas.drawPath(
          geometry.innerOccluderCircle,
          Paint()..color = const Color(0xFF0F0F0F).withValues(alpha: discAlpha),
        );
      }

      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      final crispPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      for (final sp in geometry.strokePaths) {
        final segT = ((t - sp.start) / (sp.end - sp.start)).clamp(0.0, 1.0);
        if (segT <= 0) continue;

        final drawPath = Path();
        for (final metric in sp.metrics) {
          drawPath.addPath(
            metric.extractPath(0, metric.length * segT),
            Offset.zero,
          );
        }

        glowPaint
          ..strokeWidth = sp.width + 7.5 + bloomEased * 5.0
          ..color = sp.color.withValues(alpha: 0.28 * exitFade);
        canvas.drawPath(drawPath, glowPaint);

        crispPaint
          ..strokeWidth = sp.width
          ..color = Color.lerp(
            sp.color,
            const Color(0xFFFCA5A5),
            bloomEased * 0.65,
          )!.withValues(alpha: exitFade);
        canvas.drawPath(drawPath, crispPaint);
      }

      final accentT = ((t - 0.40) / 0.20).clamp(0.0, 1.0) * exitFade;
      if (accentT > 0) {
        final fillGlow = Paint()
          ..color = const Color(0xFFEF4444).withValues(alpha: 0.28 * accentT);
        final fillCrisp = Paint()
          ..color = const Color(0xFFDC2626).withValues(alpha: accentT);

        for (final d in geometry.diamondFills) {
          canvas.drawPath(d, fillCrisp);
        }
        for (final pt in geometry.spearDots) {
          canvas.drawCircle(pt, 6.5, fillGlow);
          canvas.drawCircle(pt, 3.0, fillCrisp);
        }
        for (final pt in geometry.vertexNodes) {
          canvas.drawCircle(pt, 3.5, fillCrisp);
        }
      }

      final eyeT = ((t - 0.38) / 0.26).clamp(0.0, 1.0) * exitFade;
      if (eyeT > 0) {
        canvas.drawPath(
          geometry.eyeOuterPath,
          Paint()
            ..color = const Color(0xFF2A0A0D).withValues(
              alpha: 0.85 * eyeT * (1.0 - bloomEased),
            ),
        );
        canvas.drawCircle(
          const Offset(340, 340),
          48,
          Paint()
            ..color = const Color(0xFFEF4444).withValues(alpha: 0.24 * eyeT),
        );
        canvas.drawCircle(
          const Offset(340, 340),
          38,
          Paint()..color = const Color(0xFFDC2626).withValues(alpha: eyeT),
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: const Offset(340, 340),
            width: 16 * eyeT,
            height: 40,
          ),
          Paint()
            ..color = const Color(0xFF0F0F0F).withValues(
              alpha: eyeT * (1.0 - bloomEased * 0.85),
            ),
        );
        canvas.drawCircle(
          const Offset(351, 328),
          5,
          Paint()..color = const Color(0xFFFCA5A5).withValues(alpha: eyeT),
        );
      }

      final runeT = ((t - 0.46) / 0.24).clamp(0.0, 1.0) * exitFade;
      if (runeT > 0.05) {
        canvas.saveLayer(
          const Rect.fromLTWH(0, 0, 690, 690),
          Paint()..color = Color.fromRGBO(255, 255, 255, runeT),
        );
        for (final g in geometry.ringRunes) {
          canvas.save();
          canvas.translate(g.position.dx, g.position.dy);
          canvas.rotate(g.angle);
          g.painter.paint(
            canvas,
            Offset(-g.painter.width * 0.5, -g.painter.height * 0.5),
          );
          canvas.restore();
        }
        for (final g in geometry.arcGlyphs) {
          canvas.save();
          canvas.translate(g.position.dx, g.position.dy);
          canvas.rotate(g.angle);
          g.painter.paint(
            canvas,
            Offset(-g.painter.width * 0.5, -g.painter.height * 0.5),
          );
          canvas.restore();
        }
        canvas.restore();
      }

      canvas.restore();
    }

    if (bloomEased > 0) {
      final flashRadius = size.longestSide * (0.35 + bloomEased * 1.15);
      final flashAlpha = (bloomEased * exitFade).clamp(0.0, 1.0);
      canvas.drawCircle(
        center,
        flashRadius,
        Paint()
          ..shader = ui.Gradient.radial(
            center,
            flashRadius,
            [
              const Color(0xFFFFF1F2).withValues(alpha: flashAlpha),
              const Color(0xFFFCA5A5).withValues(alpha: flashAlpha * 0.96),
              const Color(0xFFEF4444).withValues(alpha: flashAlpha * 0.92),
              const Color(0xFF991B1B).withValues(alpha: flashAlpha * 0.85),
            ],
            const [0.0, 0.35, 0.72, 1.0],
          ),
      );
      if (bloomEased > 0.55) {
        final fullCover = ((bloomEased - 0.55) / 0.45).clamp(0.0, 1.0);
        canvas.drawRect(
          Offset.zero & size,
          Paint()
            ..color = Color.lerp(
              const Color(0xFFEF4444),
              const Color(0xFFFFE4E6),
              fullCover,
            )!.withValues(alpha: fullCover * exitFade),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TheMarkRitualPainter oldDelegate) =>
      oldDelegate.geometry != geometry;
}

class _SanctumAwakeningPainter extends CustomPainter {
  _SanctumAwakeningPainter({required this.progress, required this.runePainters})
    : super(repaint: progress);

  final Animation<double> progress;
  final List<TextPainter> runePainters;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final t = progress.value;

    final enterFade = (t / 0.14).clamp(0.0, 1.0);
    final exitFade = t >= 0.84
        ? (1.0 - ((t - 0.84) / 0.16)).clamp(0.0, 1.0)
        : 1.0;

    final bloomT = ((t - 0.52) / 0.32).clamp(0.0, 1.0);
    final bloomEased = Curves.easeInCubic.transform(bloomT);

    const violet = Color(0xFFA679CF);
    const gold = Color(0xFFD2A94C);
    const brightCore = Color(0xFFF5ECFF);

    if (t < 0.84) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..color = const Color(0xFF09060E).withValues(
            alpha: (0.94 * enterFade) * (1.0 - bloomEased),
          ),
      );
    }

    final center = Offset(size.width * 0.5, size.height * 0.5);
    final baseR = math.min(size.width * 0.38, 175.0);
    final sealScale = 1.0 + bloomEased * 2.0;

    if (exitFade > 0.01) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.scale(sealScale);

      final ringProgress = (t / 0.55).clamp(0.0, 1.0);
      final ringAlpha = enterFade * exitFade;

      final goldPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..color = gold.withValues(alpha: 0.85 * ringAlpha);
      final violetPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..color = violet.withValues(alpha: 0.90 * ringAlpha);
      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9.0
        ..color = violet.withValues(alpha: 0.26 * ringAlpha);

      final sweep = math.pi * 2 * Curves.easeOutCubic.transform(ringProgress);
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: baseR),
        -math.pi / 2,
        sweep,
        false,
        glowPaint,
      );
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: baseR),
        -math.pi / 2,
        sweep,
        false,
        goldPaint,
      );
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: baseR * 0.78),
        math.pi / 2,
        sweep,
        false,
        violetPaint,
      );

      final spin = t * math.pi * 1.4;
      _drawSquare(canvas, baseR * 0.76, spin, goldPaint);
      _drawSquare(canvas, baseR * 0.76, spin + math.pi / 4, violetPaint);

      if (ringProgress > 0.25) {
        final runeAlpha = ((ringProgress - 0.25) / 0.4).clamp(0.0, 1.0);
        canvas.saveLayer(
          Rect.fromCircle(center: Offset.zero, radius: baseR + 28),
          Paint()..color = Color.fromRGBO(255, 255, 255, runeAlpha * exitFade),
        );
        for (var i = 0; i < runePainters.length; i++) {
          final a = -spin * 0.5 + i * (math.pi * 2 / runePainters.length);
          final pos = Offset(math.cos(a), math.sin(a)) * (baseR * 0.89);
          final tp = runePainters[i];
          canvas.save();
          canvas.translate(pos.dx, pos.dy);
          canvas.rotate(a + math.pi / 2);
          tp.paint(canvas, Offset(-tp.width * 0.5, -tp.height * 0.5));
          canvas.restore();
        }
        canvas.restore();
      }

      canvas.restore();
    }

    if (bloomEased > 0) {
      final flashRadius = size.longestSide * (0.30 + bloomEased * 1.15);
      final flashAlpha = (bloomEased * exitFade).clamp(0.0, 1.0);
      canvas.drawCircle(
        center,
        flashRadius,
        Paint()
          ..shader = ui.Gradient.radial(
            center,
            flashRadius,
            [
              Colors.white.withValues(alpha: flashAlpha),
              brightCore.withValues(alpha: flashAlpha * 0.96),
              violet.withValues(alpha: flashAlpha * 0.85),
              const Color(0xFF4C1D95).withValues(alpha: flashAlpha * 0.75),
            ],
            const [0.0, 0.35, 0.70, 1.0],
          ),
      );
      if (bloomEased > 0.55) {
        final fullCover = ((bloomEased - 0.55) / 0.45).clamp(0.0, 1.0);
        canvas.drawRect(
          Offset.zero & size,
          Paint()
            ..color = Color.lerp(
              violet,
              brightCore,
              fullCover,
            )!.withValues(alpha: fullCover * exitFade),
        );
      }
    }
  }

  void _drawSquare(Canvas canvas, double r, double rotation, Paint paint) {
    final path = Path();
    for (var i = 0; i < 4; i++) {
      final a = rotation + i * (math.pi / 2);
      final pt = Offset(math.cos(a), math.sin(a)) * r;
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
  bool shouldRepaint(covariant _SanctumAwakeningPainter oldDelegate) => false;
}
