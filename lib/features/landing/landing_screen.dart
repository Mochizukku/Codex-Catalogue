import 'package:material_ui/material_ui.dart';
import '../../core/theme/codex_theme.dart';
import '../../core/theme/codex_tokens.dart';
import '../../widgets/codex_components.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({
    super.key,
    required this.onEnterArchive,
    required this.onSignUp,
    required this.onSignIn,
  });

  final VoidCallback onEnterArchive;
  final VoidCallback onSignUp;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final p = context.codex;
    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/images/codex_logo.png',
                    width: 72,
                    height: 72,
                    errorBuilder: (_, _, _) => Icon(
                      Icons.auto_stories,
                      size: 56,
                      color: p.accent,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'CODEX CATALOGUE',
                textAlign: TextAlign.center,
                style: CodexTypography.screenTitle(p.textPrimary).copyWith(
                  fontSize: 22,
                  letterSpacing: 1.8,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'UNDER THE DIRECTIVE OF THE PUPPETEER',
                textAlign: TextAlign.center,
                style: CodexTypography.fallbackCaption(p.accent),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: p.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: p.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'THE CLANDESTINE ARCHIVE',
                      style: CodexTypography.dossierTitle(p.accent),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Across Ancient Egypt, Imperial Rome, Classical Athens, and the outer Multiverse, anomalous relics have shaped and shattered history.',
                      style: CodexTypography.transcript(
                        p.textPrimary,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Once field operatives known as The Adventurers recover a relic, psychics of The Clairvoyance peer into its past to transcribe the discoverer\'s first-hand memories.',
                      style: CodexTypography.body(p.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: p.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: p.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ANOMALY CLASSIFICATIONS',
                      style: CodexTypography.artifactId(p.textMuted),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final c in AnomalyClass.values)
                          CodexChip(
                            label: c.label,
                            selected: false,
                            dotColor: c.color,
                            onTap: onEnterArchive,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: p.pillSurface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: p.danger.withValues(alpha: 0.6)),
                ),
                child: Row(
                  children: [
                    Text('⚠', style: TextStyle(fontSize: 18, color: p.accent)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Guests may inspect the Grand Archive index, but reading memory transcripts requires signing up to behold the ᛏᚱᚢᛏᚺ.',
                        style: CodexTypography.metadata(p.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              CodexButton(
                label: 'Browse Grand Archive (Guest)',
                onTap: onEnterArchive,
              ),
              const SizedBox(height: 10),
              CodexButton(
                label: 'Receive The Mark (Sign Up)',
                filled: false,
                onTap: onSignUp,
              ),
              const SizedBox(height: 10),
              CodexButton(
                label: 'Initiate Sign In',
                filled: false,
                mutedOutline: true,
                onTap: onSignIn,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
