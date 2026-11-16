import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/codex_tokens.dart';
import '../models/app_user.dart';
import '../models/artifact.dart';
import '../models/lore_config.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/github_image_service.dart';
import '../services/vault_local_service.dart';

final firebaseReadyProvider = StateProvider<bool>((ref) => false);

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final firestoreServiceProvider = Provider<FirestoreService>(
  (ref) => FirestoreService(),
);
final githubImageServiceProvider = Provider<GithubImageService>(
  (ref) => GithubImageService(),
);
final vaultLocalServiceProvider = Provider<VaultLocalService>(
  (ref) => VaultLocalService(),
);

final currentUserProvider = StreamProvider<AppUser?>((ref) {
  final ready = ref.watch(firebaseReadyProvider);
  if (!ready) return Stream.value(null);
  return ref.watch(authServiceProvider).watchCurrentUser();
});

final loreConfigProvider = StreamProvider<LoreConfig>((ref) {
  final ready = ref.watch(firebaseReadyProvider);
  if (!ready) return Stream.value(const LoreConfig());
  return ref.watch(firestoreServiceProvider).watchLoreConfig();
});

final approvedArtifactsProvider = StreamProvider<List<Artifact>>((ref) {
  final ready = ref.watch(firebaseReadyProvider);
  if (!ready) return Stream.value(const []);
  return ref.watch(firestoreServiceProvider).watchApprovedArtifacts();
});

final pendingArtifactsProvider = StreamProvider<List<Artifact>>((ref) {
  final ready = ref.watch(firebaseReadyProvider);
  if (!ready) return Stream.value(const []);
  return ref.watch(firestoreServiceProvider).watchPendingArtifacts();
});

final authorSubmissionsProvider = StreamProvider<List<Artifact>>((ref) {
  final ready = ref.watch(firebaseReadyProvider);
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (!ready || user == null) return Stream.value(const []);
  return ref.watch(firestoreServiceProvider).watchAuthorSubmissions(user.uid);
});

final globalThemeModeProvider = StateProvider<CodexThemeMode>(
  (ref) => CodexThemeMode.dark,
);
final readerThemeOverrideProvider = StateProvider<CodexThemeMode?>(
  (ref) => null,
);
final readerFontSizeProvider = StateProvider<double>((ref) => 17.0);

final selectedAnomalyClassProvider = StateProvider<AnomalyClass?>(
  (ref) => null,
);
final selectedEraProvider = StateProvider<String?>((ref) => null);

final filteredArtifactsProvider = Provider<AsyncValue<List<Artifact>>>((ref) {
  final asyncList = ref.watch(approvedArtifactsProvider);
  final selectedClass = ref.watch(selectedAnomalyClassProvider);
  final selectedEra = ref.watch(selectedEraProvider);

  return asyncList.whenData((items) {
    return items.where((a) {
      if (a.visibility == ArtifactVisibility.hidden) return false;
      final matchClass = selectedClass == null || a.anomalyClass == selectedClass;
      final matchEra =
          selectedEra == null ||
          a.historicalOrigin.toLowerCase() == selectedEra.toLowerCase();
      return matchClass && matchEra;
    }).toList();
  });
});

class VaultNotifier extends StateNotifier<Map<String, VaultEntry>> {
  VaultNotifier(this._service) : super(const {}) {
    refresh();
  }

  final VaultLocalService _service;

  Future<void> refresh() async {
    state = await _service.loadEntries();
  }

  Future<bool> toggleBookmark(Artifact artifact) async {
    final current = state[artifact.id]?.isBookmarked ?? false;
    final nextState = !current;
    state = await _service.setBookmark(artifact, nextState);
    return nextState;
  }

  Future<bool> toggleOffline(Artifact artifact) async {
    final current = state[artifact.id]?.isOfflineSaved ?? false;
    final nextState = !current;
    state = await _service.setOfflineSaved(artifact, nextState);
    return nextState;
  }

  Future<void> setBookmarkExplicit(Artifact artifact, bool value) async {
    state = await _service.setBookmark(artifact, value);
  }

  Future<void> setOfflineExplicit(Artifact artifact, bool value) async {
    state = await _service.setOfflineSaved(artifact, value);
  }
}

final vaultProvider =
    StateNotifierProvider<VaultNotifier, Map<String, VaultEntry>>(
      (ref) => VaultNotifier(ref.watch(vaultLocalServiceProvider)),
    );
