import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:material_ui/material_ui.dart';
import '../core/theme/codex_theme.dart';
import '../core/theme/codex_tokens.dart';

const kDefaultCodexRunes = <String>[
  'ᛏ',
  'ᚱ',
  'ᚢ',
  'ᚦ',
  'ᛁ',
  'ᛋ',
  'ᚨ',
  'ᛒ',
  'ᛟ',
  'ᚢ',
  'ᛖ',
  'ᚨ',
  'ᛚ',
];

/// Reusable, performance-optimized overlay that occasionally spawns random
/// floating Elder Futhark runes drifting across the screen. Pressing or dragging
/// near a rune deflects its trajectory with an arcane pulse without blocking
/// underlying scrolling or button gestures.
class FloatingRunesOverlay extends StatefulWidget {
  const FloatingRunesOverlay({
    super.key,
    this.child,
    this.runes = kDefaultCodexRunes,
    this.burstInterval = const Duration(milliseconds: 8500),
    this.initialDelay = const Duration(milliseconds: 1800),
    this.burstDuration = const Duration(milliseconds: 6200),
    this.minRunesPerBurst = 5,
    this.maxRunesPerBurst = 8,
    this.maxOpacity = 0.42,
    this.hitRadius = 48.0,
    this.paintInFront = false,
    this.enabled = true,
  });

  final Widget? child;
  final List<String> runes;
  final Duration burstInterval;
  final Duration initialDelay;
  final Duration burstDuration;
  final int minRunesPerBurst;
  final int maxRunesPerBurst;
  final double maxOpacity;
  final double hitRadius;
  final bool paintInFront;
  final bool enabled;

  @override
  State<FloatingRunesOverlay> createState() => _FloatingRunesOverlayState();
}

class _FloatingRunesOverlayState extends State<FloatingRunesOverlay>
    with SingleTickerProviderStateMixin {
  static const _alphaSteps = [0.22, 0.48, 0.76, 1.0];
  static const _baseFontSize = 20.0;

  late final AnimationController _controller;
  final math.Random _rng = math.Random();
  final List<_RuneParticle> _particles = [];
  final Map<String, List<TextPainter>> _painterCache = {};

  Timer? _initialDelayTimer;
  Timer? _periodicTimer;
  bool _disableAnimations = false;
  double _lastElapsedSec = 0;
  Size _viewportSize = Size.zero;
  int _burstCounter = 0;

  CodexThemeMode? _cachedMode;
  Color? _cachedGold;
  Color? _cachedViolet;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.burstDuration,
    )..addListener(_stepPhysics);
    _startTimers();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _disableAnimations = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final p = context.codex;
    final violet = AnomalyClass.cursed.color;
    if (_cachedMode != p.mode ||
        _cachedGold != p.accent ||
        _cachedViolet != violet) {
      _disposePainters();
      _cachedMode = p.mode;
      _cachedGold = p.accent;
      _cachedViolet = violet;
    }
  }

  @override
  void didUpdateWidget(covariant FloatingRunesOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.burstDuration != oldWidget.burstDuration) {
      _controller.duration = widget.burstDuration;
    }
    if (widget.enabled != oldWidget.enabled) {
      if (!widget.enabled) {
        _particles.clear();
        _controller.stop();
      }
    }
  }

  void _startTimers() {
    _initialDelayTimer = Timer(widget.initialDelay, _spawnBurst);
    _periodicTimer = Timer.periodic(widget.burstInterval, (_) => _spawnBurst());
  }

  void _spawnBurst() {
    if (!mounted ||
        !widget.enabled ||
        _disableAnimations ||
        widget.runes.isEmpty ||
        _viewportSize.isEmpty ||
        _controller.isAnimating) {
      return;
    }

    _burstCounter++;
    _lastElapsedSec = 0;
    _particles.clear();

    final minCount = widget.minRunesPerBurst.clamp(1, 20);
    final maxCount = math.max(minCount, widget.maxRunesPerBurst);
    final count = minCount + _rng.nextInt(maxCount - minCount + 1);

    for (var i = 0; i < count; i++) {
      final rune = widget.runes[_rng.nextInt(widget.runes.length)];
      final x = (0.08 + _rng.nextDouble() * 0.84) * _viewportSize.width;
      final y = (0.22 + _rng.nextDouble() * 0.70) * _viewportSize.height;
      final angle = _rng.nextDouble() * math.pi * 2;
      final baseSpeed = 14.0 + _rng.nextDouble() * 18.0;

      _particles.add(
        _RuneParticle(
          rune: rune,
          x: x,
          y: y,
          baseVx: math.cos(angle) * baseSpeed * 0.75,
          baseVy: -16.0 - _rng.nextDouble() * 18.0,
          impulseVx: 0,
          impulseVy: 0,
          rotation: (_rng.nextDouble() - 0.5) * 0.45,
          angularVel: (_rng.nextDouble() - 0.5) * 0.35,
          scale: 0.78 + _rng.nextDouble() * 0.48,
          isGold: _rng.nextBool(),
          startFrac: (i / math.max(count, 1)) * 0.28,
          lifeFrac: 0.62 + _rng.nextDouble() * 0.32,
          swayPhase: _rng.nextDouble() * math.pi * 2,
        ),
      );
    }

    _controller.forward(from: 0);
  }

  void _stepPhysics() {
    if (_particles.isEmpty) return;
    final elapsedSec =
        (_controller.lastElapsedDuration?.inMicroseconds ?? 0) / 1e6;
    final dt = (elapsedSec - _lastElapsedSec).clamp(0.0, 0.05);
    _lastElapsedSec = elapsedSec;
    if (dt <= 0) return;

    final progress = _controller.value;
    final damping = math.exp(-2.4 * dt);

    for (final p in _particles) {
      if (progress < p.startFrac) continue;
      final swayX = math.sin(elapsedSec * 1.4 + p.swayPhase) * 9.0;
      p.x += (p.baseVx + swayX + p.impulseVx) * dt;
      p.y += (p.baseVy + p.impulseVy) * dt;
      p.impulseVx *= damping;
      p.impulseVy *= damping;
      p.rotation += p.angularVel * dt;
      if (p.hitFlash > 0) {
        p.hitFlash = (p.hitFlash - dt * 1.9).clamp(0.0, 1.0);
      }
      if (p.hitCooldown > 0) {
        p.hitCooldown = (p.hitCooldown - dt).clamp(0.0, 1.0);
      }
    }
  }

  void _handlePointerHit(Offset localPos, Offset? dragDelta) {
    if (_particles.isEmpty || !_controller.isAnimating) return;

    final progress = _controller.value;
    final radiusSq = widget.hitRadius * widget.hitRadius;
    final hasDrag = dragDelta != null && dragDelta.distanceSquared > 0.5;

    for (final p in _particles) {
      final localT = (progress - p.startFrac) / p.lifeFrac;
      if (localT <= 0.02 || localT >= 0.98 || p.hitCooldown > 0) continue;

      final dx = p.x - localPos.dx;
      final dy = p.y - localPos.dy;
      final distSq = dx * dx + dy * dy;
      if (distSq > radiusSq) continue;

      if (hasDrag) {
        final dir = dragDelta / math.max(dragDelta.distance, 1.0);
        final speed = (150.0 + dragDelta.distance * 14.0).clamp(150.0, 340.0);
        p.impulseVx = dir.dx * speed;
        p.impulseVy = dir.dy * speed;
        p.baseVx = dir.dx * 34.0;
        p.baseVy = dir.dy * 34.0;
        p.angularVel = (dir.dx - dir.dy) * 3.2;
      } else {
        final dist = math.sqrt(math.max(distSq, 1.0));
        final awayX = dist > 2 ? dx / dist : (_rng.nextDouble() - 0.5) * 2;
        final awayY = dist > 2 ? dy / dist : -1.0;
        p.impulseVx = awayX * 185.0;
        p.impulseVy = awayY * 185.0;
        p.baseVx = awayX * 30.0;
        p.baseVy = awayY * 30.0;
        p.angularVel = (_rng.nextBool() ? 1 : -1) * 3.0;
      }

      p.hitFlash = 1.0;
      p.hitCooldown = 0.14;
    }
  }

  List<TextPainter> _paintersFor(String rune, bool isGold) {
    final key = '${rune}_${isGold ? 1 : 0}';
    return _painterCache.putIfAbsent(key, () {
      final base = isGold
          ? (_cachedGold ?? const Color(0xFFD2A94C))
          : (_cachedViolet ?? AnomalyClass.cursed.color);
      return [
        for (final alpha in _alphaSteps)
          TextPainter(
            text: TextSpan(
              text: rune,
              style: TextStyle(
                fontSize: _baseFontSize,
                fontWeight: FontWeight.w600,
                color: base.withValues(alpha: alpha),
                shadows: [
                  Shadow(
                    color: base.withValues(alpha: alpha * 0.85),
                    blurRadius: 12,
                  ),
                ],
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout(),
      ];
    });
  }

  void _disposePainters() {
    for (final list in _painterCache.values) {
      for (final tp in list) {
        tp.dispose();
      }
    }
    _painterCache.clear();
  }

  @override
  void dispose() {
    _initialDelayTimer?.cancel();
    _periodicTimer?.cancel();
    _controller.removeListener(_stepPhysics);
    _controller.dispose();
    _disposePainters();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gold = _cachedGold ?? context.codex.accent;
    final violet = _cachedViolet ?? AnomalyClass.cursed.color;

    final paintLayer = Positioned.fill(
      child: IgnorePointer(
        child: LayoutBuilder(
          builder: (_, constraints) {
            _viewportSize = constraints.biggest;
            return RepaintBoundary(
              child: CustomPaint(
                painter: _FloatingRunesPainter(
                  progress: _controller,
                  particles: _particles,
                  paintersFor: _paintersFor,
                  goldColor: gold,
                  violetColor: violet,
                  maxOpacity: widget.maxOpacity,
                  burstCounter: _burstCounter,
                ),
                size: Size.infinite,
              ),
            );
          },
        ),
      ),
    );

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (e) => _handlePointerHit(e.localPosition, null),
      onPointerMove: (e) => _handlePointerHit(e.localPosition, e.delta),
      child: widget.child == null
          ? Stack(fit: StackFit.expand, children: [paintLayer])
          : Stack(
              fit: StackFit.expand,
              children: widget.paintInFront
                  ? [widget.child!, paintLayer]
                  : [paintLayer, widget.child!],
            ),
    );
  }
}

class _RuneParticle {
  _RuneParticle({
    required this.rune,
    required this.x,
    required this.y,
    required this.baseVx,
    required this.baseVy,
    required this.impulseVx,
    required this.impulseVy,
    required this.rotation,
    required this.angularVel,
    required this.scale,
    required this.isGold,
    required this.startFrac,
    required this.lifeFrac,
    required this.swayPhase,
  });

  final String rune;
  double x;
  double y;
  double baseVx;
  double baseVy;
  double impulseVx;
  double impulseVy;
  double rotation;
  double angularVel;
  final double scale;
  final bool isGold;
  final double startFrac;
  final double lifeFrac;
  final double swayPhase;
  double hitFlash = 0;
  double hitCooldown = 0;
}

class _FloatingRunesPainter extends CustomPainter {
  _FloatingRunesPainter({
    required this.progress,
    required this.particles,
    required this.paintersFor,
    required this.goldColor,
    required this.violetColor,
    required this.maxOpacity,
    required this.burstCounter,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final List<_RuneParticle> particles;
  final List<TextPainter> Function(String rune, bool isGold) paintersFor;
  final Color goldColor;
  final Color violetColor;
  final double maxOpacity;
  final int burstCounter;

  @override
  void paint(Canvas canvas, Size size) {
    final globalT = progress.value;
    if (globalT <= 0 || globalT >= 1 || particles.isEmpty) return;

    final auraPaint = Paint()..style = PaintingStyle.fill;
    final rayPaint = Paint()..style = PaintingStyle.stroke;
    final sparkPaint = Paint()..style = PaintingStyle.fill;

    for (final p in particles) {
      final localT = (globalT - p.startFrac) / p.lifeFrac;
      if (localT <= 0 || localT >= 1) continue;

      final envelope = math.sin(localT * math.pi).clamp(0.0, 1.0);
      final pulse = 1.0 + 0.14 * math.sin(globalT * math.pi * 6 + p.swayPhase);
      final alpha = (maxOpacity * envelope + p.hitFlash * 0.48).clamp(0.0, 1.0);
      final buckets = paintersFor(p.rune, p.isGold);
      final bucketIdx = (alpha * (buckets.length - 1)).round().clamp(
        0,
        buckets.length - 1,
      );
      final tp = buckets[bucketIdx];
      final color = p.isGold ? goldColor : violetColor;
      final brightCore = Color.lerp(color, Colors.white, 0.45)!;
      final center = Offset(p.x, p.y);

      // 1. Multi-stop radiating aura (soft outer corona + luminous core)
      final auraRadius = (34.0 * p.scale) * pulse + p.hitFlash * 22.0;
      final coreAlpha = (0.34 * envelope + 0.42 * p.hitFlash).clamp(0.0, 0.85);
      auraPaint.shader = ui.Gradient.radial(
        center,
        auraRadius,
        [
          brightCore.withValues(alpha: coreAlpha * 0.65),
          color.withValues(alpha: coreAlpha * 0.45),
          color.withValues(alpha: coreAlpha * 0.14),
          Colors.transparent,
        ],
        const [0.0, 0.28, 0.62, 1.0],
      );
      canvas.drawCircle(center, auraRadius, auraPaint);

      // 2. Radiating arcane star rays around the rune
      final rayLength = (22.0 * p.scale) * pulse + p.hitFlash * 14.0;
      final rayAlpha = (0.28 * envelope + 0.45 * p.hitFlash).clamp(0.0, 0.8);
      for (var rIdx = 0; rIdx < 4; rIdx++) {
        final angle = p.rotation * 0.7 + rIdx * (math.pi / 4);
        final isPrimary = rIdx.isEven;
        final len = isPrimary ? rayLength : rayLength * 0.68;
        final dx = math.cos(angle) * len;
        final dy = math.sin(angle) * len;
        final p1 = Offset(p.x - dx, p.y - dy);
        final p2 = Offset(p.x + dx, p.y + dy);
        rayPaint
          ..strokeWidth = (isPrimary ? 1.4 : 0.9) + p.hitFlash * 0.8
          ..shader = ui.Gradient.linear(
            p1,
            p2,
            [
              Colors.transparent,
              brightCore.withValues(alpha: rayAlpha),
              Colors.transparent,
            ],
            const [0.0, 0.5, 1.0],
          );
        canvas.drawLine(p1, p2, rayPaint);
      }

      // 3. Expanding impact aura + radial sparks when pressed or dragged
      if (p.hitFlash > 0.02) {
        final shockRadius = 16.0 + (1.0 - p.hitFlash) * 34.0;
        auraPaint.shader = ui.Gradient.radial(
          center,
          shockRadius + 8,
          [
            Colors.transparent,
            brightCore.withValues(alpha: p.hitFlash * 0.48),
            color.withValues(alpha: p.hitFlash * 0.22),
            Colors.transparent,
          ],
          const [0.55, 0.78, 0.90, 1.0],
        );
        canvas.drawCircle(center, shockRadius + 8, auraPaint);

        for (var s = 0; s < 6; s++) {
          final sa = p.swayPhase + s * (math.pi / 3);
          final dist = 10.0 + (1.0 - p.hitFlash) * 32.0;
          final sp = Offset(
            p.x + math.cos(sa) * dist,
            p.y + math.sin(sa) * dist,
          );
          sparkPaint.color = brightCore.withValues(alpha: p.hitFlash * 0.85);
          canvas.drawCircle(sp, 1.6 * p.hitFlash + 0.6, sparkPaint);
        }
      }

      canvas.save();
      canvas.translate(p.x, p.y);
      if (p.rotation.abs() > 0.001) {
        canvas.rotate(p.rotation);
      }
      if ((p.scale - 1.0).abs() > 0.01) {
        canvas.scale(p.scale);
      }
      tp.paint(canvas, Offset(-tp.width * 0.5, -tp.height * 0.5));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _FloatingRunesPainter oldDelegate) =>
      oldDelegate.burstCounter != burstCounter ||
      oldDelegate.maxOpacity != maxOpacity ||
      oldDelegate.goldColor != goldColor ||
      oldDelegate.violetColor != violetColor;
}
