import 'package:codex_catalouge/core/theme/codex_theme.dart';
import 'package:codex_catalouge/core/theme/codex_tokens.dart';
import 'package:codex_catalouge/features/archive/archive_screen.dart';
import 'package:codex_catalouge/features/auth/auth_screen.dart';
import 'package:codex_catalouge/features/landing/arcane_backdrop.dart';
import 'package:codex_catalouge/features/landing/landing_placeholders.dart';
import 'package:codex_catalouge/features/landing/landing_screen.dart';
import 'package:codex_catalouge/features/reader/reader_screen.dart';
import 'package:codex_catalouge/features/sanctum/sanctum_screen.dart';
import 'package:codex_catalouge/main.dart';
import 'package:codex_catalouge/models/app_user.dart';
import 'package:codex_catalouge/models/artifact.dart';
import 'package:codex_catalouge/providers/codex_providers.dart';
import 'package:codex_catalouge/services/auth_service.dart';
import 'package:codex_catalouge/widgets/floating_runes_overlay.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
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

  int signUpCalls = 0;
  int signInCalls = 0;
  int signOutCalls = 0;

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
    signUpCalls++;
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
  Future<void> signIn({required String email, required String password}) async {
    signInCalls++;
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
  }
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
    expect(find.text('UNDER THE DIRECTIVE OF THE PUPPETEER'), findsNothing);
    expect(find.text('Join the Organization'), findsOneWidget);
    expect(find.text(kLandingDescriptionPlaceholder), findsOneWidget);
    expect(
      find.text(kPlaceholderFeaturedChapters.first.title),
      findsOneWidget,
    );

    final browseLink = find.text('Browse the Grand Archive');
    await tester.ensureVisible(browseLink);
    await tester.pumpAndSettle();
    await tester.tap(browseLink);
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

  testWidgets(
    'Landing CTA morphs to Join the Cult on hover and tap-loading, and slider paginates',
    (tester) async {
      var signUpCalls = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: CodexTheme.build(CodexThemeMode.dark),
          home: LandingScreen(
            onEnterArchive: () {},
            onSignUp: () => signUpCalls++,
            onSignIn: () {},
          ),
        ),
      );
      await tester.pump();

      final ctaFinder = find.text('Join the Organization');
      expect(ctaFinder, findsOneWidget);
      expect(find.text('UNCOVER THE ARCHIVE'), findsOneWidget);

      final titleFinder = find.text('CODEX CATALOGUE');
      final titleRectIdle = tester.getRect(titleFinder);

      // Trigger lava-lamp title animation (~1.8s) and confirm title position never shifts.
      await tester.pump(const Duration(milliseconds: 1850));
      await tester.pump(const Duration(milliseconds: 600));
      expect(tester.getRect(titleFinder), titleRectIdle);

      // Description starts hidden below the centered hero viewport.
      final descOpacityFinder = find.ancestor(
        of: find.text(kLandingDescriptionPlaceholder),
        matching: find.byType(AnimatedOpacity),
      );
      expect(tester.widget<AnimatedOpacity>(descOpacityFinder).opacity, 0.0);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await tester.pump();

      // Rapid hover enter/exit/enter does not throw duplicate key assertions.
      await mouse.moveTo(tester.getCenter(ctaFinder));
      await tester.pump(const Duration(milliseconds: 50));
      await mouse.moveTo(const Offset(5, 5));
      await tester.pump(const Duration(milliseconds: 50));
      await mouse.moveTo(tester.getCenter(find.text('Join the Organization')));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Join the Cult'), findsOneWidget);

      // Exit hover restores "Join the Organization".
      await mouse.moveTo(const Offset(5, 5));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Join the Organization'), findsOneWidget);
      await mouse.removePointer();

      // Tap (mobile flow) shows "Join the Cult" loading state, then triggers onSignUp.
      await tester.tap(find.text('Join the Organization'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Join the Cult'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(signUpCalls, 0);

      await tester.pump(const Duration(milliseconds: 450));
      expect(signUpCalls, 1);

      // Tapping scroll cue scrolls down and reveals description with floating letters.
      await tester.tap(find.text('UNCOVER THE ARCHIVE'));
      await tester.pumpAndSettle();
      expect(tester.widget<AnimatedOpacity>(descOpacityFinder).opacity, 1.0);
      expect(find.text(kLandingDescriptionPlaceholder), findsOneWidget);

      // Slider arrow advances to the second placeholder chapter.
      final nextArrow = find.byIcon(Icons.chevron_right);
      await tester.ensureVisible(nextArrow);
      await tester.pumpAndSettle();
      await tester.tap(nextArrow);
      await tester.pumpAndSettle();
      expect(find.text(kPlaceholderFeaturedChapters[1].title), findsOneWidget);

      // Scrolling back to top resets the reveal state so it can replay.
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, 900),
      );
      await tester.pumpAndSettle();
      expect(tester.widget<AnimatedOpacity>(descOpacityFinder).opacity, 0.0);
    },
  );

  testWidgets(
    'FloatingRunesOverlay spawns random runes, responds to press/drag, and preserves child taps',
    (tester) async {
      var childTapped = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: CodexTheme.build(CodexThemeMode.dark),
          home: Scaffold(
            body: FloatingRunesOverlay(
              initialDelay: const Duration(milliseconds: 50),
              burstInterval: const Duration(seconds: 10),
              burstDuration: const Duration(milliseconds: 600),
              hitRadius: 1000,
              child: Center(
                child: ElevatedButton(
                  onPressed: () => childTapped++,
                  child: const Text('Child Button'),
                ),
              ),
            ),
          ),
        ),
      );

      // Advance past initialDelay so a burst starts.
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 120));

      // Drag across the overlay to deflect active runes.
      await tester.dragFrom(const Offset(100, 200), const Offset(180, -60));
      await tester.pump(const Duration(milliseconds: 120));

      // Tapping child widget still works through translucent Listener.
      await tester.tap(find.text('Child Button'));
      await tester.pumpAndSettle();
      expect(childTapped, 1);
    },
  );

  testWidgets(
    'AuthScreen Sign Up plays crimson Mark ritual into Sign In, then Sign In awakens into Dashboard',
    (tester) async {
      final fakeAuth = _FakeAuthService();
      var enteredDashboard = 0;

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
              onSuccess: () => enteredDashboard++,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(ArcaneBackdrop), findsOneWidget);
      expect(find.byType(FloatingRunesOverlay), findsOneWidget);
      expect(find.text('OBTAIN THE MARK'), findsOneWidget);

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'Seer_Test');
      await tester.enterText(fields.at(1), 'seer@codex.org');
      await tester.enterText(fields.at(2), 'secret123');
      await tester.enterText(fields.at(3), 'secret123');

      final signUpBtn = find.text('Sign Up & Behold ᛏᚱᚢᛏᚺ');
      await tester.ensureVisible(signUpBtn);
      await tester.tap(signUpBtn);
      await tester.pump();
      expect(fakeAuth.signUpCalls, 1);
      expect(fakeAuth.signOutCalls, 1);

      // Let the 3000ms crimson Mark ritual complete and transition to Sign In.
      await tester.pumpAndSettle();
      expect(find.text('SANCTUM AUTHENTICATION'), findsOneWidget);
      expect(enteredDashboard, 0);
      expect(find.text('seer@codex.org'), findsOneWidget);
      expect(find.text('secret123'), findsNothing);

      // Enter password and Sign In -> Sanctum Awakening -> Dashboard callback.
      await tester.enterText(find.byType(TextField).at(1), 'secret123');
      final signInBtn = find.text('Sign In');
      await tester.ensureVisible(signInBtn);
      await tester.tap(signInBtn);
      await tester.pump();
      expect(fakeAuth.signInCalls, 1);

      await tester.pumpAndSettle();
      expect(enteredDashboard, 1);
    },
  );

  testWidgets(
    'Archive search/sort filters artifacts and Sanctum switches all 3 theme modes',
    (tester) async {
      final first = _sampleArtifact(
        id: 'a1',
        number: 101,
        title: 'Obelisk of Whispering Sand',
        origin: 'Ancient Egypt',
        upvotes: 12,
      );
      final second = _sampleArtifact(
        id: 'a2',
        number: 204,
        title: 'Brass Astrolabe of Athens',
        origin: 'Athens',
        upvotes: 90,
      );

      final container = ProviderContainer(
        overrides: [
          firebaseReadyProvider.overrideWith((ref) => false),
          currentUserProvider.overrideWith((ref) => Stream.value(null)),
          approvedArtifactsProvider.overrideWith(
            (ref) => Stream.value([first, second]),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: CodexTheme.build(CodexThemeMode.dark),
            home: const Scaffold(body: ArchiveScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Obelisk of Whispering Sand'), findsOneWidget);
      expect(find.text('Brass Astrolabe of Athens'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Astrolabe');
      await tester.pumpAndSettle();
      expect(find.text('Brass Astrolabe of Athens'), findsOneWidget);
      expect(find.text('Obelisk of Whispering Sand'), findsNothing);

      // Verify Sanctum 3-mode theme selector updates globalThemeModeProvider.
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: CodexTheme.build(CodexThemeMode.dark),
            home: const Scaffold(body: SanctumScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Papyrus'));
      await tester.pumpAndSettle();
      expect(container.read(globalThemeModeProvider), CodexThemeMode.papyrus);

      await tester.tap(find.text('Light'));
      await tester.pumpAndSettle();
      expect(container.read(globalThemeModeProvider), CodexThemeMode.light);
    },
  );

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
    await tester.pump();

    final submitBtn = find.text('Sign Up & Behold ᛏᚱᚢᛏᚺ');

    // Empty name
    await tester.ensureVisible(submitBtn);
    await tester.tap(submitBtn);
    await tester.pump();
    expect(find.text('Enter your Seeker title.'), findsOneWidget);

    // Invalid email
    await tester.enterText(find.byType(TextField).at(0), 'Seer_One');
    await tester.enterText(find.byType(TextField).at(1), 'bad-email');
    await tester.ensureVisible(submitBtn);
    await tester.tap(submitBtn);
    await tester.pump();
    expect(find.text('Enter a valid email address.'), findsOneWidget);

    // Short password
    await tester.enterText(find.byType(TextField).at(1), 'seer@codex.org');
    await tester.enterText(find.byType(TextField).at(2), '123');
    await tester.ensureVisible(submitBtn);
    await tester.tap(submitBtn);
    await tester.pump();
    expect(
      find.text('Password must be at least 6 characters.'),
      findsOneWidget,
    );

    // Mismatched confirm password
    await tester.enterText(find.byType(TextField).at(2), 'secret12');
    await tester.enterText(find.byType(TextField).at(3), 'different');
    await tester.ensureVisible(submitBtn);
    await tester.tap(submitBtn);
    await tester.pump();
    expect(find.text('Passwords do not match.'), findsOneWidget);

    // Firebase not ready
    await tester.enterText(find.byType(TextField).at(3), 'secret12');
    await tester.ensureVisible(submitBtn);
    await tester.tap(submitBtn);
    await tester.pump();
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
    await tester.pump();

    await tester.enterText(find.byType(TextField).at(0), '  Seer_Manayon  ');
    await tester.enterText(find.byType(TextField).at(1), '  seer@codex.org  ');
    await tester.enterText(find.byType(TextField).at(2), 'secret12');
    await tester.enterText(find.byType(TextField).at(3), 'secret12');

    // Toggle password visibility
    final showPassBtn = find.byTooltip('Show password').first;
    await tester.ensureVisible(showPassBtn);
    await tester.pump();
    await tester.tap(showPassBtn);
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField).at(2)).obscureText,
      isFalse,
    );

    // Duplicate email error formatting
    shouldThrowDuplicate = true;
    final submitBtn = find.text('Sign Up & Behold ᛏᚱᚢᛏᚺ');
    await tester.ensureVisible(submitBtn);
    await tester.tap(submitBtn);
    await tester.pump();
    expect(
      find.text(
        'An account with this email already exists. Try signing in instead.',
      ),
      findsOneWidget,
    );
    expect(succeeded, isFalse);

    // Successful registration transitions to Sign In via crimson Mark ritual
    shouldThrowDuplicate = false;
    await tester.ensureVisible(submitBtn);
    await tester.tap(submitBtn);
    await tester.pump();
    expect(capturedName, 'Seer_Manayon');
    expect(capturedEmail, 'seer@codex.org');
    expect(find.text('The Mark of Codex granted'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('SANCTUM AUTHENTICATION'), findsOneWidget);
    expect(succeeded, isFalse);
  });
}
