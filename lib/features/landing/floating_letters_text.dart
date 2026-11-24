import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

/// Displays [text] with a GPU-batched floating-letters assembly animation when
/// [revealed] transitions to true, keeping the landed glyphs as-is upon
/// completion with zero layout or text swap.
class FloatingLettersText extends StatefulWidget {
  const FloatingLettersText({
    super.key,
    required this.text,
    required this.style,
    required this.glowColor,
    required this.revealed,
    this.duration = const Duration(milliseconds: 1450),
  });

  final String text;
  final TextStyle style;
  final Color glowColor;
  final bool revealed;
  final Duration duration;

  @override
  State<FloatingLettersText> createState() => _FloatingLettersTextState();
}

class _FloatingLettersTextState extends State<FloatingLettersText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _disableAnimations = false;

  double? _cachedWidth;
  String? _cachedText;
  TextStyle? _cachedStyle;
  TextScaler? _cachedScaler;
  double? _cachedDpr;

  List<_GlyphTarget>? _glyphs;
  Map<String, _SpriteGlyph>? _sprites;
  ui.Image? _atlasImage;
  int? _atlasGeneration;
  bool? _layoutScheduled;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    GoogleFonts.pendingFonts().then((_) {
      if (!mounted) return;
      final prevW = _cachedWidth;
      final prevScaler = _cachedScaler;
      _cachedWidth = null;
      if (prevW != null && prevScaler != null) {
        _ensureLayout(prevW, prevScaler, _cachedDpr ?? 1.0);
        if (widget.revealed) setState(() {});
      }
    });
  }

  @override
  void reassemble() {
    super.reassemble();
    _cachedWidth = null;
    _layoutScheduled = false;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _disableAnimations = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (widget.revealed && _disableAnimations) {
      _controller.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant FloatingLettersText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.revealed == oldWidget.revealed) return;

    if (!widget.revealed) {
      _controller.reset();
    } else if (_disableAnimations) {
      _controller.value = 1;
    } else {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _atlasGeneration = (_atlasGeneration ?? 0) + 1;
    _disposeGlyphResources();
    _controller.dispose();
    super.dispose();
  }

  void _disposeGlyphResources() {
    final sprites = _sprites;
    if (sprites != null) {
      for (final s in sprites.values) {
        s.painter.dispose();
      }
    }
    _sprites = const {};
    _atlasImage?.dispose();
    _atlasImage = null;
  }

  void _schedulePreLayout(
    double maxWidth,
    TextScaler textScaler,
    double dpr,
  ) {
    if (_cachedWidth == maxWidth &&
        _cachedText == widget.text &&
        _cachedStyle == widget.style &&
        _cachedScaler == textScaler &&
        _cachedDpr == dpr) {
      return;
    }
    if (_layoutScheduled ?? false) return;
    _layoutScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _layoutScheduled = false;
      if (!mounted) return;
      _ensureLayout(maxWidth, textScaler, dpr);
    });
  }

  void _ensureLayout(double maxWidth, TextScaler textScaler, double dpr) {
    if (_cachedWidth == maxWidth &&
        _cachedText == widget.text &&
        _cachedStyle == widget.style &&
        _cachedScaler == textScaler &&
        _cachedDpr == dpr) {
      return;
    }

    _disposeGlyphResources();
    _cachedWidth = maxWidth;
    _cachedText = widget.text;
    _cachedStyle = widget.style;
    _cachedScaler = textScaler;
    _cachedDpr = dpr;

    final paragraphPainter = TextPainter(
      text: TextSpan(text: widget.text, style: widget.style),
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
    )..layout(maxWidth: maxWidth);

    final lines = paragraphPainter.computeLineMetrics();
    final lineBands = <({double top, double bottom, double baseline})>[];
    var yCursor = 0.0;
    for (final line in lines) {
      lineBands.add((
        top: yCursor,
        bottom: yCursor + line.height,
        baseline: yCursor + line.ascent,
      ));
      yCursor += line.height;
    }

    final sprites = <String, _SpriteGlyph>{};
    final glyphs = <_GlyphTarget>[];
    final text = widget.text;
    final len = text.length;

    const pad = 2.0;
    var cursorX = 0.0;
    var maxCellH = 0.0;

    for (var i = 0; i < len; i++) {
      final ch = text[i];
      if (ch.trim().isEmpty) continue;

      var sprite = sprites[ch];
      if (sprite == null) {
        final cp = TextPainter(
          text: TextSpan(text: ch, style: widget.style),
          textDirection: TextDirection.ltr,
          textScaler: textScaler,
        )..layout();
        final baseline = cp.computeDistanceToActualBaseline(
          TextBaseline.alphabetic,
        );
        final cellW = (cp.width + pad * 2).ceilToDouble();
        final cellH = (cp.height + pad * 2).ceilToDouble();
        if (cellH > maxCellH) maxCellH = cellH;
        sprite = _SpriteGlyph(
          painter: cp,
          cellX: cursorX,
          cellW: cellW,
          cellH: cellH,
          baseline: baseline,
        );
        sprites[ch] = sprite;
        cursorX += cellW;
      }

      final boxes = paragraphPainter.getBoxesForSelection(
        TextSelection(baseOffset: i, extentOffset: i + 1),
      );
      if (boxes.isEmpty) continue;
      final box = boxes.first;
      final midY = (box.top + box.bottom) * 0.5;

      var lineBaseline = box.top + sprite.baseline;
      for (final band in lineBands) {
        if (midY >= band.top && midY <= band.bottom) {
          lineBaseline = band.baseline;
          break;
        }
      }

      final hash = ((i * 2654435761) & 0xFFFF) / 65535.0;
      final angle = hash * math.pi * 2;
      final distance = 14.0 + ((i * 37) % 22);
      glyphs.add(
        _GlyphTarget(
          char: ch,
          target: Offset(box.left, lineBaseline - sprite.baseline),
          scatter: Offset(
            math.cos(angle) * distance,
            math.sin(angle) * distance - 10.0,
          ),
          rotation: (hash - 0.5) * 0.60,
          start: (i / math.max(len, 1)) * 0.45,
        ),
      );
    }

    paragraphPainter.dispose();
    _sprites = sprites;
    _glyphs = glyphs;

    if (cursorX > 0 && maxCellH > 0) {
      _buildAtlasImage(cursorX, maxCellH, dpr);
    }
  }

  Future<void> _buildAtlasImage(
    double logicalW,
    double logicalH,
    double dpr,
  ) async {
    final gen = (_atlasGeneration ?? 0) + 1;
    _atlasGeneration = gen;
    final sprites = _sprites;
    if (sprites == null || sprites.isEmpty) return;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(dpr);
    for (final s in sprites.values) {
      s.painter.paint(canvas, Offset(s.cellX + 2.0, 2.0));
    }

    final picture = recorder.endRecording();
    final imgW = math.max(1, (logicalW * dpr).ceil());
    final imgH = math.max(1, (logicalH * dpr).ceil());
    final image = await picture.toImage(imgW, imgH);
    picture.dispose();

    if (!mounted || gen != _atlasGeneration) {
      image.dispose();
      return;
    }
    _atlasImage?.dispose();
    _atlasImage = image;
    if (widget.revealed) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    final dpr = MediaQuery.devicePixelRatioOf(context).clamp(1.0, 3.0);
    final baseText = Text(widget.text, style: widget.style);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (!widget.revealed) {
          _schedulePreLayout(constraints.maxWidth, textScaler, dpr);
          return IgnorePointer(child: Opacity(opacity: 0, child: baseText));
        }

        if (_disableAnimations) {
          return baseText;
        }

        _ensureLayout(constraints.maxWidth, textScaler, dpr);

        return RepaintBoundary(
          child: Stack(
            children: [
              // Preserves exact paragraph height & accessibility semantics without swapping.
              IgnorePointer(child: Opacity(opacity: 0, child: baseText)),
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _FloatingLettersPainter(
                      progress: _controller,
                      glyphs: _glyphs ?? const [],
                      sprites: _sprites ?? const {},
                      atlasImage: _atlasImage,
                      dpr: dpr,
                      glowColor: widget.glowColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SpriteGlyph {
  const _SpriteGlyph({
    required this.painter,
    required this.cellX,
    required this.cellW,
    required this.cellH,
    required this.baseline,
  });

  final TextPainter painter;
  final double cellX;
  final double cellW;
  final double cellH;
  final double baseline;
}

class _GlyphTarget {
  const _GlyphTarget({
    required this.char,
    required this.target,
    required this.scatter,
    required this.rotation,
    required this.start,
  });

  final String char;
  final Offset target;
  final Offset scatter;
  final double rotation;
  final double start;
}

class _FloatingLettersPainter extends CustomPainter {
  _FloatingLettersPainter({
    required this.progress,
    required this.glyphs,
    required this.sprites,
    required this.atlasImage,
    required this.dpr,
    required this.glowColor,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final List<_GlyphTarget> glyphs;
  final Map<String, _SpriteGlyph> sprites;
  final ui.Image? atlasImage;
  final double dpr;
  final Color glowColor;

  @override
  void paint(Canvas canvas, Size size) {
    final globalT = progress.value;
    if (globalT <= 0 || glyphs.isEmpty) return;

    const span = 0.55;
    final atlas = atlasImage;

    if (atlas != null) {
      _paintWithAtlas(canvas, atlas, globalT, span);
    } else {
      _paintFallback(canvas, globalT, span);
    }
  }

  void _paintWithAtlas(
    Canvas canvas,
    ui.Image atlas,
    double globalT,
    double span,
  ) {
    final transforms = <RSTransform>[];
    final rects = <Rect>[];
    final colors = <Color>[];
    final glowPaint = Paint()..style = PaintingStyle.fill;
    final invDpr = 1.0 / dpr;

    for (final g in glyphs) {
      final raw = ((globalT - g.start) / span).clamp(0.0, 1.0);
      if (raw <= 0) continue;

      final s = sprites[g.char];
      if (s == null) continue;

      final eased = Curves.easeOutCubic.transform(raw);
      final inv = 1.0 - eased;
      final pos = g.target + g.scatter * inv;
      final angle = g.rotation * inv;
      if (eased <= 0.005) continue;

      if (inv > 0.14) {
        glowPaint.color = glowColor.withValues(alpha: 0.26 * inv * raw);
        canvas.drawCircle(
          pos + Offset(s.painter.width * 0.5, s.painter.height * 0.55),
          6.0,
          glowPaint,
        );
      }

      const pad = 2.0;
      final anchorX = (s.cellW * dpr) * 0.5;
      final anchorY = (s.cellH * dpr) * 0.5;
      transforms.add(
        RSTransform.fromComponents(
          rotation: angle,
          scale: invDpr,
          anchorX: anchorX,
          anchorY: anchorY,
          translateX: pos.dx - pad + s.cellW * 0.5,
          translateY: pos.dy - pad + s.cellH * 0.5,
        ),
      );
      rects.add(
        Rect.fromLTWH(
          s.cellX * dpr,
          0,
          s.cellW * dpr,
          s.cellH * dpr,
        ),
      );
      colors.add(Color.fromRGBO(255, 255, 255, eased));
    }

    if (transforms.isNotEmpty) {
      canvas.drawRawAtlas(
        atlas,
        _packTransforms(transforms),
        _packRects(rects),
        _packColors(colors),
        BlendMode.modulate,
        null,
        Paint()..filterQuality = FilterQuality.medium,
      );
    }
  }

  void _paintFallback(
    Canvas canvas,
    double globalT,
    double span,
  ) {
    final glowPaint = Paint()..style = PaintingStyle.fill;
    for (final g in glyphs) {
      final raw = ((globalT - g.start) / span).clamp(0.0, 1.0);
      if (raw <= 0) continue;

      final s = sprites[g.char];
      if (s == null) continue;

      final eased = Curves.easeOutCubic.transform(raw);
      final inv = 1.0 - eased;
      final pos = g.target + g.scatter * inv;
      final angle = g.rotation * inv;
      if (eased <= 0.005) continue;

      if (inv > 0.14) {
        glowPaint.color = glowColor.withValues(alpha: 0.26 * inv * raw);
        canvas.drawCircle(
          pos + Offset(s.painter.width * 0.5, s.painter.height * 0.55),
          6.0,
          glowPaint,
        );
      }

      if (angle.abs() > 0.001) {
        canvas.save();
        canvas.translate(
          pos.dx + s.painter.width * 0.5,
          pos.dy + s.painter.height * 0.5,
        );
        canvas.rotate(angle);
        s.painter.paint(
          canvas,
          Offset(-s.painter.width * 0.5, -s.painter.height * 0.5),
        );
        canvas.restore();
      } else {
        s.painter.paint(canvas, pos);
      }
    }
  }

  static Float32List _packTransforms(List<RSTransform> list) {
    final out = Float32List(list.length * 4);
    for (var i = 0; i < list.length; i++) {
      final t = list[i];
      final o = i * 4;
      out[o] = t.scos;
      out[o + 1] = t.ssin;
      out[o + 2] = t.tx;
      out[o + 3] = t.ty;
    }
    return out;
  }

  static Float32List _packRects(List<Rect> list) {
    final out = Float32List(list.length * 4);
    for (var i = 0; i < list.length; i++) {
      final r = list[i];
      final o = i * 4;
      out[o] = r.left;
      out[o + 1] = r.top;
      out[o + 2] = r.right;
      out[o + 3] = r.bottom;
    }
    return out;
  }

  static Int32List _packColors(List<Color> list) {
    final out = Int32List(list.length);
    for (var i = 0; i < list.length; i++) {
      out[i] = list[i].toARGB32();
    }
    return out;
  }

  @override
  bool shouldRepaint(covariant _FloatingLettersPainter oldDelegate) =>
      oldDelegate.glyphs != glyphs ||
      oldDelegate.atlasImage != atlasImage ||
      oldDelegate.glowColor != glowColor;
}
