import 'package:firebase_core/firebase_core.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/codex_theme.dart';
import 'core/theme/codex_tokens.dart';
import 'features/archive/archive_screen.dart';
import 'features/auth/auth_screen.dart';
import 'features/landing/landing_screen.dart';
import 'features/sanctum/sanctum_screen.dart';
import 'features/transcribe/transcribe_screen.dart';
import 'features/vault/vault_screen.dart';
import 'firebase_options.dart';
import 'models/app_user.dart';
import 'providers/codex_providers.dart';
import 'widgets/codex_ambient_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var firebaseReady = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseReady = true;
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }
  runApp(
    ProviderScope(
      overrides: [firebaseReadyProvider.overrideWith((ref) => firebaseReady)],
      child: const CodexCatalogueApp(),
    ),
  );
}

class CodexCatalogueApp extends ConsumerWidget {
  const CodexCatalogueApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(globalThemeModeProvider);
    return MaterialApp(
      title: 'Codex Catalogue',
      debugShowCheckedModeBanner: false,
      theme: CodexTheme.build(mode),
      home: const CodexRootGate(),
    );
  }
}

class CodexRootGate extends ConsumerStatefulWidget {
  const CodexRootGate({super.key});

  @override
  ConsumerState<CodexRootGate> createState() => _CodexRootGateState();
}

class _CodexRootGateState extends ConsumerState<CodexRootGate> {
  static const _tabs = [
    (glyph: '▤', label: 'Archive'),
    (glyph: '⇩', label: 'Vault'),
    (glyph: '✎', label: 'Transcribe'),
    (glyph: '☥', label: 'Sanctum'),
  ];

  bool _showLanding = true;
  int _tabIndex = 0;

  void _openAuth(bool signUp) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AuthScreen(
          initialSignUp: signUp,
          onSuccess: () {
            Navigator.of(context).pop();
            setState(() => _showLanding = false);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;

    if (user == null && _showLanding) {
      return LandingScreen(
        onEnterArchive: () => setState(() {
          _showLanding = false;
          _tabIndex = 0;
        }),
        onSignUp: () => _openAuth(true),
        onSignIn: () => _openAuth(false),
      );
    }

    final p = context.codex;
    final screens = [
      ArchiveScreen(onShowLanding: () => setState(() => _showLanding = true)),
      VaultScreen(onBrowseArchive: () => setState(() => _tabIndex = 0)),
      const TranscribeScreen(),
      SanctumScreen(onShowLanding: () => setState(() => _showLanding = true)),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 760;
        final content = SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 940),
              child: IndexedStack(index: _tabIndex, children: screens),
            ),
          ),
        );

        return Scaffold(
          backgroundColor: p.background,
          body: CodexAmbientBackground(
            child: isWide
                ? Row(
                    children: [
                      _ArcaneNavRail(
                        tabs: _tabs,
                        activeIndex: _tabIndex,
                        user: user,
                        onSelect: (i) => setState(() => _tabIndex = i),
                        onLogoTap: () => setState(() => _showLanding = true),
                      ),
                      Expanded(child: content),
                    ],
                  )
                : content,
          ),
          bottomNavigationBar: isWide
              ? null
              : _ArcaneBottomNavBar(
                  tabs: _tabs,
                  activeIndex: _tabIndex,
                  onSelect: (i) => setState(() => _tabIndex = i),
                ),
        );
      },
    );
  }
}

class _ArcaneNavRail extends StatelessWidget {
  const _ArcaneNavRail({
    required this.tabs,
    required this.activeIndex,
    required this.user,
    required this.onSelect,
    required this.onLogoTap,
  });

  final List<({String glyph, String label})> tabs;
  final int activeIndex;
  final AppUser? user;
  final ValueChanged<int> onSelect;
  final VoidCallback onLogoTap;

  @override
  Widget build(BuildContext context) {
    final p = context.codex;
    final isDark = p.mode == CodexThemeMode.dark;
    final violet = AnomalyClass.cursed.color;

    return Container(
      width: 224,
      decoration: BoxDecoration(
        color: p.surface.withValues(alpha: isDark ? 0.88 : 0.94),
        border: Border(right: BorderSide(color: p.border)),
        boxShadow: [
          BoxShadow(
            color: violet.withValues(alpha: isDark ? 0.10 : 0.04),
            blurRadius: 20,
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 18, 14, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: onLogoTap,
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/images/codexlogo.png',
                        width: 38,
                        height: 38,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => Icon(
                          Icons.auto_stories,
                          size: 32,
                          color: p.accent,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'CODEX\nCATALOGUE',
                          style: CodexTypography.dossierTitle(
                            p.textPrimary,
                          ).copyWith(fontSize: 13, letterSpacing: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Divider(color: p.border, height: 1),
              const SizedBox(height: 14),
              for (var i = 0; i < tabs.length; i++) ...[
                _RailNavItem(
                  glyph: tabs[i].glyph,
                  label: tabs[i].label,
                  active: activeIndex == i,
                  onTap: () => onSelect(i),
                ),
                const SizedBox(height: 6),
              ],
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: p.pillSurface.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: p.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.displayName ?? 'Guest Seeker',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CodexTypography.button(p.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user != null
                          ? '${user!.inUniverseRole} · ${user!.truthPoints} TP'
                          : 'Uninitiated Guest',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CodexTypography.badge(p.accent),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RailNavItem extends StatefulWidget {
  const _RailNavItem({
    required this.glyph,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String glyph;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  State<_RailNavItem> createState() => _RailNavItemState();
}

class _RailNavItemState extends State<_RailNavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final p = context.codex;
    final active = widget.active;
    final fg = active ? p.accent : (_hovered ? p.textPrimary : p.textMuted);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: active
                ? p.accent.withValues(alpha: 0.14)
                : (_hovered ? p.pillSurface.withValues(alpha: 0.55) : Colors.transparent),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: active
                  ? p.accent.withValues(alpha: 0.65)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Text(widget.glyph, style: TextStyle(fontSize: 17, color: fg)),
              const SizedBox(width: 11),
              Text(
                widget.label,
                style: CodexTypography.dossierLabel(fg, active: active)
                    .copyWith(fontSize: 13.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArcaneBottomNavBar extends StatelessWidget {
  const _ArcaneBottomNavBar({
    required this.tabs,
    required this.activeIndex,
    required this.onSelect,
  });

  final List<({String glyph, String label})> tabs;
  final int activeIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final p = context.codex;
    final isDark = p.mode == CodexThemeMode.dark;
    return Container(
      height: 66,
      decoration: BoxDecoration(
        color: p.surface.withValues(alpha: isDark ? 0.94 : 0.98),
        border: Border(top: BorderSide(color: p.border)),
      ),
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Row(
        children: [
          for (var i = 0; i < tabs.length; i++)
            _NavTab(
              glyph: tabs[i].glyph,
              label: tabs[i].label,
              active: activeIndex == i,
              onTap: () => onSelect(i),
            ),
        ],
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.glyph,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String glyph;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.codex;
    final color = active ? p.accent : p.textMuted;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: active ? 28 : 0,
              height: 2,
              margin: const EdgeInsets.only(bottom: 5),
              decoration: BoxDecoration(
                color: active ? p.accent : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: p.accent.withValues(alpha: 0.65),
                          blurRadius: 6,
                        ),
                      ]
                    : null,
              ),
            ),
            Text(glyph, style: TextStyle(fontSize: 18, color: color)),
            Text(
              label,
              style: CodexTypography.navLabel(color, active: active),
            ),
          ],
        ),
      ),
    );
  }
}
