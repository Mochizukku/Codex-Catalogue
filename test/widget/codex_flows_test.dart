import 'package:codex_catalouge/core/theme/codex_theme.dart';
import 'package:codex_catalouge/core/theme/codex_tokens.dart';
import 'package:codex_catalouge/features/auth/auth_screen.dart';
import 'package:codex_catalouge/features/reader/reader_screen.dart';
import 'package:codex_catalouge/features/sanctum/sanctum_screen.dart';
import 'package:codex_catalouge/main.dart';
import 'package:codex_catalouge/models/app_user.dart';
import 'package:codex_catalouge/models/artifact.dart';
import 'package:codex_catalouge/providers/codex_providers.dart';
import 'package:codex_catalouge/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthService implements AuthService {
  _FakeAuthService({this.onSignUp});

  final Future<AppUser> Function({
    required String email,
    required String password,
    required String displayName,
  })?
  onSignUp;

  @override
  User? get currentFirebaseUser => null;

  @override
  Stream<User?> get authStateChanges => Stream.value(null);

  @override
  Stream<AppUser?> watchCurrentUser() => Stream.value(null);

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String displayName,
  }) {
    if (onSignUp != null) {
      return onSignUp!(
        email: email,
        password: password,
        displayName: displayName,
      );
    }
    return Future.value(
      AppUser(
        uid: 'u_new',
        displayName: displayName,
        email: email,
        createdAt: DateTime(2026),
      ),
    );
  }

  @override
  Future<void> signIn({required String email, required String password}) async {}

  @override
  Future<void> signOut() async {}
}

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

  testWidgets('AuthScreen Sign Up validates inputs, confirm password, and firebaseReady', (
    tester,
  ) async {
    var firebaseReady = false;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firebaseReadyProvider.overrideWith((ref) => firebaseReady),
          authServiceProvider.overrideWithValue(_FakeAuthService()),
        ],
        child: MaterialApp(
          theme: CodexTheme.build(CodexThemeMode.dark),
          home: const AuthScreen(initialSignUp: true),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final submitBtn = find.text('Sign Up & Behold ᛏᚱᚢᛏᚺ');

    // Empty name
    await tester.ensureVisible(submitBtn);
    await tester.tap(submitBtn);
    await tester.pumpAndSettle();
    expect(find.text('Enter your Seeker title.'), findsOneWidget);

    // Invalid email
    await tester.enterText(find.byType(TextField).at(0), 'Seer_One');
    await tester.enterText(find.byType(TextField).at(1), 'bad-email');
    await tester.ensureVisible(submitBtn);
    await tester.tap(submitBtn);
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid email address.'), findsOneWidget);

    // Short password
    await tester.enterText(find.byType(TextField).at(1), 'seer@codex.org');
    await tester.enterText(find.byType(TextField).at(2), '123');
    await tester.ensureVisible(submitBtn);
    await tester.tap(submitBtn);
    await tester.pumpAndSettle();
    expect(
      find.text('Password must be at least 6 characters.'),
      findsOneWidget,
    );

    // Mismatched confirm password
    await tester.enterText(find.byType(TextField).at(2), 'secret12');
    await tester.enterText(find.byType(TextField).at(3), 'different');
    await tester.ensureVisible(submitBtn);
    await tester.tap(submitBtn);
    await tester.pumpAndSettle();
    expect(find.text('Passwords do not match.'), findsOneWidget);

    // Firebase not ready
    await tester.enterText(find.byType(TextField).at(3), 'secret12');
    await tester.ensureVisible(submitBtn);
    await tester.tap(submitBtn);
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Firebase is not configured yet. Follow SETUP.md to link your project.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('AuthScreen Sign Up succeeds and formats FirebaseAuthException', (
    tester,
  ) async {
    String? capturedEmail;
    String? capturedName;
    var succeeded = false;
    var shouldThrowDuplicate = false;

    final fakeAuth = _FakeAuthService(
      onSignUp: ({
        required email,
        required password,
        required displayName,
      }) async {
        if (shouldThrowDuplicate) {
          throw FirebaseAuthException(code: 'email-already-in-use');
        }
        capturedEmail = email;
        capturedName = displayName;
        return AppUser(
          uid: 'u1',
          displayName: displayName,
          email: email,
          createdAt: DateTime(2026),
        );
      },
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firebaseReadyProvider.overrideWith((ref) => true),
          authServiceProvider.overrideWithValue(fakeAuth),
        ],
        child: MaterialApp(
          theme: CodexTheme.build(CodexThemeMode.dark),
          home: AuthScreen(
            initialSignUp: true,
            onSuccess: () => succeeded = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), '  Seer_Manayon  ');
    await tester.enterText(find.byType(TextField).at(1), '  seer@codex.org  ');
    await tester.enterText(find.byType(TextField).at(2), 'secret12');
    await tester.enterText(find.byType(TextField).at(3), 'secret12');

    // Toggle password visibility
    await tester.tap(find.byTooltip('Show password').first);
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField).at(2)).obscureText,
      isFalse,
    );

    // Duplicate email error formatting
    shouldThrowDuplicate = true;
    final submitBtn = find.text('Sign Up & Behold ᛏᚱᚢᛏᚺ');
    await tester.ensureVisible(submitBtn);
    await tester.tap(submitBtn);
    await tester.pumpAndSettle();
    expect(
      find.text(
        'An account with this email already exists. Try signing in instead.',
      ),
      findsOneWidget,
    );
    expect(succeeded, isFalse);

    // Successful registration
    shouldThrowDuplicate = false;
    await tester.ensureVisible(submitBtn);
    await tester.tap(submitBtn);
    await tester.pumpAndSettle();
    expect(capturedName, 'Seer_Manayon');
    expect(capturedEmail, 'seer@codex.org');
    expect(succeeded, isTrue);
    expect(find.text('The Mark of Codex granted'), findsOneWidget);
  });
}
