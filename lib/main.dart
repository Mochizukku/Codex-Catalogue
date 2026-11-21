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
import 'providers/codex_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var firebaseReady = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseReady = true;
  } catch (_) {
    // Firebase not configured yet; follow SETUP.md to link your project.
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
  bool _showLanding = true;
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;

    if (user == null && _showLanding) {
      return LandingScreen(
        onEnterArchive: () => setState(() {
          _showLanding = false;
          _tabIndex = 0;
        }),
        onSignUp: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AuthScreen(
              initialSignUp: true,
              onSuccess: () {
                Navigator.of(context).pop();
                setState(() => _showLanding = false);
              },
            ),
          ),
        ),
        onSignIn: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AuthScreen(
              initialSignUp: false,
              onSuccess: () {
                Navigator.of(context).pop();
                setState(() => _showLanding = false);
              },
            ),
          ),
        ),
      );
    }

    final p = context.codex;
    final screens = [
      ArchiveScreen(onShowLanding: () => setState(() => _showLanding = true)),
      const VaultScreen(),
      const TranscribeScreen(),
      SanctumScreen(onShowLanding: () => setState(() => _showLanding = true)),
    ];

    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(child: IndexedStack(index: _tabIndex, children: screens)),
      bottomNavigationBar: Container(
        height: 64,
        decoration: BoxDecoration(
          color: p.surface,
          border: Border(top: BorderSide(color: p.border)),
        ),
        padding: const EdgeInsets.fromLTRB(4, 6, 4, 12),
        child: Row(
          children: [
            _NavTab(
              glyph: '▤',
              label: 'Archive',
              active: _tabIndex == 0,
              onTap: () => setState(() => _tabIndex = 0),
            ),
            _NavTab(
              glyph: '⇩',
              label: 'Vault',
              active: _tabIndex == 1,
              onTap: () => setState(() => _tabIndex = 1),
            ),
            _NavTab(
              glyph: '✎',
              label: 'Transcribe',
              active: _tabIndex == 2,
              onTap: () => setState(() => _tabIndex = 2),
            ),
            _NavTab(
              glyph: '☥',
              label: 'Sanctum',
              active: _tabIndex == 3,
              onTap: () => setState(() => _tabIndex = 3),
            ),
          ],
        ),
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
