import 'package:codex_catalouge/core/theme/codex_theme.dart';
import 'package:codex_catalouge/core/theme/codex_tokens.dart';
import 'package:codex_catalouge/features/reader/reader_screen.dart';
import 'package:codex_catalouge/features/sanctum/sanctum_screen.dart';
import 'package:codex_catalouge/main.dart';
import 'package:codex_catalouge/models/app_user.dart';
import 'package:codex_catalouge/models/artifact.dart';
import 'package:codex_catalouge/providers/codex_providers.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Artifact _sampleArtifact({
  String id = 'art_0417',
  int number = 417,
  String title = 'The Ledger That Remembers Debts',
  AnomalyClass anomalyClass = AnomalyClass.cursed,
  String origin = 'Rome',
  int upvotes = 128,
  int downvotes = 0,
}) => Artifact(
  id: id,
  artifactNumber: number,
  title: title,
  anomalyClass: anomalyClass,
  historicalOrigin: origin,
  discovererPerspective: 'Roman Clerk',
  adventurerRecoveryNote: 'REDACTED',
  clairvoyanceName: 'Author #1',
  chapterContent:
      'I found it beneath the third step of the treasury.\n\nEvery name I read aloud turned a shade paler.',
  authorId: 'author_1',
  status: ArtifactStatus.approved,
  isOfficialCanon: true,
  upvotes: upvotes,
  downvotes: downvotes,
  updatedAt: DateTime(2026),
);

void main() {
  testWidgets('Guest landing page leads to Archive and Truth Gate warning', (
    tester,
  ) async {
    final sample = _sampleArtifact();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firebaseReadyProvider.overrideWith((ref) => false),
          currentUserProvider.overrideWith((ref) => Stream.value(null)),
          approvedArtifactsProvider.overrideWith(
            (ref) => Stream.value([sample]),
          ),
        ],
        child: const CodexCatalogueApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('CODEX CATALOGUE'), findsOneWidget);
    final browseBtn = find.text('Browse Grand Archive (Guest)');
    await tester.ensureVisible(browseBtn);
    await tester.pumpAndSettle();
    await tester.tap(browseBtn);
    await tester.pumpAndSettle();

    expect(find.text('Artifact [0417]'), findsOneWidget);
    await tester.tap(find.text('The Ledger That Remembers Debts'));
    await tester.pumpAndSettle();

    expect(find.text('Not Eligible to see the ᛏᚱᚢᛏᚺ'), findsOneWidget);
  });

  testWidgets('Reader shows redacted fallback, theme toolbar, and flagged gate', (
    tester,
  ) async {
    final flagged = _sampleArtifact(
      id: 'art_0508',
      number: 508,
      title: 'The Hollow Oar of Piraeus',
      anomalyClass: AnomalyClass.dangerous,
      origin: 'Athens',
      upvotes: 0,
      downvotes: 12,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firebaseReadyProvider.overrideWith((ref) => false),
          currentUserProvider.overrideWith(
            (ref) => Stream.value(
              AppUser(
                uid: 'u1',
                displayName: 'Seer',
                email: 'seer@codex.org',
                createdAt: DateTime(2026),
              ),
            ),
          ),
        ],
        child: MaterialApp(
          theme: CodexTheme.build(CodexThemeMode.dark),
          home: ReaderScreen(artifact: flagged),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Flagged anomaly'), findsOneWidget);
    await tester.tap(find.text('Proceed anyway'));
    await tester.pumpAndSettle();

    expect(
      find.text('[VISION FRAGMENT CORRUPTED]\nVISUAL DATA REDACTED'),
      findsOneWidget,
    );

    await tester.tap(find.text('Papyrus'));
    await tester.pumpAndSettle();
    expect(find.text('Artifact [0508]'), findsOneWidget);
  });

  testWidgets('Sanctum gates Council button to Admin/Moderator roles', (
    tester,
  ) async {
    final reader = AppUser(
      uid: 'r1',
      displayName: 'Seeker_1',
      email: 'r1@codex.org',
      role: UserRole.reader,
      createdAt: DateTime(2026),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firebaseReadyProvider.overrideWith((ref) => false),
          currentUserProvider.overrideWith((ref) => Stream.value(reader)),
        ],
        child: MaterialApp(
          theme: CodexTheme.build(CodexThemeMode.dark),
          home: const Scaffold(body: SanctumScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("Open Puppeteer's Council"), findsNothing);
  });
}
