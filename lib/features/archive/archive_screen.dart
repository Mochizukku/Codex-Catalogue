import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import '../../core/theme/codex_theme.dart';
import '../../core/theme/codex_tokens.dart';
import '../../models/artifact.dart';
import '../../providers/codex_providers.dart';
import '../../widgets/codex_ambient_shell.dart';
import '../../widgets/codex_components.dart';
import '../auth/auth_screen.dart';
import '../reader/reader_screen.dart';

enum _ArchiveSort {
  number('Artifact #'),
  rating('Top Rated'),
  newest('Newest');

  const _ArchiveSort(this.label);
  final String label;
}

class ArchiveScreen extends ConsumerStatefulWidget {
  const ArchiveScreen({super.key, this.onShowLanding});

  final VoidCallback? onShowLanding;

  @override
  ConsumerState<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends ConsumerState<ArchiveScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  _ArchiveSort _sort = _ArchiveSort.number;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openArtifact(BuildContext context, Artifact artifact) {
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

  List<Artifact> _applySearchAndSort(List<Artifact> source) {
    final q = _query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? List<Artifact>.from(source)
        : source.where((a) {
            return a.title.toLowerCase().contains(q) ||
                a.bracketedCode.toLowerCase().contains(q) ||
                a.numberCode.contains(q) ||
                a.historicalOrigin.toLowerCase().contains(q);
          }).toList();

    switch (_sort) {
      case _ArchiveSort.number:
        filtered.sort(
          (a, b) =>
              (a.artifactNumber ?? 9999).compareTo(b.artifactNumber ?? 9999),
        );
      case _ArchiveSort.rating:
        filtered.sort((a, b) => b.rating.compareTo(a.rating));
      case _ArchiveSort.newest:
        filtered.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.codex;
    final selectedClass = ref.watch(selectedAnomalyClassProvider);
    final selectedEra = ref.watch(selectedEraProvider);
    final loreConfig =
        ref.watch(loreConfigProvider).valueOrNull?.historicalOrigins ??
        const ['Ancient Egypt', 'Rome', 'Athens', 'Multiverse'];
    final artifactsAsync = ref.watch(filteredArtifactsProvider);
    final user = ref.watch(currentUserProvider).valueOrNull;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: widget.onShowLanding,
                child: Image.asset(
                  'assets/images/codexlogo.png',
                  width: 36,
                  height: 36,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => Icon(
                    Icons.auto_stories,
                    size: 28,
                    color: p.accent,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GRAND ARCHIVE',
                      style: CodexTypography.screenTitle(
                        p.textPrimary,
                      ).copyWith(letterSpacing: 1.5),
                    ),
                    Text(
                      'Catalogued anomalies & memory logs',
                      style: CodexTypography.metadata(p.textMuted),
                    ),
                  ],
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
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: p.surface.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: p.accent.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    '✦ ${user.truthPoints} TP',
                    style: CodexTypography.chip(p.accent),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _query = v),
            style: CodexTypography.body(p.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search by artifact title, [0417], or origin...',
              prefixIcon: Icon(Icons.search, size: 18, color: p.textMuted),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: Icon(Icons.close, size: 16, color: p.textMuted),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _query = '');
                      },
                    ),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final s in _ArchiveSort.values) ...[
                  CodexIconPillButton(
                    label: s.label,
                    active: _sort == s,
                    onTap: () => setState(() => _sort = s),
                  ),
                  const SizedBox(width: 6),
                ],
                Container(
                  width: 1,
                  height: 18,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  color: p.border,
                ),
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
              AsyncData(:final value) => Builder(
                builder: (context) {
                  final items = _applySearchAndSort(value);
                  if (items.isEmpty) {
                    return Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: CodexSectionCard(
                          padding: const EdgeInsets.all(22),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.menu_book_outlined,
                                size: 32,
                                color: p.accent,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'No catalogued artifacts match the current filters.',
                                textAlign: TextAlign.center,
                                style: CodexTypography.body(p.textMuted),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return LayoutBuilder(
                    builder: (ctx, box) {
                      if (box.maxWidth >= 640) {
                        return GridView.builder(
                          padding: const EdgeInsets.only(bottom: 24),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                mainAxisExtent: 178,
                              ),
                          itemCount: items.length,
                          itemBuilder: (_, i) => ArtifactCard(
                            artifact: items[i],
                            onTap: () => _openArtifact(ctx, items[i]),
                          ),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.only(bottom: 20),
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => ArtifactCard(
                          artifact: items[i],
                          onTap: () => _openArtifact(ctx, items[i]),
                        ),
                      );
                    },
                  );
                },
              ),
              AsyncError(:final error) => Center(
                child: CodexSectionCard(
                  borderColor: p.danger.withValues(alpha: 0.6),
                  glowColor: p.danger,
                  child: Text(
                    'Unable to load Firestore archive: $error',
                    textAlign: TextAlign.center,
                    style: CodexTypography.body(p.danger),
                  ),
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
