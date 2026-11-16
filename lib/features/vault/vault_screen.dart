import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/codex_theme.dart';
import '../../core/theme/codex_tokens.dart';
import '../../providers/codex_providers.dart';
import '../../widgets/codex_components.dart';
import '../auth/auth_screen.dart';
import '../reader/reader_screen.dart';

class VaultScreen extends ConsumerWidget {
  const VaultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.codex;
    final user = ref.watch(currentUserProvider).valueOrNull;
    final vaultEntries = ref.watch(vaultProvider).values.toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Vault', style: CodexTypography.screenTitle(p.textPrimary)),
          const SizedBox(height: 14),
          if (vaultEntries.isEmpty)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Nothing saved yet. Open an artifact and tap ☆ to bookmark or ⇩ to read offline.',
                    textAlign: TextAlign.center,
                    style: CodexTypography.body(p.textMuted),
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.only(bottom: 20),
                itemCount: vaultEntries.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (ctx, i) {
                  final entry = vaultEntries[i];
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
