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

class CodexChip extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final p = context.codex;
    final bg = selected ? p.accent : p.surface;
    final border = selected ? p.accent : p.border;
    final fg = selected ? p.onAccent : p.textPrimary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dotColor != null) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(label, style: CodexTypography.chip(fg)),
          ],
        ),
      ),
    );
  }
}

class CodexButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final p = context.codex;
    final borderColor =
        dangerOutline
            ? p.danger
            : mutedOutline
            ? p.border
            : p.accent;
    final textColor =
        filled
            ? p.onAccent
            : dangerOutline
            ? p.danger
            : mutedOutline
            ? p.textMuted
            : p.accent;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(11),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? p.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: borderColor),
        ),
        child: Text(label, style: CodexTypography.button(textColor)),
      ),
    );
  }
}

class CodexIconPillButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final p = context.codex;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: active ? p.accent : p.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: active ? p.accent : p.border),
        ),
        child: Text(
          label,
          style: CodexTypography.body(active ? p.onAccent : p.textPrimary),
        ),
      ),
    );
  }
}

class ArtifactCard extends StatelessWidget {
  const ArtifactCard({
    super.key,
    required this.artifact,
    required this.onTap,
  });

  final Artifact artifact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.codex;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: p.border),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: artifact.anomalyClass.color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 13, 13, 13),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        artifact.bracketedCode,
                        style: CodexTypography.artifactId(p.accent),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        artifact.title,
                        style: CodexTypography.cardTitle(p.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  'Discovered in ${artifact.historicalOrigin}',
                                  style: CodexTypography.metadata(p.textMuted),
                                ),
                                if (artifact.isOfficialCanon)
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
                              artifact.signedRating,
                              style: CodexTypography.chip(
                                artifact.rating < 0 ? p.danger : p.textMuted,
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
                filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                child: Container(color: p.background.withValues(alpha: 0.82)),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(19),
                  decoration: BoxDecoration(
                    color: p.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: p.danger),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '⚠',
                        style: TextStyle(fontSize: 26, color: p.accent),
                      ),
                      const SizedBox(height: 6),
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
                      const SizedBox(height: 14),
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
          ],
        ),
      );
    },
  );
}
