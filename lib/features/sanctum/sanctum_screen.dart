import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/codex_theme.dart';
import '../../core/theme/codex_tokens.dart';
import '../../providers/codex_providers.dart';
import '../../services/github_image_service.dart';
import '../../widgets/codex_components.dart';
import '../auth/auth_screen.dart';
import '../council/council_screen.dart';

class SanctumScreen extends ConsumerStatefulWidget {
  const SanctumScreen({super.key, this.onShowLanding});

  final VoidCallback? onShowLanding;

  @override
  ConsumerState<SanctumScreen> createState() => _SanctumScreenState();
}

class _SanctumScreenState extends ConsumerState<SanctumScreen> {
  final _ownerCtrl = TextEditingController();
  final _repoCtrl = TextEditingController();
  final _branchCtrl = TextEditingController(text: 'main');
  final _patCtrl = TextEditingController();
  bool _loadedGithub = false;

  @override
  void dispose() {
    _ownerCtrl.dispose();
    _repoCtrl.dispose();
    _branchCtrl.dispose();
    _patCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadGithubConfig() async {
    if (_loadedGithub) return;
    _loadedGithub = true;
    final cfg = await ref.read(githubImageServiceProvider).loadConfig();
    if (!mounted) return;
    _ownerCtrl.text = cfg.owner;
    _repoCtrl.text = cfg.repo;
    _branchCtrl.text = cfg.branch;
    _patCtrl.text = cfg.pat;
  }

  Future<void> _saveGithubConfig() async {
    await ref.read(githubImageServiceProvider).saveLocalConfig(
      GithubConfig(
        owner: _ownerCtrl.text,
        repo: _repoCtrl.text,
        branch: _branchCtrl.text.isEmpty ? 'main' : _branchCtrl.text,
        pat: _patCtrl.text,
      ),
    );
    if (mounted) showCodexToast(context, 'GitHub asset config saved');
  }

  @override
  Widget build(BuildContext context) {
    final p = context.codex;
    final user = ref.watch(currentUserProvider).valueOrNull;
    final themeMode = ref.watch(globalThemeModeProvider);
    final isLight = themeMode == CodexThemeMode.light;

    if (user != null && user.role.isCouncil) {
      _loadGithubConfig();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Sanctum', style: CodexTypography.screenTitle(p.textPrimary)),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: p.border),
            ),
            child: Column(
              children: [
                _InfoRow(
                  label: 'Account',
                  value: user?.displayName ?? 'Uninitiated Guest',
                ),
                const SizedBox(height: 6),
                _InfoRow(
                  label: 'Role',
                  value: user?.inUniverseRole ?? 'Guest Seeker',
                ),
                if (user != null) ...[
                  const SizedBox(height: 6),
                  _InfoRow(
                    label: 'Rank / TP',
                    value: 'Level ${user.hierarchyLevel} · ${user.truthPoints} TP',
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: p.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Light theme',
                  style: CodexTypography.body(p.textPrimary),
                ),
                Switch.adaptive(
                  value: isLight,
                  activeThumbColor: p.accent,
                  onChanged: (v) {
                    ref.read(globalThemeModeProvider.notifier).state =
                        v ? CodexThemeMode.light : CodexThemeMode.dark;
                    ref.read(readerThemeOverrideProvider.notifier).state = null;
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (user != null && user.role.isCouncil) ...[
            CodexButton(
              label: "Open Puppeteer's Council",
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CouncilScreen()),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: p.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'GitHub Relic Repository Config',
                    style: CodexTypography.button(p.accent),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _ownerCtrl,
                    style: CodexTypography.body(p.textPrimary),
                    decoration: const InputDecoration(hintText: 'GitHub Owner'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _repoCtrl,
                    style: CodexTypography.body(p.textPrimary),
                    decoration: const InputDecoration(hintText: 'Repository Name'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _branchCtrl,
                    style: CodexTypography.body(p.textPrimary),
                    decoration: const InputDecoration(hintText: 'Branch (main)'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _patCtrl,
                    obscureText: true,
                    style: CodexTypography.body(p.textPrimary),
                    decoration: const InputDecoration(
                      hintText: 'Fine-grained PAT (contents:write)',
                    ),
                  ),
                  const SizedBox(height: 10),
                  CodexButton(
                    label: 'Save GitHub Config',
                    filled: false,
                    onTap: _saveGithubConfig,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ] else ...[
            Text(
              "The Puppeteer's Council button appears for admins and moderators only.",
              style: CodexTypography.metadata(p.textMuted),
            ),
            const SizedBox(height: 14),
          ],
          if (user == null) ...[
            CodexButton(
              label: 'Sign Up / Sign In',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AuthScreen(initialSignUp: true),
                ),
              ),
            ),
          ] else ...[
            CodexButton(
              label: 'Sign Out',
              filled: false,
              mutedOutline: true,
              onTap: () async {
                await ref.read(authServiceProvider).signOut();
                if (context.mounted) showCodexToast(context, 'Signed out');
              },
            ),
          ],
          if (widget.onShowLanding != null) ...[
            const SizedBox(height: 10),
            CodexButton(
              label: 'View Codex Introduction',
              filled: false,
              mutedOutline: true,
              onTap: widget.onShowLanding,
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final p = context.codex;
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(label, style: CodexTypography.dossierLabel(p.textMuted)),
        ),
        Expanded(
          child: Text(value, style: CodexTypography.dossierLabel(p.textPrimary)),
        ),
      ],
    );
  }
}
