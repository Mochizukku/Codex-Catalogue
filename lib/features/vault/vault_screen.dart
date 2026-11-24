import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import '../../core/theme/codex_theme.dart';
import '../../core/theme/codex_tokens.dart';
import '../../providers/codex_providers.dart';
import '../../services/vault_local_service.dart';
import '../../widgets/codex_ambient_shell.dart';
import '../../widgets/codex_components.dart';
import '../auth/auth_screen.dart';
import '../reader/reader_screen.dart';

enum _VaultFilter {
  all('All Saved'),
  bookmarked('Bookmarks ★'),
  offline('Offline ⇩');

  const _VaultFilter(this.label);
  final String label;
}

class VaultScreen extends ConsumerStatefulWidget {
  const VaultScreen({super.key, this.onBrowseArchive});

  final VoidCallback? onBrowseArchive;

  @override
  ConsumerState<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends ConsumerState<VaultScreen> {
  _VaultFilter _filter = _VaultFilter.all;

  List<VaultEntry> _applyFilter(List<VaultEntry> entries) {
    return switch (_filter) {
      _VaultFilter.all => entries,
      _VaultFilter.bookmarked => entries.where((e) => e.isBookmarked).toList(),
      _VaultFilter.offline => entries.where((e) => e.isOfflineSaved).toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final p = context.codex;
    final user = ref.watch(currentUserProvider).valueOrNull;
    final allEntries = ref.watch(vaultProvider).values.toList();
    final filtered = _applyFilter(allEntries);
    final bookmarkedCount = allEntries.where((e) => e.isBookmarked).length;
    final offlineCount = allEntries.where((e) => e.isOfflineSaved).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PERSONAL VAULT',
                      style: CodexTypography.screenTitle(
                        p.textPrimary,
                      ).copyWith(letterSpacing: 1.5),
                    ),
                    Text(
                      'Local bookmarks & offline memory transcripts',
                      style: CodexTypography.metadata(p.textMuted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: p.surface.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: p.border),
                ),
                child: Text(
                  '★ $bookmarkedCount · ⇩ $offlineCount',
                  style: CodexTypography.chip(p.accent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final f in _VaultFilter.values) ...[
                  CodexChip(
                    label: f.label,
                    selected: _filter == f,
                    onTap: () => setState(() => _filter = f),
                  ),
                  const SizedBox(width: 6),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (filtered.isEmpty)
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: CodexSectionCard(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 34,
                          color: p.accent,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          allEntries.isEmpty
                              ? 'Nothing saved yet. Open an artifact and tap ☆ to bookmark or ⇩ to read offline.'
                              : 'No entries match the selected vault filter.',
                          textAlign: TextAlign.center,
                          style: CodexTypography.body(p.textMuted),
                        ),
                        if (allEntries.isEmpty &&
                            widget.onBrowseArchive != null) ...[
                          const SizedBox(height: 14),
                          CodexButton(
                            label: 'Browse Grand Archive',
                            filled: false,
                            onTap: widget.onBrowseArchive,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.only(bottom: 24),
                itemCount: filtered.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (ctx, i) {
                  final entry = filtered[i];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ArtifactCard(
                        artifact: entry.artifact,
                        onTap: () {
                          if (user == null) {
                            showTruthGateDialog(
                              ctx,
                              onSignUp: () => Navigator.of(ctx).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const AuthScreen(initialSignUp: true),
                                ),
                              ),
                              onSignIn: () => Navigator.of(ctx).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const AuthScreen(initialSignUp: false),
                                ),
                              ),
                            );
                            return;
                          }
                          Navigator.of(ctx).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  ReaderScreen(artifact: entry.artifact),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          if (entry.isBookmarked)
                            CodexIconPillButton(
                              label: '★ Remove bookmark',
                              onTap: () async {
                                await ref
                                    .read(vaultProvider.notifier)
                                    .setBookmarkExplicit(entry.artifact, false);
                                if (user != null &&
                                    ref.read(firebaseReadyProvider)) {
                                  await ref
                                      .read(firestoreServiceProvider)
                                      .toggleUserBookmark(
                                        userId: user.uid,
                                        artifactId: entry.artifact.id,
                                        bookmark: false,
                                      );
                                }
                              },
                            ),
                          if (entry.isOfflineSaved)
                            CodexIconPillButton(
                              label: '⇩ Remove offline copy',
                              onTap: () => ref
                                  .read(vaultProvider.notifier)
                                  .setOfflineExplicit(entry.artifact, false),
                            ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
