import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  reader('READER', 'The Seeker'),
  author('AUTHOR', 'The Clairvoyance'),
  moderator('MODERATOR', 'The Inquisitor'),
  admin('ADMIN', 'The Overseer');

  const UserRole(this.firestoreValue, this.defaultInUniverseTitle);
  final String firestoreValue;
  final String defaultInUniverseTitle;

  bool get isCouncil => this == UserRole.moderator || this == UserRole.admin;
  bool get isAdmin => this == UserRole.admin;

  static UserRole fromString(String? value) => UserRole.values.firstWhere(
    (r) => r.firestoreValue.toUpperCase() == value?.toUpperCase(),
    orElse: () => UserRole.reader,
  );
}

class AppUser {
  const AppUser({
    required this.uid,
    required this.displayName,
    required this.email,
    this.role = UserRole.reader,
    this.inUniverseRole = 'The Seeker',
    this.vanguardBranch,
    this.truthPoints = 0,
    this.bookmarkedArtifactIds = const [],
    required this.createdAt,
  });

  final String uid;
  final String displayName;
  final String email;
  final UserRole role;
  final String inUniverseRole;
  final String? vanguardBranch;
  final int truthPoints;
  final List<String> bookmarkedArtifactIds;
  final DateTime createdAt;

  int get hierarchyLevel => switch (role) {
    UserRole.admin => 5,
    UserRole.moderator => 4,
    UserRole.author => 3,
    UserRole.reader => truthPoints >= 100 ? 2 : 1,
  };

  Map<String, dynamic> toMap() => {
    'displayName': displayName,
    'email': email,
    'role': role.firestoreValue,
    'inUniverseRole': inUniverseRole,
    'vanguardBranch': vanguardBranch,
    'truthPoints': truthPoints,
    'bookmarkedArtifactIds': bookmarkedArtifactIds,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    final role = UserRole.fromString(map['role'] as String?);
    final rawCreated = map['createdAt'];
    final created = switch (rawCreated) {
      Timestamp t => t.toDate(),
      String s => DateTime.tryParse(s) ?? DateTime.now(),
      _ => DateTime.now(),
    };
    return AppUser(
      uid: uid,
      displayName: (map['displayName'] as String?) ?? 'Seer',
      email: (map['email'] as String?) ?? '',
      role: role,
      inUniverseRole:
          (map['inUniverseRole'] as String?) ?? role.defaultInUniverseTitle,
      vanguardBranch: map['vanguardBranch'] as String?,
      truthPoints: (map['truthPoints'] as num?)?.toInt() ?? 0,
      bookmarkedArtifactIds:
          (map['bookmarkedArtifactIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      createdAt: created,
    );
  }
}
