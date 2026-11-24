import 'dart:io';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/codex_theme.dart';
import '../../core/theme/codex_tokens.dart';
import '../../models/artifact.dart';
import '../../providers/codex_providers.dart';
import '../../widgets/codex_ambient_shell.dart';
import '../../widgets/codex_components.dart';
import '../transcribe/transcribe_screen.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({super.key, required this.artifact});

  final Artifact artifact;

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  bool _bypassFlagOverlay = false;

  @override
  Widget build(BuildContext context) {
    final globalMode = ref.watch(globalThemeModeProvider);
    final readerMode = ref.watch(readerThemeOverrideProvider) ?? globalMode;
    final fontSize = ref.watch(readerFontSizeProvider);
    final vaultMap = ref.watch(vaultProvider);
    final user = ref.watch(currentUserProvider).valueOrNull;

    final liveArtifactStream =
        ref.watch(firebaseReadyProvider)
            ? ref
                .watch(firestoreServiceProvider)
                .watchArtifactById(widget.artifact.id)
            : Stream.value(widget.artifact);

    return Theme(
      data: CodexTheme.build(readerMode),
      child: StreamBuilder<Artifact?>(
        stream: liveArtifactStream,
        initialData: widget.artifact,
        builder: (context, snap) {
          final art = snap.data ?? widget.artifact;
          final p = context.codex;
          final vaultEntry = vaultMap[art.id];
          final isBookmarked = vaultEntry?.isBookmarked ?? false;
          final isOffline = vaultEntry?.isOfflineSaved ?? false;
          final showFlagged = art.isFlagged && !_bypassFlagOverlay;
          final canRevise =
              user != null && (user.uid == art.authorId || user.role.isCouncil);

          return Scaffold(
            backgroundColor: p.background,
            body: CodexAmbientBackground(
              child: SafeArea(
                child: Stack(
                  children: [
                    SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 86),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 740),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            CodexIconPillButton(
                              label: '‹ Archive',
                              onTap: () => Navigator.of(context).pop(),
                            ),
                            Row(
                              children: [
                                CodexIconPillButton(
                                  label: isBookmarked ? '★' : '☆',
                                  active: isBookmarked,
                                  onTap: () async {
                                    final next = await ref
                                        .read(vaultProvider.notifier)
                                        .toggleBookmark(art);
                                    if (user != null &&
                                        ref.read(firebaseReadyProvider)) {
                                      await ref
                                          .read(firestoreServiceProvider)
                                          .toggleUserBookmark(
                                            userId: user.uid,
                                            artifactId: art.id,
                                            bookmark: next,
                                          );
                                    }
                                    if (context.mounted) {
                                      showCodexToast(
                                        context,
                                        next
                                            ? 'Bookmarked'
                                            : 'Removed bookmark',
                                      );
                                    }
                                  },
                                ),
                                const SizedBox(width: 6),
                                CodexIconPillButton(
                                  label: '⇩',
                                  active: isOffline,
                                  onTap: () async {
                                    final next = await ref
                                        .read(vaultProvider.notifier)
                                        .toggleOffline(art);
                                    if (context.mounted) {
                                      showCodexToast(
                                        context,
                                        next
                                            ? 'Saved for offline reading'
                                            : 'Removed offline copy',
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _DossierHeaderCard(artifact: art),
                        const SizedBox(height: 14),
                        _RelicVisualFrame(
                          artifact: art,
                          localImagePath: vaultEntry?.localImagePath,
                        ),
                        const SizedBox(height: 16),
                        for (final para in art.chapterContent
                            .split(RegExp(r'\n\s*\n'))
                            .where((s) => s.trim().isNotEmpty)) ...[
                          Text(
                            para.trim(),
                            style: CodexTypography.transcript(
                              p.textPrimary,
                              fontSize: fontSize,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        const SizedBox(height: 8),
                        _VoteBar(artifact: art, userId: user?.uid),
                      ],
                    ),
                        ),
                      ),
                    ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 14,
                    child: Center(
                      child: _FloatingReaderToolbar(
                        activeMode: readerMode,
                        onDecreaseFont: () {
                          final next =
                              fontSize >= 21 ? 17.0 : (fontSize <= 13 ? 13.0 : 13.0);
                          ref.read(readerFontSizeProvider.notifier).state = next;
                        },
                        onIncreaseFont: () {
                          final next =
                              fontSize <= 13 ? 17.0 : (fontSize >= 21 ? 21.0 : 21.0);
                          ref.read(readerFontSizeProvider.notifier).state = next;
                        },
                        onSelectMode: (m) =>
                            ref
                                .read(readerThemeOverrideProvider.notifier)
                                .state = m,
                      ),
                    ),
                  ),
                  if (showFlagged)
                    Positioned.fill(
                      child: _FlaggedAnomalyOverlay(
                        rating: art.rating,
                        canRevise: canRevise,
                        onProceed: () =>
                            setState(() => _bypassFlagOverlay = true),
                        onRevise: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) =>
                                  StudioWizardScreen(initialArtifact: art),
                            ),
                          );
                        },
                        onBack: () => Navigator.of(context).pop(),
                      ),
                    ),
                ],
              ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DossierHeaderCard extends StatelessWidget {
  const _DossierHeaderCard({required this.artifact});

  final Artifact artifact;

  @override
  Widget build(BuildContext context) {
    final p = context.codex;
    return CodexSectionCard(
      padding: const EdgeInsets.all(15),
      glowColor: artifact.anomalyClass.color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                artifact.bracketedCode,
                style: CodexTypography.dossierTitle(p.textPrimary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: artifact.anomalyClass.color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: artifact.anomalyClass.color),
                ),
                child: Text(
                  artifact.anomalyClass.label,
                  style: CodexTypography.badge(artifact.anomalyClass.color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _DossierRow(label: 'Origin', value: artifact.historicalOrigin),
          const SizedBox(height: 4),
          _DossierRow(
            label: 'Recovered by',
            value:
                artifact.adventurerRecoveryNote.trim().isEmpty
                    ? 'REDACTED'
                    : artifact.adventurerRecoveryNote,
          ),
          const SizedBox(height: 4),
          _DossierRow(label: 'Catalogued by', value: artifact.clairvoyanceName),
        ],
      ),
    );
  }
}

class _DossierRow extends StatelessWidget {
  const _DossierRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final p = context.codex;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 88,
          child: Text(label, style: CodexTypography.dossierLabel(p.textMuted)),
        ),
        Expanded(
          child: Text(
            value,
            style: CodexTypography.dossierLabel(p.textPrimary),
          ),
        ),
      ],
    );
  }
}

class _RelicVisualFrame extends StatelessWidget {
  const _RelicVisualFrame({required this.artifact, this.localImagePath});

  final Artifact artifact;
  final String? localImagePath;

  @override
  Widget build(BuildContext context) {
    final p = context.codex;
    if (localImagePath != null && File(localImagePath!).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Container(
          height: 150,
          decoration: BoxDecoration(
            border: Border.all(color: p.accent),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Image.file(
            File(localImagePath!),
            height: 150,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const CorruptedVisionFallback(),
          ),
        ),
      );
    }

    final url = artifact.primaryImageUrl;
    if (url == null) return const CorruptedVisionFallback();

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          border: Border.all(color: p.accent),
          borderRadius: BorderRadius.circular(6),
        ),
        child: CachedNetworkImage(
          imageUrl: url,
          height: 150,
          width: double.infinity,
          fit: BoxFit.cover,
          placeholder: (_, _) => Container(
            height: 150,
            color: p.surface,
            alignment: Alignment.center,
            child: CircularProgressIndicator(color: p.accent),
          ),
          errorWidget: (_, _, _) => const CorruptedVisionFallback(),
        ),
      ),
    );
  }
}

class _VoteBar extends ConsumerWidget {
  const _VoteBar({required this.artifact, this.userId});

  final Artifact artifact;
  final String? userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.codex;
    final ready = ref.watch(firebaseReadyProvider);
    final voteStream =
        ready && userId != null
            ? ref
                .watch(firestoreServiceProvider)
                .watchUserVote(artifact.id, userId!)
            : Stream.value(0);

    return StreamBuilder<int>(
      stream: voteStream,
      initialData: 0,
      builder: (context, snap) {
        final myVote = snap.data ?? 0;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'Rate this chapter',
                  style: CodexTypography.metadata(p.textMuted),
                ),
                const SizedBox(width: 8),
                CodexIconPillButton(
                  label: '▲',
                  active: myVote == 1,
                  onTap: () {
                    if (userId != null && ready) {
                      ref.read(firestoreServiceProvider).castVote(
                        artifactId: artifact.id,
                        userId: userId!,
                        voteValue: 1,
                      );
                    }
                  },
                ),
                const SizedBox(width: 6),
                CodexIconPillButton(
                  label: '▼',
                  active: myVote == -1,
                  onTap: () {
                    if (userId != null && ready) {
                      ref.read(firestoreServiceProvider).castVote(
                        artifactId: artifact.id,
                        userId: userId!,
                        voteValue: -1,
                      );
                    }
                  },
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
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
        );
      },
    );
  }
}

class _FloatingReaderToolbar extends StatelessWidget {
  const _FloatingReaderToolbar({
    required this.activeMode,
    required this.onDecreaseFont,
    required this.onIncreaseFont,
    required this.onSelectMode,
  });

  final CodexThemeMode activeMode;
  final VoidCallback onDecreaseFont;
  final VoidCallback onIncreaseFont;
  final ValueChanged<CodexThemeMode> onSelectMode;

  @override
  Widget build(BuildContext context) {
    final p = context.codex;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: p.pillSurface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: p.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToolbarItem(label: 'A−', active: false, onTap: onDecreaseFont),
          _ToolbarItem(label: 'A+', active: false, onTap: onIncreaseFont),
          _ToolbarItem(
            label: 'Dark',
            active: activeMode == CodexThemeMode.dark,
            onTap: () => onSelectMode(CodexThemeMode.dark),
          ),
          _ToolbarItem(
            label: 'Light',
            active: activeMode == CodexThemeMode.light,
            onTap: () => onSelectMode(CodexThemeMode.light),
          ),
          _ToolbarItem(
            label: 'Papyrus',
            active: activeMode == CodexThemeMode.papyrus,
            onTap: () => onSelectMode(CodexThemeMode.papyrus),
          ),
        ],
      ),
    );
  }
}

class _ToolbarItem extends StatelessWidget {
  const _ToolbarItem({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.codex;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: active ? p.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: CodexTypography.dossierLabel(
            active ? p.onAccent : p.textPrimary,
            active: active,
          ),
        ),
      ),
    );
  }
}

class _FlaggedAnomalyOverlay extends StatelessWidget {
  const _FlaggedAnomalyOverlay({
    required this.rating,
    required this.canRevise,
    required this.onProceed,
    required this.onRevise,
    required this.onBack,
  });

  final int rating;
  final bool canRevise;
  final VoidCallback onProceed;
  final VoidCallback onRevise;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final p = context.codex;
    final signed = rating >= 0 ? '+$rating' : '−${rating.abs()}';
    return Stack(
      fit: StackFit.expand,
      children: [
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
          child: Container(color: p.background.withValues(alpha: 0.80)),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
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
                  Text('⚠', style: TextStyle(fontSize: 26, color: p.accent)),
                  const SizedBox(height: 6),
                  Text(
                    'Flagged anomaly',
                    style: CodexTypography.warningHeading(p.danger),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Readers rated this chapter $signed, below the visibility threshold.',
                    textAlign: TextAlign.center,
                    style: CodexTypography.body(p.textMuted),
                  ),
                  const SizedBox(height: 12),
                  CodexButton(label: 'Proceed anyway', onTap: onProceed),
                  if (canRevise) ...[
                    const SizedBox(height: 8),
                    CodexButton(
                      label: 'Revise transcription',
                      filled: false,
                      onTap: onRevise,
                    ),
                  ],
                  const SizedBox(height: 8),
                  CodexButton(
                    label: 'Back to archive',
                    filled: false,
                    mutedOutline: true,
                    onTap: onBack,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
