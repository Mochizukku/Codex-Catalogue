import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/theme/codex_tokens.dart';

enum ArtifactStatus {
  draft('DRAFT', 'Draft'),
  pending('PENDING', 'Pending review'),
  approved('APPROVED', 'Published'),
  rejected('REJECTED', 'Rejected');

  const ArtifactStatus(this.firestoreValue, this.displayLabel);
  final String firestoreValue;
  final String displayLabel;

  static ArtifactStatus fromString(String? val) =>
      ArtifactStatus.values.firstWhere(
        (e) => e.firestoreValue.toUpperCase() == val?.toUpperCase(),
        orElse: () => ArtifactStatus.pending,
      );
}

enum ArtifactVisibility {
  public('PUBLIC'),
  flagged('FLAGGED'),
  hidden('HIDDEN');

  const ArtifactVisibility(this.firestoreValue);
  final String firestoreValue;

  static ArtifactVisibility fromString(String? val) =>
      ArtifactVisibility.values.firstWhere(
        (e) => e.firestoreValue.toUpperCase() == val?.toUpperCase(),
        orElse: () => ArtifactVisibility.public,
      );
}

class Artifact {
  const Artifact({
    required this.id,
    this.artifactNumber,
    required this.title,
    required this.anomalyClass,
    this.anomalyScope = 'Mortal / Localized',
    required this.historicalOrigin,
    required this.discovererPerspective,
    required this.adventurerRecoveryNote,
    required this.clairvoyanceName,
    required this.chapterContent,
    this.imageUrls = const [],
    this.stagedImageBase64,
    required this.authorId,
    this.status = ArtifactStatus.pending,
    this.visibility = ArtifactVisibility.public,
    this.isOfficialCanon = false,
    this.upvotes = 0,
    this.downvotes = 0,
    this.downvoteThreshold = -10,
    required this.updatedAt,
  });

  final String id;
  final int? artifactNumber;
  final String title;
  final AnomalyClass anomalyClass;
  final String anomalyScope;
  final String historicalOrigin;
  final String discovererPerspective;
  final String adventurerRecoveryNote;
  final String clairvoyanceName;
  final String chapterContent;
  final List<String> imageUrls;
  final String? stagedImageBase64;
  final String authorId;
  final ArtifactStatus status;
  final ArtifactVisibility visibility;
  final bool isOfficialCanon;
  final int upvotes;
  final int downvotes;
  final int downvoteThreshold;
  final DateTime updatedAt;

  int get rating => upvotes - downvotes;

  bool get isFlagged =>
      visibility == ArtifactVisibility.flagged || rating <= downvoteThreshold;

  static String formatFourDigitNumber(int number) =>
      number.clamp(0, 9999).toString().padLeft(4, '0');

  static bool isValidFourDigitNumber(String input) =>
      RegExp(r'^\d{4}$').hasMatch(input.trim()) &&
      int.parse(input.trim()) >= 1;

  String get numberCode => artifactNumber == null
      ? '----'
      : formatFourDigitNumber(artifactNumber!);

  String get bracketedCode => 'Artifact [$numberCode]';

  String get formattedLabel => '$bracketedCode - $title';

  String get signedRating => rating >= 0 ? '+$rating' : '−${rating.abs()}';

  String? get primaryImageUrl =>
      imageUrls.isNotEmpty && imageUrls.first.trim().isNotEmpty
          ? imageUrls.first.trim()
          : null;

  Artifact copyWith({
    String? id,
    int? artifactNumber,
    String? title,
    AnomalyClass? anomalyClass,
    String? anomalyScope,
    String? historicalOrigin,
    String? discovererPerspective,
    String? adventurerRecoveryNote,
    String? clairvoyanceName,
    String? chapterContent,
    List<String>? imageUrls,
    String? stagedImageBase64,
    bool clearStagedImage = false,
    String? authorId,
    ArtifactStatus? status,
    ArtifactVisibility? visibility,
    bool? isOfficialCanon,
    int? upvotes,
    int? downvotes,
    int? downvoteThreshold,
    DateTime? updatedAt,
  }) => Artifact(
    id: id ?? this.id,
    artifactNumber: artifactNumber ?? this.artifactNumber,
    title: title ?? this.title,
    anomalyClass: anomalyClass ?? this.anomalyClass,
    anomalyScope: anomalyScope ?? this.anomalyScope,
    historicalOrigin: historicalOrigin ?? this.historicalOrigin,
    discovererPerspective: discovererPerspective ?? this.discovererPerspective,
    adventurerRecoveryNote:
        adventurerRecoveryNote ?? this.adventurerRecoveryNote,
    clairvoyanceName: clairvoyanceName ?? this.clairvoyanceName,
    chapterContent: chapterContent ?? this.chapterContent,
    imageUrls: imageUrls ?? this.imageUrls,
    stagedImageBase64:
        clearStagedImage ? null : (stagedImageBase64 ?? this.stagedImageBase64),
    authorId: authorId ?? this.authorId,
    status: status ?? this.status,
    visibility: visibility ?? this.visibility,
    isOfficialCanon: isOfficialCanon ?? this.isOfficialCanon,
    upvotes: upvotes ?? this.upvotes,
    downvotes: downvotes ?? this.downvotes,
    downvoteThreshold: downvoteThreshold ?? this.downvoteThreshold,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toMap() => {
    'artifactNumber': artifactNumber,
    'title': title,
    'formattedLabel': formattedLabel,
    'anomalyClass': anomalyClass.label,
    'anomalyScope': anomalyScope,
    'historicalOrigin': historicalOrigin,
    'discovererPerspective': discovererPerspective,
    'adventurerRecoveryNote': adventurerRecoveryNote,
    'clairvoyanceName': clairvoyanceName,
    'chapterContent': chapterContent,
    'imageUrls': imageUrls,
    'stagedImageBase64': stagedImageBase64,
    'authorId': authorId,
    'status': status.firestoreValue,
    'visibility':
        (upvotes - downvotes) <= downvoteThreshold
            ? ArtifactVisibility.flagged.firestoreValue
            : visibility.firestoreValue,
    'isOfficialCanon': isOfficialCanon,
    'upvotes': upvotes,
    'downvotes': downvotes,
    'rating': rating,
    'downvoteThreshold': downvoteThreshold,
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  Map<String, dynamic> toJson() => {
    ...toMap(),
    'id': id,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Artifact.fromMap(String id, Map<String, dynamic> map) {
    final rawUpdated = map['updatedAt'];
    final parsedDate = switch (rawUpdated) {
      Timestamp t => t.toDate(),
      String s => DateTime.tryParse(s) ?? DateTime.now(),
      _ => DateTime.now(),
    };
    return Artifact(
      id: id,
      artifactNumber: (map['artifactNumber'] as num?)?.toInt(),
      title: (map['title'] as String?) ?? 'Untitled Artifact',
      anomalyClass: AnomalyClass.fromString(map['anomalyClass'] as String?),
      anomalyScope: (map['anomalyScope'] as String?) ?? 'Mortal / Localized',
      historicalOrigin: (map['historicalOrigin'] as String?) ?? 'Unknown Era',
      discovererPerspective:
          (map['discovererPerspective'] as String?) ?? 'Unknown Discoverer',
      adventurerRecoveryNote:
          (map['adventurerRecoveryNote'] as String?) ?? 'REDACTED',
      clairvoyanceName:
          (map['clairvoyanceName'] as String?) ?? 'Unknown Scribe',
      chapterContent: (map['chapterContent'] as String?) ?? '',
      imageUrls:
          (map['imageUrls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      stagedImageBase64: map['stagedImageBase64'] as String?,
      authorId: (map['authorId'] as String?) ?? '',
      status: ArtifactStatus.fromString(map['status'] as String?),
      visibility: ArtifactVisibility.fromString(map['visibility'] as String?),
      isOfficialCanon: (map['isOfficialCanon'] as bool?) ?? false,
      upvotes: (map['upvotes'] as num?)?.toInt() ?? 0,
      downvotes: (map['downvotes'] as num?)?.toInt() ?? 0,
      downvoteThreshold: (map['downvoteThreshold'] as num?)?.toInt() ?? -10,
      updatedAt: parsedDate,
    );
  }
}
