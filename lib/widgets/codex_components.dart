import 'dart:ui';
import 'package:material_ui/material_ui.dart';
import '../core/theme/codex_theme.dart';
import '../core/theme/codex_tokens.dart';
import '../models/artifact.dart';

void showCodexToast(BuildContext context, String message) {
  final p = context.codex;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: p.textPrimary,
        elevation: 0,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: CodexTypography.button(p.background),
        ),
      ),
    );
}

class CodexChip extends StatefulWidget {
  const CodexChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.dotColor,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? dotColor;

  @override
  State<CodexChip> createState() => _CodexChipState();
}

class _CodexChipState extends State<CodexChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final p = context.codex;
    final bg = widget.selected
        ? p.accent
        : (_hovered ? p.pillSurface : p.surface.withValues(alpha: 0.85));
    final border = widget.selected
        ? p.accent
        : (_hovered ? p.accent.withValues(alpha: 0.55) : p.border);
    final fg = widget.selected ? p.onAccent : p.textPrimary;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.dotColor != null) ...[
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: widget.dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Text(widget.label, style: CodexTypography.chip(fg)),
            ],
          ),
        ),
      ),
    );
  }
}

class CodexButton extends StatefulWidget {
  const CodexButton({
    super.key,
    required this.label,
    required this.onTap,
    this.filled = true,
    this.mutedOutline = false,
    this.dangerOutline = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool filled;
  final bool mutedOutline;
  final bool dangerOutline;

  @override
  State<CodexButton> createState() => _CodexButtonState();
}

class _CodexButtonState extends State<CodexButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final p = context.codex;
    final borderColor = widget.dangerOutline
        ? p.danger
        : widget.mutedOutline
        ? (_hovered ? p.accent.withValues(alpha: 0.65) : p.border)
        : p.accent;
    final textColor = widget.filled
        ? p.onAccent
        : widget.dangerOutline
        ? p.danger
        : widget.mutedOutline
        ? (_hovered ? p.textPrimary : p.textMuted)
        : p.accent;
    final bgColor = widget.filled
        ? (_hovered ? Color.lerp(p.accent, Colors.white, 0.10)! : p.accent)
        : (_hovered ? borderColor.withValues(alpha: 0.10) : Colors.transparent);

    return MouseRegion(
      cursor: widget.onTap == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: double.infinity,
          padding: const EdgeInsets.all(11),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: borderColor),
          ),
          child: Text(widget.label, style: CodexTypography.button(textColor)),
        ),
      ),
    );
  }
}

class CodexIconPillButton extends StatefulWidget {
  const CodexIconPillButton({
    super.key,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  State<CodexIconPillButton> createState() => _CodexIconPillButtonState();
}

class _CodexIconPillButtonState extends State<CodexIconPillButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final p = context.codex;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: widget.active
                ? p.accent
                : (_hovered ? p.pillSurface : p.surface.withValues(alpha: 0.86)),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.active
                  ? p.accent
                  : (_hovered ? p.accent.withValues(alpha: 0.55) : p.border),
            ),
          ),
          child: Text(
            widget.label,
            style: CodexTypography.body(
              widget.active ? p.onAccent : p.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class ArtifactCard extends StatefulWidget {
  const ArtifactCard({
    super.key,
    required this.artifact,
    required this.onTap,
  });

  final Artifact artifact;
  final VoidCallback onTap;

  @override
  State<ArtifactCard> createState() => _ArtifactCardState();
}

class _ArtifactCardState extends State<ArtifactCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final p = context.codex;
    final art = widget.artifact;
    final isDark = p.mode == CodexThemeMode.dark;
    final classColor = art.anomalyClass.color;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                p.surface.withValues(alpha: isDark ? 0.86 : 0.94),
                Color.lerp(
                  p.surface,
                  classColor,
                  _hovered ? 0.11 : 0.05,
                )!.withValues(alpha: isDark ? 0.88 : 0.94),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _hovered
                  ? Color.lerp(p.border, classColor, 0.55)!
                  : p.border,
            ),
            boxShadow: [
              BoxShadow(
                color: classColor.withValues(
                  alpha: _hovered ? (isDark ? 0.18 : 0.10) : 0.06,
                ),
                blurRadius: _hovered ? 18 : 10,
                spreadRadius: _hovered ? 0.5 : 0,
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: classColor,
                    boxShadow: [
                      BoxShadow(
                        color: classColor.withValues(alpha: 0.55),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(13, 13, 13, 13),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                art.bracketedCode,
                                style: CodexTypography.artifactId(p.accent),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: classColor.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: classColor.withValues(alpha: 0.5),
                                ),
                              ),
                              child: Text(
                                art.anomalyClass.label,
                                style: CodexTypography.badge(classColor),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          art.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: CodexTypography.cardTitle(p.textPrimary),
                        ),
                        const Spacer(),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    'Discovered in ${art.historicalOrigin}',
                                    style: CodexTypography.metadata(p.textMuted),
                                  ),
                                  if (art.isOfficialCanon)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: p.pillSurface,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: p.accent),
                                      ),
                                      child: Text(
                                        'Canon',
                                        style: CodexTypography.badge(p.accent),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: p.pillSurface,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                art.signedRating,
                                style: CodexTypography.chip(
                                  art.rating < 0 ? p.danger : p.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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

class CorruptedVisionFallback extends StatelessWidget {
  const CorruptedVisionFallback({super.key, this.height = 150});

  final double height;

  @override
  Widget build(BuildContext context) {
    final p = context.codex;
    return Container(
      height: height,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: p.border),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              11,
              (i) => Container(
                height: 4,
                width: double.infinity,
                color: p.border.withValues(alpha: i.isEven ? 0.35 : 0.15),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: p.background.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: p.danger.withValues(alpha: 0.7)),
            ),
            child: Text(
              '[VISION FRAGMENT CORRUPTED]\nVISUAL DATA REDACTED',
              textAlign: TextAlign.center,
              style: CodexTypography.fallbackCaption(p.danger),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> showTruthGateDialog(
  BuildContext context, {
  required VoidCallback onSignUp,
  required VoidCallback onSignIn,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Truth Gate',
    barrierColor: Colors.transparent,
    pageBuilder: (ctx, _, _) {
      final p = ctx.codex;
      return Material(
        color: Colors.transparent,
        child: Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              onTap: () => Navigator.of(ctx).pop(),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                child: Container(color: p.background.withValues(alpha: 0.84)),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: p.surface.withValues(alpha: 0.96),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: p.danger.withValues(alpha: 0.85)),
                      boxShadow: [
                        BoxShadow(
                          color: p.danger.withValues(alpha: 0.24),
                          blurRadius: 28,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/codexlogo.png',
                          width: 48,
                          height: 48,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => Text(
                            '⚠',
                            style: TextStyle(fontSize: 28, color: p.accent),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Not Eligible to see the ᛏᚱᚢᛏᚺ',
                          textAlign: TextAlign.center,
                          style: CodexTypography.warningHeading(p.danger),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Uninitiated guests are barred from reading Clairvoyance memory transcripts. Sign up to receive The Mark of Codex Catalogue and unlock the archives.',
                          textAlign: TextAlign.center,
                          style: CodexTypography.body(p.textMuted),
                        ),
                        const SizedBox(height: 16),
                        CodexButton(
                          label: 'Sign up to receive The Mark',
                          onTap: () {
                            Navigator.of(ctx).pop();
                            onSignUp();
                          },
                        ),
                        const SizedBox(height: 8),
                        CodexButton(
                          label: 'Sign in to existing account',
                          filled: false,
                          onTap: () {
                            Navigator.of(ctx).pop();
                            onSignIn();
                          },
                        ),
                        const SizedBox(height: 8),
                        CodexButton(
                          label: 'Back to archive',
                          filled: false,
                          mutedOutline: true,
                          onTap: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
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
