import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/codex_theme.dart';
import '../../core/theme/codex_tokens.dart';
import '../../models/artifact.dart';
import '../../providers/codex_providers.dart';
import '../../widgets/codex_components.dart';
import '../auth/auth_screen.dart';
import '../reader/reader_screen.dart';

class ArchiveScreen extends ConsumerWidget {
  const ArchiveScreen({super.key, this.onShowLanding});

  final VoidCallback? onShowLanding;

  void _openArtifact(BuildContext context, WidgetRef ref, Artifact artifact) {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) {
      showTruthGateDialog(
        context,
        onSignUp: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const AuthScreen(initialSignUp: true),
          ),
        ),
        onSignIn: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const AuthScreen(initialSignUp: false),
          ),
        ),
      );
      return;
    }

    ref.read(firestoreServiceProvider).incrementTruthPoints(user.uid, points: 2);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ReaderScreen(artifact: artifact)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.codex;
    final selectedClass = ref.watch(selectedAnomalyClassProvider);
    final selectedEra = ref.watch(selectedEraProvider);
    final loreConfig =
        ref.watch(loreConfigProvider).valueOrNull?.historicalOrigins ??
        const ['Ancient Egypt', 'Rome', 'Athens', 'Multiverse'];
    final artifactsAsync = ref.watch(filteredArtifactsProvider);
    final user = ref.watch(currentUserProvider).valueOrNull;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onShowLanding,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.asset(
                    'assets/images/codex_logo.png',
                    width: 36,
                    height: 36,
                    errorBuilder: (_, _, _) => Icon(
                      Icons.auto_stories,
                      size: 28,
                      color: p.accent,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Archive',
                  style: CodexTypography.screenTitle(p.textPrimary),
                ),
              ),
              if (user == null)
                CodexIconPillButton(
                  label: 'Guest · Sign Up',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AuthScreen(initialSignUp: true),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                CodexChip(
                  label: 'All',
                  selected: selectedClass == null,
                  onTap: () =>
                      ref.read(selectedAnomalyClassProvider.notifier).state =
                          null,
                ),
                const SizedBox(width: 6),
                for (final c in AnomalyClass.values) ...[
                  CodexChip(
                    label: c.label,
                    selected: selectedClass == c,
                    dotColor: c.color,
                    onTap: () =>
                        ref.read(selectedAnomalyClassProvider.notifier).state =
                            selectedClass == c ? null : c,
                  ),
                  const SizedBox(width: 6),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                CodexChip(
                  label: 'All eras',
                  selected: selectedEra == null,
                  onTap: () =>
                      ref.read(selectedEraProvider.notifier).state = null,
                ),
                const SizedBox(width: 6),
                for (final era in loreConfig) ...[
                  CodexChip(
                    label: era,
                    selected: selectedEra == era,
                    onTap: () =>
                        ref.read(selectedEraProvider.notifier).state =
                            selectedEra == era ? null : era,
                  ),
                  const SizedBox(width: 6),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: switch (artifactsAsync) {
              AsyncData(:final value) when value.isEmpty => Center(
                child: Text(
                  'No catalogued artifacts match the current filters.',
                  textAlign: TextAlign.center,
                  style: CodexTypography.body(p.textMuted),
                ),
              ),
              AsyncData(:final value) => ListView.separated(
                padding: const EdgeInsets.only(bottom: 20),
                itemCount: value.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (ctx, i) => ArtifactCard(
                  artifact: value[i],
                  onTap: () => _openArtifact(ctx, ref, value[i]),
                ),
              ),
              AsyncError(:final error) => Center(
                child: Text(
                  'Unable to load Firestore archive: $error',
                  textAlign: TextAlign.center,
                  style: CodexTypography.body(p.danger),
                ),
              ),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
        ],
      ),
    );
  }
}
