import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/artifact.dart';
import '../models/lore_config.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _artifacts =>
      _db.collection('artifacts');

  Stream<LoreConfig> watchLoreConfig() => _db
      .collection('lore_config')
      .doc('catalogue_settings')
      .snapshots()
      .map((snap) => LoreConfig.fromMap(snap.data()));

  Stream<List<Artifact>> watchApprovedArtifacts() => _artifacts
      .where('status', isEqualTo: ArtifactStatus.approved.firestoreValue)
      .snapshots()
      .map((snap) {
        final list =
            snap.docs.map((d) => Artifact.fromMap(d.id, d.data())).toList()
              ..sort(
                (a, b) =>
                    (a.artifactNumber ?? 9999).compareTo(b.artifactNumber ?? 9999),
              );
        return list;
      });

  Stream<List<Artifact>> watchAuthorSubmissions(String authorId) => _artifacts
      .where('authorId', isEqualTo: authorId)
      .snapshots()
      .map((snap) {
        final list =
            snap.docs.map((d) => Artifact.fromMap(d.id, d.data())).toList()
              ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        return list;
      });

  Stream<List<Artifact>> watchPendingArtifacts() => _artifacts
      .where('status', isEqualTo: ArtifactStatus.pending.firestoreValue)
      .snapshots()
      .map((snap) {
        final list =
            snap.docs.map((d) => Artifact.fromMap(d.id, d.data())).toList()
              ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        return list;
      });

  Stream<Artifact?> watchArtifactById(String id) => _artifacts
      .doc(id)
      .snapshots()
      .map((doc) => doc.exists && doc.data() != null ? Artifact.fromMap(doc.id, doc.data()!) : null);

  Stream<int> watchUserVote(String artifactId, String userId) => _artifacts
      .doc(artifactId)
      .collection('votes')
      .doc(userId)
      .snapshots()
      .map((snap) => (snap.data()?['value'] as num?)?.toInt() ?? 0);

  Future<String> saveSubmission(Artifact artifact) async {
    final docRef =
        artifact.id.isEmpty ? _artifacts.doc() : _artifacts.doc(artifact.id);
    final updated = artifact.copyWith(id: docRef.id, updatedAt: DateTime.now());
    await docRef.set(updated.toMap(), SetOptions(merge: true));
    return docRef.id;
  }

  Future<void> castVote({
    required String artifactId,
    required String userId,
    required int voteValue, // 1 for upvote, -1 for downvote
  }) async {
    final artRef = _artifacts.doc(artifactId);
    final voteRef = artRef.collection('votes').doc(userId);

    await _db.runTransaction((tx) async {
      final artSnap = await tx.get(artRef);
      if (!artSnap.exists || artSnap.data() == null) return;
      final voteSnap = await tx.get(voteRef);

      final current = Artifact.fromMap(artSnap.id, artSnap.data()!);
      final prevVote = (voteSnap.data()?['value'] as num?)?.toInt() ?? 0;
      final nextVote = prevVote == voteValue ? 0 : voteValue;

      var upvotes = current.upvotes;
      var downvotes = current.downvotes;

      if (prevVote == 1) upvotes = (upvotes - 1).clamp(0, 1 << 30);
      if (prevVote == -1) downvotes = (downvotes - 1).clamp(0, 1 << 30);
      if (nextVote == 1) upvotes += 1;
      if (nextVote == -1) downvotes += 1;

      final netRating = upvotes - downvotes;
      final visibility =
          netRating <= current.downvoteThreshold
              ? ArtifactVisibility.flagged
              : ArtifactVisibility.public;

      tx.set(voteRef, {'value': nextVote, 'updatedAt': FieldValue.serverTimestamp()});
      tx.update(artRef, {
        'upvotes': upvotes,
        'downvotes': downvotes,
        'rating': netRating,
        'visibility': visibility.firestoreValue,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> approveArtifact({
    required Artifact artifact,
    required int artifactNumber,
    required bool isOfficialCanon,
    String? committedRawUrl,
  }) async {
    final urls =
        committedRawUrl != null && committedRawUrl.isNotEmpty
            ? [committedRawUrl]
            : artifact.imageUrls;
    final approved = artifact.copyWith(
      artifactNumber: artifactNumber,
      isOfficialCanon: isOfficialCanon,
      imageUrls: urls,
      clearStagedImage: true,
      status: ArtifactStatus.approved,
      visibility: ArtifactVisibility.public,
      updatedAt: DateTime.now(),
    );
    await _artifacts.doc(artifact.id).set(approved.toMap(), SetOptions(merge: true));
  }

  Future<void> rejectArtifact(String artifactId) async {
    await _artifacts.doc(artifactId).update({
      'status': ArtifactStatus.rejected.firestoreValue,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> toggleUserBookmark({
    required String userId,
    required String artifactId,
    required bool bookmark,
  }) async {
    await _db.collection('users').doc(userId).update({
      'bookmarkedArtifactIds':
          bookmark
              ? FieldValue.arrayUnion([artifactId])
              : FieldValue.arrayRemove([artifactId]),
    });
  }

  Future<void> incrementTruthPoints(String userId, {int points = 5}) async {
    await _db.collection('users').doc(userId).update({
      'truthPoints': FieldValue.increment(points),
    });
  }
}
