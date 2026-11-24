import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';
import '../../core/theme/codex_theme.dart';
import '../../core/theme/codex_tokens.dart';
import '../../widgets/floating_runes_overlay.dart';
import 'arcane_backdrop.dart';
import 'ethereal_mist_overlay.dart';
import 'floating_letters_text.dart';
import 'landing_placeholders.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({
    super.key,
    required this.onEnterArchive,
    required this.onSignUp,
    required this.onSignIn,
  });

  final VoidCallback onEnterArchive;
  final VoidCallback onSignUp;
  final VoidCallback onSignIn;

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with SingleTickerProviderStateMixin {
  late final LandingAtmosphereController _atmosphere;
  late final ScrollController _scrollController;
  final ValueNotifier<double> _scrollOffset = ValueNotifier<double>(0);

  final GlobalKey _descKey = GlobalKey();
  final GlobalKey _sliderKey = GlobalKey();

  bool _descriptionRevealed = false;
  bool _sliderRevealed = false;
  double _lastViewportHeight = 0;

  @override
  void initState() {
    super.initState();
    _atmosphere = LandingAtmosphereController(this)..start(() => mounted);
    _scrollController = ScrollController()..addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateRevealStates());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _atmosphere.disableAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
  }

  void _onScroll() {
    if (!mounted || !_scrollController.hasClients) return;
    _scrollOffset.value = _scrollController.offset;
    _updateRevealStates();
  }

  void _updateRevealStates() {
    if (!mounted || _lastViewportHeight <= 0) return;

    final offset = _scrollController.hasClients ? _scrollController.offset : 0.0;
    final resetToTop = offset <= 24;

    final nextDesc = _computeRevealed(
      _descKey,
      current: _descriptionRevealed,
      resetToTop: resetToTop,
      enterThreshold: _lastViewportHeight * 0.88,
    );
    final nextSlider = _computeRevealed(
      _sliderKey,
      current: _sliderRevealed,
      resetToTop: resetToTop,
      enterThreshold: _lastViewportHeight * 0.92,
    );

    if (nextDesc != _descriptionRevealed || nextSlider != _sliderRevealed) {
      setState(() {
        _descriptionRevealed = nextDesc;
        _sliderRevealed = nextSlider;
      });
    }
  }

  bool _computeRevealed(
    GlobalKey key, {
    required bool current,
    required bool resetToTop,
    required double enterThreshold,
  }) {
    if (resetToTop) return false;
    final ctx = key.currentContext;
    if (ctx == null || !ctx.mounted) return current;
    final renderObj = ctx.findRenderObject();
    if (renderObj is! RenderBox || !renderObj.hasSize) return current;

    final top = renderObj.localToGlobal(Offset.zero).dy;
    if (top < enterThreshold) return true;
    if (top >= _lastViewportHeight * 1.02) return false;
    return current;
  }

  void _scrollToDescription() {
    if (!_scrollController.hasClients) return;
    final target = (_lastViewportHeight * 0.82).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _scrollOffset.dispose();
    _atmosphere.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.codex;
    return Scaffold(
      backgroundColor: p.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: ArcaneBackdrop(
              animation: _atmosphere.controller,
              scrollOffset: _scrollOffset,
            ),
          ),
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _atmosphere.controller,
              builder: (_, _) => EtherealMistOverlay(
                animation: _atmosphere.controller,
                seed: _atmosphere.cycleSeed,
              ),
            ),
          ),
          FloatingRunesOverlay(
            child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                _lastViewportHeight = constraints.maxHeight;
                return SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 680),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const SizedBox(height: 24),
                                Column(
                                  children: [
                                    _BrandHeroHeader(
                                      sealAnimation: _atmosphere.controller,
                                    ),
                                    const SizedBox(height: 26),
                                    _JoinOrganizationCultButton(
                                      onJoin: widget.onSignUp,
                                    ),
                                    const SizedBox(height: 14),
                                    _HighlightedArchiveOption(
                                      onTap: widget.onEnterArchive,
                                    ),
                                    const SizedBox(height: 8),
                                    _SignInTextOption(onTap: widget.onSignIn),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 18,
                                    bottom: 20,
                                  ),
                                  child: _ScrollRevealCue(
                                    onTap: _scrollToDescription,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            key: _descKey,
                            child: AnimatedOpacity(
                              opacity: _descriptionRevealed ? 1 : 0,
                              duration: const Duration(milliseconds: 480),
                              curve: Curves.easeOut,
                              child: AnimatedSlide(
                                offset: _descriptionRevealed
                                    ? Offset.zero
                                    : const Offset(0, 0.06),
                                duration: const Duration(milliseconds: 520),
                                curve: Curves.easeOutCubic,
                                child: _DescriptionSection(
                                  revealed: _descriptionRevealed,
                                ),
                              ),
                            ),
                          ),
                          if (kPlaceholderFeaturedChapters.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            Container(
                              key: _sliderKey,
                              child: AnimatedOpacity(
                                opacity: _sliderRevealed ? 1 : 0,
                                duration: const Duration(milliseconds: 520),
                                curve: Curves.easeOut,
                                child: AnimatedSlide(
                                  offset: _sliderRevealed
                                      ? Offset.zero
                                      : const Offset(0, 0.08),
                                  duration: const Duration(milliseconds: 560),
                                  curve: Curves.easeOutCubic,
                                  child: _FeaturedChaptersSlider(
                                    slides: kPlaceholderFeaturedChapters,
                                    onTapSlide: widget.onEnterArchive,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 52),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            ),
          ),
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _atmosphere.controller,
              builder: (_, _) => EtherealMistOverlay(
                animation: _atmosphere.controller,
                seed: _atmosphere.cycleSeed,
                foreground: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScrollRevealCue extends StatelessWidget {
  const _ScrollRevealCue({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.codex;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'UNCOVER THE ARCHIVE',
                style: CodexTypography.badge(
                  p.textMuted.withValues(alpha: 0.85),
                ).copyWith(letterSpacing: 1.4),
              ),
              const SizedBox(height: 2),
              Icon(
                Icons.keyboard_arrow_down,
                size: 18,
                color: p.accent.withValues(alpha: 0.85),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandHeroHeader extends StatelessWidget {
  const _BrandHeroHeader({required this.sealAnimation});

  final Animation<double> sealAnimation;

  @override
  Widget build(BuildContext context) {
    final p = context.codex;
    final violet = AnomalyClass.cursed.color;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isWide = screenWidth >= 520;
    final sealSize = (screenWidth - 16).clamp(160.0, isWide ? 370.0 : 330.0);
    final logoSize = isWide ? 168.0 : 148.0;

    return Column(
      children: [
        SizedBox(
          width: logoSize + 44,
          height: logoSize + 44,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              OverflowBox(
                minWidth: sealSize,
                maxWidth: sealSize,
                minHeight: sealSize,
                maxHeight: sealSize,
                child: ArcaneSealRing(
                  animation: sealAnimation,
                  size: sealSize,
                ),
              ),
              Image.asset(
                'assets/images/codexlogo.png',
                width: logoSize,
                height: logoSize,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => Icon(
                  Icons.auto_stories,
                  size: logoSize * 0.55,
                  color: p.accent,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: _ArcaneLavaTitle(
            text: kLandingHeadline,
            baseColor: p.textPrimary,
            fontSize: isWide ? 44 : 34,
            letterSpacing: isWide ? 4.4 : 3.0,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _OrnamentLine(color: violet.withValues(alpha: 0.65)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                '✦  ᛟ  ✦',
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 2.0,
                  color: p.accent.withValues(alpha: 0.85),
                ),
              ),
            ),
            _OrnamentLine(color: violet.withValues(alpha: 0.65)),
          ],
        ),
      ],
    );
  }
}

class _ArcaneLavaTitle extends StatefulWidget {
  const _ArcaneLavaTitle({
    required this.text,
    required this.baseColor,
    required this.fontSize,
    required this.letterSpacing,
  });

  final String text;
  final Color baseColor;
  final double fontSize;
  final double letterSpacing;

  @override
  State<_ArcaneLavaTitle> createState() => _ArcaneLavaTitleState();
}

class _ArcaneLavaTitleState extends State<_ArcaneLavaTitle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final math.Random _rng = math.Random();
  List<_LavaBlob> _blobs = const [];
  Timer? _initialTimer;
  Timer? _periodicTimer;
  bool _disableAnimations = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    );
    _initialTimer = Timer(const Duration(milliseconds: 1800), _triggerLavaGlow);
    _periodicTimer = Timer.periodic(
      const Duration(milliseconds: 8000),
      (_) => _triggerLavaGlow(),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _disableAnimations = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
  }

  void _triggerLavaGlow() {
    if (!mounted || _disableAnimations || _controller.isAnimating) return;
    setState(() {
      _blobs = List.generate(4, (i) {
        final leftToRight = _rng.nextBool();
        final x0 = leftToRight
            ? 0.08 + _rng.nextDouble() * 0.35
            : 0.57 + _rng.nextDouble() * 0.35;
        final x1 = leftToRight
            ? 0.55 + _rng.nextDouble() * 0.40
            : 0.05 + _rng.nextDouble() * 0.40;
        return _LavaBlob(
          x0: x0,
          y0: 0.15 + _rng.nextDouble() * 0.70,
          dx: x1 - x0,
          dy: (_rng.nextDouble() - 0.5) * 0.65,
          radius: 36.0 + _rng.nextDouble() * 34.0,
          phase: _rng.nextDouble() * math.pi * 2,
          isIvory: i.isOdd,
        );
      });
    });
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _initialTimer?.cancel();
    _periodicTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: _LavaGlowMask(
        progress: _controller,
        blobs: _blobs,
        child: Text(
          widget.text,
          textAlign: TextAlign.center,
          style: CodexTypography.screenTitle(widget.baseColor).copyWith(
            fontSize: widget.fontSize,
            fontWeight: FontWeight.w800,
            letterSpacing: widget.letterSpacing,
            height: 1.15,
          ),
        ),
      ),
    );
  }
}

class _LavaBlob {
  const _LavaBlob({
    required this.x0,
    required this.y0,
    required this.dx,
    required this.dy,
    required this.radius,
    required this.phase,
    required this.isIvory,
  });

  final double x0;
  final double y0;
  final double dx;
  final double dy;
  final double radius;
  final double phase;
  final bool isIvory;
}

/// Masks drifting lava-lamp radial blobs directly onto [child]'s exact painted
/// glyph pixels via [BlendMode.srcATop] so layout never shifts or rebuilds.
class _LavaGlowMask extends SingleChildRenderObjectWidget {
  const _LavaGlowMask({
    required this.progress,
    required this.blobs,
    required super.child,
  });

  final Animation<double> progress;
  final List<_LavaBlob> blobs;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderLavaGlowMask(progress, blobs);

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderLavaGlowMask renderObject,
  ) {
    renderObject
      ..progress = progress
      ..blobs = blobs;
  }
}

class _RenderLavaGlowMask extends RenderProxyBox {
  _RenderLavaGlowMask(this._progress, this._blobs);

  Animation<double> _progress;
  List<_LavaBlob> _blobs;

  set progress(Animation<double> value) {
    if (_progress == value) return;
    if (attached) _progress.removeListener(markNeedsPaint);
    _progress = value;
    if (attached) _progress.addListener(markNeedsPaint);
    markNeedsPaint();
  }

  set blobs(List<_LavaBlob> value) {
    if (_blobs == value) return;
    _blobs = value;
    markNeedsPaint();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _progress.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _progress.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child == null) return;

    final t = _progress.value;
    if (t <= 0 || t >= 1 || _blobs.isEmpty || size.isEmpty) {
      context.paintChild(child, offset);
      return;
    }

    final envelope = math.pow(math.sin(t * math.pi), 0.65).toDouble();
    final canvas = context.canvas;
    canvas.saveLayer(offset & size, Paint());
    context.paintChild(child, offset);

    final blobPaint = Paint()..blendMode = BlendMode.srcATop;
    for (final b in _blobs) {
      final cx =
          offset.dx +
          size.width *
              (b.x0 + b.dx * t + 0.05 * math.sin(t * math.pi * 2 + b.phase));
      final cy =
          offset.dy +
          size.height *
              (b.y0 + b.dy * t + 0.22 * math.cos(t * math.pi * 2 + b.phase));
      final radius =
          b.radius * (0.85 + 0.28 * math.sin(t * math.pi * 3 + b.phase));
      final center = Offset(cx, cy);

      final colors = b.isIvory
          ? [
              Colors.white.withValues(alpha: 0.96 * envelope),
              const Color(0xFFFFF1B8).withValues(alpha: 0.85 * envelope),
              const Color(0xFFFFD873).withValues(alpha: 0.35 * envelope),
              Colors.transparent,
            ]
          : [
              const Color(0xFFF3E2FF).withValues(alpha: 0.96 * envelope),
              const Color(0xFFC582FF).withValues(alpha: 0.88 * envelope),
              const Color(0xFF964BFF).withValues(alpha: 0.38 * envelope),
              Colors.transparent,
            ];

      blobPaint.shader = ui.Gradient.radial(
        center,
        radius,
        colors,
        const [0.0, 0.38, 0.72, 1.0],
      );
      canvas.drawCircle(center, radius, blobPaint);
    }

    canvas.restore();
  }
}

class _OrnamentLine extends StatelessWidget {
  const _OrnamentLine({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Flexible(
    child: Container(
      constraints: const BoxConstraints(maxWidth: 42),
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.transparent, color, Colors.transparent],
        ),
      ),
    ),
  );
}

class _JoinOrganizationCultButton extends StatefulWidget {
  const _JoinOrganizationCultButton({required this.onJoin});

  final VoidCallback onJoin;

  @override
  State<_JoinOrganizationCultButton> createState() =>
      _JoinOrganizationCultButtonState();
}

class _JoinOrganizationCultButtonState
    extends State<_JoinOrganizationCultButton> {
  static const _sinisterBg = Color(0xFF22070A);
  static const _sinisterBorder = Color(0xFFB81D24);
  static const _sinisterText = Color(0xFFFFD8D8);

  bool _hovered = false;
  bool _activating = false;
  Timer? _navTimer;

  bool get _isSinister => _hovered || _activating;

  void _handleTap() {
    if (_activating) return;
    setState(() => _activating = true);
    _navTimer?.cancel();
    _navTimer = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      setState(() => _activating = false);
      widget.onJoin();
    });
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.codex;
    final sinister = _isSinister;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            onTap: _handleTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: sinister ? _sinisterBg : p.accent,
                borderRadius: BorderRadius.circular(sinister ? 2 : 6),
                border: Border.all(
                  color: sinister ? _sinisterBorder : p.accent,
                  width: sinister ? 1.4 : 1.0,
                ),
                boxShadow: sinister
                    ? [
                        BoxShadow(
                          color: _sinisterBorder.withValues(alpha: 0.50),
                          blurRadius: 20,
                          spreadRadius: 1,
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: p.accent.withValues(alpha: 0.25),
                          blurRadius: 14,
                          offset: const Offset(0, 3),
                        ),
                      ],
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: sinister
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_activating) ...[
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.8,
                                color: _sinisterText,
                              ),
                            ),
                            const SizedBox(width: 10),
                          ] else ...[
                            const Text(
                              'ᛟ',
                              style: TextStyle(
                                fontSize: 13,
                                color: _sinisterBorder,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            'Join the Cult',
                            style: CodexTypography.screenTitle(_sinisterText)
                                .copyWith(
                                  fontSize: 14,
                                  letterSpacing: 1.8,
                                ),
                          ),
                          if (!_activating) ...[
                            const SizedBox(width: 8),
                            const Text(
                              'ᛟ',
                              style: TextStyle(
                                fontSize: 13,
                                color: _sinisterBorder,
                              ),
                            ),
                          ],
                        ],
                      )
                    : Text(
                        'Join the Organization',
                        textAlign: TextAlign.center,
                        style: CodexTypography.button(
                          p.onAccent,
                        ).copyWith(fontSize: 14, letterSpacing: 0.5),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HighlightedArchiveOption extends StatefulWidget {
  const _HighlightedArchiveOption({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_HighlightedArchiveOption> createState() =>
      _HighlightedArchiveOptionState();
}

class _HighlightedArchiveOptionState extends State<_HighlightedArchiveOption> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final p = context.codex;
    return Center(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 5,
              children: [
                Text('or', style: CodexTypography.body(p.textMuted)),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: p.accent.withValues(alpha: _hovered ? 0.24 : 0.13),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Browse the Grand Archive',
                    style: CodexTypography.button(p.accent).copyWith(
                      decoration: TextDecoration.underline,
                      decorationColor: p.accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SignInTextOption extends StatelessWidget {
  const _SignInTextOption({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.codex;
    return Center(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: Text(
              'Already marked? Initiate Sign In',
              style: CodexTypography.metadata(p.textMuted).copyWith(
                decoration: TextDecoration.underline,
                decorationColor: p.textMuted.withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DescriptionSection extends StatelessWidget {
  const _DescriptionSection({required this.revealed});

  final bool revealed;

  @override
  Widget build(BuildContext context) {
    final p = context.codex;
    final violet = AnomalyClass.cursed.color;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: p.surface.withValues(alpha: 0.80),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: p.border.withValues(alpha: 0.9)),
        boxShadow: [
          BoxShadow(
            color: violet.withValues(alpha: 0.10),
            blurRadius: 22,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('◆', style: TextStyle(fontSize: 10, color: p.accent)),
              const SizedBox(width: 8),
              Text(
                'ABOUT CODEX CATALOGUE',
                style: CodexTypography.dossierTitle(p.accent),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FloatingLettersText(
            text: kLandingDescriptionPlaceholder,
            style: CodexTypography.transcript(p.textPrimary, fontSize: 16),
            glowColor: violet,
            revealed: revealed,
          ),
        ],
      ),
    );
  }
}

class _FeaturedChaptersSlider extends StatefulWidget {
  const _FeaturedChaptersSlider({
    required this.slides,
    required this.onTapSlide,
  });

  final List<FeaturedChapterSlide> slides;
  final VoidCallback onTapSlide;

  @override
  State<_FeaturedChaptersSlider> createState() =>
      _FeaturedChaptersSliderState();
}

class _FeaturedChaptersSliderState extends State<_FeaturedChaptersSlider> {
  late final PageController _pageController;
  Timer? _autoPlayTimer;
  int _currentIndex = 0;
  bool _paused = false;
  bool _disableAnimations = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92);
    if (widget.slides.length > 1) {
      _autoPlayTimer = Timer.periodic(
        const Duration(seconds: 5),
        (_) => _advanceAutoPlay(),
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _disableAnimations = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
  }

  void _advanceAutoPlay() {
    if (!mounted ||
        _paused ||
        _disableAnimations ||
        !_pageController.hasClients) {
      return;
    }
    final next = (_currentIndex + 1) % widget.slides.length;
    _goToPage(next);
  }

  void _goToPage(int index) {
    if (!_pageController.hasClients) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.codex;
    final count = widget.slides.length;

    return MouseRegion(
      onEnter: (_) => _paused = true,
      onExit: (_) => _paused = false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Row(
              children: [
                Text('ᛟ', style: TextStyle(fontSize: 12, color: p.accent)),
                const SizedBox(width: 6),
                Text(
                  'FEATURED CHAPTERS',
                  style: CodexTypography.artifactId(p.accent),
                ),
                const Spacer(),
                if (count > 1) ...[
                  _SliderArrowButton(
                    icon: Icons.chevron_left,
                    onTap: () => _goToPage((_currentIndex - 1 + count) % count),
                  ),
                  const SizedBox(width: 6),
                  _SliderArrowButton(
                    icon: Icons.chevron_right,
                    onTap: () => _goToPage((_currentIndex + 1) % count),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 204,
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollStartNotification &&
                    notification.dragDetails != null) {
                  _paused = true;
                } else if (notification is ScrollEndNotification) {
                  _paused = false;
                }
                return false;
              },
              child: PageView.builder(
                controller: _pageController,
                itemCount: count,
                onPageChanged: (index) => setState(() => _currentIndex = index),
                itemBuilder: (context, index) {
                  final slide = widget.slides[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: _FeaturedChapterCard(
                      slide: slide,
                      onTap: widget.onTapSlide,
                    ),
                  );
                },
              ),
            ),
          ),
          if (count > 1) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(count, (index) {
                final active = index == _currentIndex;
                return GestureDetector(
                  onTap: () => _goToPage(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 20 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: active ? p.accent : p.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }
}

class _SliderArrowButton extends StatelessWidget {
  const _SliderArrowButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.codex;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: p.surface.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: p.border),
        ),
        child: Icon(icon, size: 16, color: p.textPrimary),
      ),
    );
  }
}

class _FeaturedChapterCard extends StatelessWidget {
  const _FeaturedChapterCard({required this.slide, required this.onTap});

  final FeaturedChapterSlide slide;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.codex;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              p.surface.withValues(alpha: 0.88),
              Color.lerp(
                p.surface,
                slide.anomalyClass.color,
                0.08,
              )!.withValues(alpha: 0.88),
            ],
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Color.lerp(p.border, slide.anomalyClass.color, 0.30)!,
          ),
          boxShadow: [
            BoxShadow(
              color: slide.anomalyClass.color.withValues(alpha: 0.14),
              blurRadius: 16,
              spreadRadius: 0.5,
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: slide.anomalyClass.color,
                boxShadow: [
                  BoxShadow(
                    color: slide.anomalyClass.color.withValues(alpha: 0.65),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            slide.chapterLabel,
                            style: CodexTypography.artifactId(p.accent),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: p.pillSurface.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: p.border),
                          ),
                          child: Text(
                            slide.originTag,
                            style: CodexTypography.badge(p.textMuted),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      slide.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: CodexTypography.cardTitle(p.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Text(
                        slide.synopsis,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: CodexTypography.body(p.textMuted),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Inspect in Archive →',
                      style: CodexTypography.badge(p.accent),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
